import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var store: TrackerStore
    @State private var name = ""
    @State private var showingHistory = false
    @State private var pendingDelete: TrackingSession?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Tally Bar").font(.headline)
                Spacer()
                Button {
                    showingHistory.toggle()
                } label: {
                    Image(systemName: showingHistory ? "timer" : "clock.arrow.circlepath")
                }
                .help(showingHistory ? "Show timer" : "Show history")
                .accessibilityLabel(showingHistory ? "Show timer" : "Show history")
                .buttonStyle(.borderless)
            }
            .padding(20)

            Divider()
            if showingHistory { history } else { timer }
            Divider()

            HStack {
                Button("Export CSV…", action: export)
                    .disabled(store.data.history.isEmpty)
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .keyboardShortcut("q")
                    .help("A running timer continues until you pause or finish it.")
            }
            .font(.callout)
            .buttonStyle(.borderless)
            .padding(16)
        }
        .frame(width: 360)
        .alert("Couldn’t save or load sessions", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("OK") { store.errorMessage = nil }
        } message: { Text(store.errorMessage ?? "") }
        .alert("Delete this session?", isPresented: Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { pendingDelete = nil }
            Button("Delete", role: .destructive) {
                if let session = pendingDelete { store.delete(session) }
                pendingDelete = nil
            }
        } message: { Text("This removes the session from your history and daily totals.") }
    }

    private var timer: some View {
        VStack(alignment: .leading, spacing: 20) {
            if store.cannotLoad {
                Label("Saved sessions are unavailable", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.secondary)
                Text("To protect your history, tracking is disabled. Check the sessions file and reopen the app.")
                    .font(.callout)
                    .textSelection(.enabled)
            }
            if let active = store.data.active {
                HStack {
                    Text(active.name).font(.title3.weight(.medium)).lineLimit(2)
                    Spacer()
                    Text(active.runningSince == nil ? "Paused" : "Running")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                TextField("What are you working on?", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(start)
                    .accessibilityLabel("Session name")
            }

            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(clockText(store.data.active?.duration(at: context.date) ?? 0))
                    .font(.system(size: 44, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .accessibilityLabel("Elapsed time")
                    .accessibilityValue(clockText(store.data.active?.duration(at: context.date) ?? 0))
            }

            HStack(spacing: 10) {
                if let active = store.data.active {
                    Button {
                        if active.runningSince == nil { store.resume() } else { store.pause() }
                    } label: {
                        Label(active.runningSince == nil ? "Resume" : "Pause", systemImage: active.runningSince == nil ? "play.fill" : "pause.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Finish") { store.finish() }
                        .buttonStyle(.bordered)
                } else {
                    Button(action: start) {
                        Label("Start session", systemImage: "play.fill").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .controlSize(.large)
            .disabled(store.cannotLoad)

            Divider()
            TimelineView(.periodic(from: .now, by: 1)) { context in
                HStack {
                    Text("Today").foregroundStyle(.secondary)
                    Spacer()
                    Text(clockText(store.total(on: context.date, now: context.date))).monospacedDigit()
                }
                .font(.callout)
            }
            Text("Running time includes sleep and time while the app is closed.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("History").font(.title3.weight(.medium))
                Spacer()
                Text("\(store.data.history.count) sessions").font(.caption).foregroundStyle(.secondary)
            }
            if store.data.history.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock").font(.title).foregroundStyle(.tertiary)
                    Text("No finished sessions").font(.headline)
                    Text("Finish a timer to add it here.").foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 220)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(store.data.history) { session in
                            HStack(alignment: .top, spacing: 10) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(session.name).font(.body.weight(.medium)).lineLimit(2)
                                    Text(session.createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 0)
                                VStack(alignment: .trailing, spacing: 6) {
                                    Text(clockText(session.duration())).monospacedDigit().font(.callout)
                                    Button { pendingDelete = session } label: { Image(systemName: "trash") }
                                        .buttonStyle(.borderless)
                                        .foregroundStyle(.secondary)
                                        .accessibilityLabel("Delete \(session.name)")
                                }
                            }
                            .padding(.vertical, 12)
                            Divider()
                        }
                    }
                }
                .frame(height: 280)
            }
        }
        .padding(20)
    }

    private func start() {
        store.start(name: name)
        if store.data.active != nil { name = "" }
    }

    private func export() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "Tally Bar Sessions.csv"
        panel.canCreateDirectories = true
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try store.csv.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            store.errorMessage = "Could not export sessions. \(error.localizedDescription)"
        }
    }
}

#Preview {
    ContentView(store: TrackerStore(fileURL: URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("tally-preview.json")))
}
