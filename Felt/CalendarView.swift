import SwiftUI
import SwiftData
#if os(iOS)
import UIKit
#endif

struct CalendarView: View {
    @Query(sort: \DayEntry.date, order: .reverse) private var entries: [DayEntry]
    @Environment(\.dismiss) private var dismiss
    @State private var displayedMonth = Date.now
    @State private var selectedEntry: DayEntry?

    private let calendar = Calendar.current
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols

    private static let dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private var monthEntries: [String: DayEntry] {
        var map: [String: DayEntry] = [:]
        for entry in entries {
            map[entry.dayKey] = entry
        }
        return map
    }

    private var monthLabel: String {
        displayedMonth.formatted(.dateTime.month(.wide).year())
    }

    private var daysInMonth: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let padding = firstWeekday - calendar.firstWeekday
        let paddingCount = padding >= 0 ? padding : padding + 7

        var days: [Date?] = Array(repeating: nil, count: paddingCount)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }

        return days
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Month navigation
                HStack {
                    Button {
                        withAnimation { shiftMonth(by: -1) }
                        #if os(iOS)
                        UISelectionFeedbackGenerator().selectionChanged()
                        #endif
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                    }

                    Spacer()

                    Text(monthLabel)
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .contentTransition(.numericText())

                    Spacer()

                    Button {
                        withAnimation { shiftMonth(by: 1) }
                        #if os(iOS)
                        UISelectionFeedbackGenerator().selectionChanged()
                        #endif
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.horizontal)

                // Weekday headers
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                    ForEach(weekdaySymbols, id: \.self) { symbol in
                        Text(symbol)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)

                // Calendar grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                        if let date {
                            dayCell(for: date)
                        } else {
                            Color.clear.frame(height: 44)
                        }
                    }
                }
                .padding(.horizontal)

                // Stats
                statsSection

                Spacer()
            }
            .padding(.top)
            .background(FeltTheme.background)
            .navigationTitle("Calendar")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedEntry) { entry in
                EntryDetailView(entry: entry)
            }
        }
    }

    // MARK: - Day Cell

    private func dayCell(for date: Date) -> some View {
        let dayKey = Self.dayKeyFormatter.string(from: date)

        let entry = monthEntries[dayKey]
        let isToday = calendar.isDateInToday(date)
        let isFuture = calendar.compare(date, to: .now, toGranularity: .day) == .orderedDescending

        return Button {
            if let entry {
                selectedEntry = entry
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                #endif
            }
        } label: {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.caption.weight(isToday ? .bold : .regular))
                    .foregroundStyle(isFuture ? .tertiary : .primary)

                if let entry {
                    Circle()
                        .fill(entry.mood.color)
                        .frame(width: 8, height: 8)
                } else {
                    Circle()
                        .fill(.clear)
                        .frame(width: 8, height: 8)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isToday ? FeltTheme.accent.opacity(0.1) : .clear)
            )
        }
        .buttonStyle(.plain)
        .disabled(entry == nil)
    }

    // MARK: - Stats

    private var statsSection: some View {
        let monthEntriesList = entries.filter {
            calendar.isDate($0.date, equalTo: displayedMonth, toGranularity: .month)
        }
        let avgMood = monthEntriesList.isEmpty ? 0 :
            monthEntriesList.reduce(0) { $0 + $1.mood.numericValue } / Double(monthEntriesList.count)

        return HStack(spacing: 20) {
            statItem(value: "\(monthEntriesList.count)", label: "entries")
            statItem(value: String(format: "%.1f", avgMood), label: "avg mood")

            if let mostCommon = mostCommonMood(in: monthEntriesList) {
                statItem(value: mostCommon.emoji, label: "most felt")
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .feltCard()
        .padding(.horizontal)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func mostCommonMood(in entries: [DayEntry]) -> Mood? {
        var counts: [Mood: Int] = [:]
        for entry in entries { counts[entry.mood, default: 0] += 1 }
        return counts.max(by: { $0.value < $1.value })?.key
    }

    private func shiftMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newDate
        }
    }
}
