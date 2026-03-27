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
    @AppStorage("felt_onboarded") private var hasOnboarded = false

    var body: some View {
        NavigationStack {
            if !hasOnboarded {
                WelcomeView {
                    SampleEntries.seed(into: modelContext)
                    withAnimation {
                        hasOnboarded = true
                    }
                }
            } else {
                TimelineView()
            }
        }
    }
}
