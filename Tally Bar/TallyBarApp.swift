import SwiftUI

@main
struct TallyBarApp: App {
    @StateObject private var store = TrackerStore()

    var body: some Scene {
        MenuBarExtra {
            ContentView(store: store)
        } label: {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                HStack(spacing: 4) {
                    Image(systemName: store.data.active?.runningSince == nil ? "timer" : "record.circle")
                    if let active = store.data.active {
                        Text(clockText(active.duration(at: context.date))).monospacedDigit()
                    }
                }
                .accessibilityLabel(store.data.active == nil ? "Tally Bar" : "Tally Bar, session in progress")
            }
        }
        .menuBarExtraStyle(.window)
    }
}
