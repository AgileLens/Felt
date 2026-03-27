import Foundation
import SwiftData

@Model
final class DayEntry {
    var id: UUID
    var date: Date
    var moodRaw: String
    var note: String
    var gratitude: String

    var mood: Mood {
        get { Mood(rawValue: moodRaw) ?? .okay }
        set { moodRaw = newValue.rawValue }
    }

    private static let dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var dayKey: String {
        DayEntry.dayKeyFormatter.string(from: date)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    init(date: Date = .now, mood: Mood, note: String = "", gratitude: String = "") {
        self.id = UUID()
        self.date = date
        self.moodRaw = mood.rawValue
        self.note = note
        self.gratitude = gratitude
    }
}
