import SwiftUI
import SwiftData

@main
struct FeltApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: DayEntry.self)
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DayEntry.date, order: .reverse) private var entries: [DayEntry]
    @State private var hasSeeded = UserDefaults.standard.bool(forKey: "felt_seeded")

    private var hasCheckedInToday: Bool {
        entries.first?.isToday == true
    }

    var body: some View {
        NavigationStack {
            if !hasSeeded && entries.isEmpty {
                WelcomeView()
            } else {
                TimelineView()
            }
        }
        .task {
            if !hasSeeded {
                SampleEntries.seed(into: modelContext)
                UserDefaults.standard.set(true, forKey: "felt_seeded")
                hasSeeded = true
            }
        }
    }
}
