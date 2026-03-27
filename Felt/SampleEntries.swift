import Foundation
import SwiftData

enum SampleEntries {
    @MainActor
    static func seed(into context: ModelContext) {
        let cal = Calendar.current

        let samples: [(Int, Mood, String, String)] = [
            // (daysAgo, mood, note, gratitude)
            (1, .happy, "Great dinner with friends. Laughed a lot.", "Friends who show up"),
            (2, .okay, "Quiet day. Nothing special but nothing bad.", "A warm bed"),
            (3, .radiant, "Got the promotion! Can't believe it!", "My team believing in me"),
            (4, .meh, "Rainy day. Stayed inside mostly.", "A good book"),
            (5, .good, "Nice walk in the park. Spring is coming.", "Nature"),
            (6, .happy, "Cooked a new recipe and it turned out great.", "Having time to cook"),
            (7, .low, "Didn't sleep well. Feeling off.", ""),
            (8, .okay, "Regular day. Gym in the morning helped.", "My health"),
            (9, .good, "FaceTimed family. Miss them but glad we talked.", "Family"),
            (10, .happy, "Beautiful sunset on the drive home.", "Living somewhere beautiful"),
            (11, .meh, "Monday energy. Lots of meetings.", "At least it's a short week"),
            (12, .good, "Read for two hours. Haven't done that in a while.", "The ability to read"),
            (13, .radiant, "Perfect weekend day. Beach, sun, and nothing to do.", "Freedom"),
            (14, .happy, "Cleaned the apartment. Fresh start feeling.", "A clean space"),
        ]

        for (daysAgo, mood, note, gratitude) in samples {
            guard let date = cal.date(byAdding: .day, value: -daysAgo, to: .now) else { continue }
            let entry = DayEntry(date: date, mood: mood, note: note, gratitude: gratitude)
            context.insert(entry)
        }

        try? context.save()
    }
}
