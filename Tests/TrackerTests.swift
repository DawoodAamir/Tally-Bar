import Foundation

@main
struct TrackerTests {
    static func main() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("sessions.json")
        let t = Date(timeIntervalSince1970: 1_700_000_000)
        let store = TrackerStore(fileURL: file)
        precondition(!store.cannotLoad)
        store.start(name: "  Design  ", at: t)
        store.start(name: "Must not replace", at: t)
        precondition(store.data.active?.name == "Design")
        store.pause(at: t.addingTimeInterval(60))
        store.pause(at: t.addingTimeInterval(90))
        precondition(store.data.active?.duration(at: t.addingTimeInterval(120)) == 60)
        let restored = TrackerStore(fileURL: file)
        precondition(restored.data == store.data)
        restored.resume(at: t.addingTimeInterval(180))
        restored.resume(at: t.addingTimeInterval(190))
        let running = TrackerStore(fileURL: file)
        precondition(running.data.active?.duration(at: t.addingTimeInterval(240)) == 120)
        running.finish(at: t.addingTimeInterval(240))
        running.finish(at: t.addingTimeInterval(250))
        precondition(running.data.active == nil && running.data.history.count == 1)
        precondition(running.data.history[0].duration() == 120)
        precondition(TrackerStore(fileURL: file).data == running.data)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let midnight = calendar.startOfDay(for: t)
        let split = TrackerStore(fileURL: folder.appendingPathComponent("split.json"))
        split.start(name: "Overnight", at: midnight.addingTimeInterval(-60))
        split.pause(at: midnight.addingTimeInterval(60))
        split.resume(at: midnight.addingTimeInterval(120))
        precondition(split.total(on: midnight, now: midnight.addingTimeInterval(180), calendar: calendar) == 120)
        split.finish(at: midnight.addingTimeInterval(180))
        precondition(split.total(on: midnight.addingTimeInterval(-1), calendar: calendar) == 60)
        precondition(split.total(on: midnight, calendar: calendar) == 120)

        split.start(name: "=SUM(1,2)\n\"quoted\"", at: t)
        split.finish(at: t.addingTimeInterval(5))
        precondition(split.csv.contains("\"'=SUM(1,2)\n\"\"quoted\"\"\""))
        split.delete(split.data.history[0])
        precondition(split.data.history.count == 1)
        precondition(TrackerStore(fileURL: split.fileURL).data == split.data)
        split.start(name: "   ", at: t)
        precondition(split.data.active?.name == "Untitled session")
        split.pause(at: t.addingTimeInterval(-60))
        precondition(split.data.active?.duration() == 0)
        split.finish(at: t)
        precondition(clockText(3661) == "01:01:01")
        precondition(clockText(360_000) == "100:00:00")

        precondition(clockText(-1) == "00:00:00")
        precondition(clockText(.infinity) == "00:00:00")
        precondition(clockText(.nan) == "00:00:00")
        precondition(!clockText(Double.greatestFiniteMagnitude).isEmpty)

        // Local days can have 23 or 25 hours at daylight-saving transitions.
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        for (month, day, hours) in [(3, 10, 23), (11, 3, 25)] {
            let date = calendar.date(from: DateComponents(year: 2024, month: month, day: day))!
            let interval = calendar.dateInterval(of: .day, for: date)!
            let daylight = TrackerStore(fileURL: folder.appendingPathComponent("dst-\(month).json"))
            daylight.start(name: "Full local day", at: interval.start)
            daylight.finish(at: interval.end)
            precondition(daylight.total(on: date, calendar: calendar) == Double(hours * 3600))
        }

        let corrupt = folder.appendingPathComponent("corrupt.json")
        try Data("invalid".utf8).write(to: corrupt)
        let broken = TrackerStore(fileURL: corrupt)
        broken.start(name: "Should not overwrite", at: t)
        precondition(broken.cannotLoad && broken.errorMessage != nil && broken.data.active == nil)
        let preserved = try String(contentsOf: corrupt, encoding: .utf8)
        precondition(preserved == "invalid")
        let blockedParent = folder.appendingPathComponent("blocked")
        let blocked = TrackerStore(fileURL: blockedParent.appendingPathComponent("sessions.json"))
        try Data().write(to: blockedParent)
        blocked.start(name: "Cannot save", at: t)
        precondition(blocked.errorMessage != nil && blocked.data.active == nil)
        print("PASS: lifecycle, persistence, pauses, midnight totals, CSV escaping, deletion, clock rollback, corrupt data and failed writes")
    }
}
