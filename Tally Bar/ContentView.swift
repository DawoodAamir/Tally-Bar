import SwiftUI
import AppKit

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Tally Bar", systemImage: "timer")
                .font(.headline)
            Text("Your time tracker starts here.")
                .foregroundStyle(.secondary)
            Divider()
            Button("Quit Tally Bar") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(20)
        .frame(width: 280)
    }
}

#Preview {
    ContentView()
}
