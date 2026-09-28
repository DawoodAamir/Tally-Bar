import SwiftUI

@main
struct TallyBarApp: App {
    var body: some Scene {
        MenuBarExtra("Tally Bar", systemImage: "timer") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
