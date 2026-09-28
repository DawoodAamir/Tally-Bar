import Foundation
import Combine

struct TimeSpan: Codable, Equatable {
    var start: Date
    var end: Date
}

struct TrackingSession: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var createdAt: Date
    var spans: [TimeSpan] = []
    var runningSince: Date?

    func duration(at now: Date = Date(), within interval: DateInterval? = nil) -> TimeInterval {
        var periods = spans
        if let start = runningSince { periods.append(TimeSpan(start: start, end: now)) }
        return periods.reduce(0) { total, span in
            let start = max(span.start, interval?.start ?? span.start)
            let end = min(span.end, interval?.end ?? span.end)
            return total + max(0, end.timeIntervalSince(start))
        }
    }
}

struct TrackerData: Codable, Equatable {
    var active: TrackingSession?
    var history: [TrackingSession] = []
}

final class TrackerStore: ObservableObject {
    @Published private(set) var data = TrackerData()
    @Published var errorMessage: String?
    private(set) var cannotLoad = false
    let fileURL: URL

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Tally Bar", isDirectory: true).appendingPathComponent("sessions.json")
        do {
            let contents = try Data(contentsOf: self.fileURL)
            data = try JSONDecoder().decode(TrackerData.self, from: contents)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            // A first launch starts with an empty history.
        } catch {
            cannotLoad = true
            errorMessage = "Your saved sessions could not be opened. The original file has been preserved at \(self.fileURL.path). \(error.localizedDescription)"
        }
    }

    private func update(_ change: (inout TrackerData) -> Void) {
        guard !cannotLoad else { return }
        var next = data
        change(&next)
        do {
            let bytes = try JSONEncoder().encode(next)
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try bytes.write(to: fileURL, options: .atomic)
            data = next
        } catch {
            errorMessage = "Could not save this change. Your previous session state is unchanged. \(error.localizedDescription)"
        }
    }

    func start(name: String, at now: Date = Date()) {
        guard data.active == nil else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        update { $0.active = TrackingSession(name: trimmed.isEmpty ? "Untitled session" : trimmed, createdAt: now, runningSince: now) }
    }

    func pause(at now: Date = Date()) {
        guard let start = data.active?.runningSince else { return }
        update {
            $0.active?.spans.append(TimeSpan(start: start, end: max(start, now)))
            $0.active?.runningSince = nil
        }
    }

    func resume(at now: Date = Date()) {
        guard data.active != nil, data.active?.runningSince == nil else { return }
        update { $0.active?.runningSince = now }
    }

    func finish(at now: Date = Date()) {
        guard var session = data.active else { return }
        if let start = session.runningSince {
            session.spans.append(TimeSpan(start: start, end: max(start, now)))
            session.runningSince = nil
        }
        update {
            $0.history.insert(session, at: 0)
            $0.active = nil
        }
    }

    func delete(_ session: TrackingSession) {
        update { $0.history.removeAll { $0.id == session.id } }
    }

    func total(on date: Date, now: Date = Date(), calendar: Calendar = .current) -> TimeInterval {
        guard let interval = calendar.dateInterval(of: .day, for: date) else { return 0 }
        return (data.history + [data.active].compactMap { $0 }).reduce(0) { $0 + $1.duration(at: now, within: interval) }
    }

    var csv: String {
        let formatter = ISO8601DateFormatter()
        func quote(_ value: String) -> String {
            // Prevent spreadsheet formula execution in user-provided titles.
            let safe = ["=", "+", "-", "@", "\t", "\r", "\n"].contains(where: { value.hasPrefix($0) }) ? "'" + value : value
            return "\"" + safe.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        let rows = data.history.map { session in
            [quote(session.name), quote(formatter.string(from: session.createdAt)),
             quote(session.spans.last.map { formatter.string(from: $0.end) } ?? ""),
             String(Int(session.duration()))].joined(separator: ",")
        }
        return (["Session,Started (UTC),Ended (UTC),Seconds"] + rows).joined(separator: "\r\n") + "\r\n"
    }
}

func clockText(_ seconds: TimeInterval) -> String {
    let value = max(0, Int(seconds))
    return String(format: "%02d:%02d:%02d", value / 3600, (value / 60) % 60, value % 60)
}
