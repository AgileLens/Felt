import SwiftUI

enum Mood: String, Codable, CaseIterable, Identifiable {
    case radiant
    case happy
    case good
    case okay
    case meh
    case low
    case sad
    case awful

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .radiant: return "🌟"
        case .happy: return "😊"
        case .good: return "🙂"
        case .okay: return "😐"
        case .meh: return "😕"
        case .low: return "😔"
        case .sad: return "😢"
        case .awful: return "😞"
        }
    }

    var label: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .radiant: return Color(red: 1.0, green: 0.82, blue: 0.25)
        case .happy: return Color(red: 0.95, green: 0.65, blue: 0.20)
        case .good: return Color(red: 0.40, green: 0.78, blue: 0.50)
        case .okay: return Color(red: 0.45, green: 0.72, blue: 0.82)
        case .meh: return Color(red: 0.60, green: 0.60, blue: 0.70)
        case .low: return Color(red: 0.65, green: 0.50, blue: 0.72)
        case .sad: return Color(red: 0.55, green: 0.40, blue: 0.70)
        case .awful: return Color(red: 0.50, green: 0.32, blue: 0.55)
        }
    }

    /// Numeric value for charting (1 = worst, 8 = best)
    var numericValue: Double {
        switch self {
        case .radiant: return 8
        case .happy: return 7
        case .good: return 6
        case .okay: return 5
        case .meh: return 4
        case .low: return 3
        case .sad: return 2
        case .awful: return 1
        }
    }
}
