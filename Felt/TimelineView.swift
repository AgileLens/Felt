import SwiftUI
import SwiftData
import Charts

struct TimelineView: View {
    @Query(sort: \DayEntry.date, order: .reverse) private var entries: [DayEntry]
    @State private var showCheckIn = false
    @State private var showCalendar = false
    @State private var selectedEntry: DayEntry?

    private var todayEntry: DayEntry? {
        entries.first(where: { $0.isToday })
    }

    private var streak: Int {
        var count = 0
        let cal = Calendar.current
        // Start from today; if no entry today, try yesterday (streak still counts)
        var checkDate = cal.startOfDay(for: .now)

        // Deduplicate by day
        var seen = Set<String>()
        let unique = entries.filter { seen.insert($0.dayKey).inserted }

        // Allow starting from yesterday if no entry today
        if !unique.contains(where: { cal.isDate($0.date, inSameDayAs: checkDate) }) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: checkDate) else { return 0 }
            checkDate = yesterday
        }

        for entry in unique {
            if cal.isDate(entry.date, inSameDayAs: checkDate) {
                count += 1
                guard let prev = cal.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            } else if entry.date < checkDate {
                break
            }
        }
        return count
    }

    private var last7Days: [DayEntry] {
        let cal = Calendar.current
        guard let weekAgo = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: .now)) else { return [] }
        return entries.filter { $0.date >= weekAgo }.reversed()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                todayCard
                moodChart
                recentEntries
                Spacer(minLength: 20)
            }
        }
        .background(FeltTheme.background)
        .navigationTitle("Felt")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                HStack(spacing: 12) {
                    Button {
                        showCalendar = true
                    } label: {
                        Image(systemName: "calendar")
                    }

                    if todayEntry == nil {
                        Button {
                            showCheckIn = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(FeltTheme.accent)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showCheckIn) {
            CheckInView()
        }
        .sheet(isPresented: $showCalendar) {
            CalendarView()
        }
        .sheet(item: $selectedEntry) { entry in
            EntryDetailView(entry: entry)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.subheadline)
                    .foregroundStyle(FeltTheme.subtleText)

                if streak > 1 {
                    Label("\(streak) day streak", systemImage: "flame.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                }
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Today Card

    private var todayCard: some View {
        Group {
            if let today = todayEntry {
                VStack(spacing: 12) {
                    HStack {
                        Text(today.mood.emoji)
                            .font(.system(size: 40))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Today you felt \(today.mood.label.lowercased())")
                                .font(.headline)
                            if !today.note.isEmpty {
                                Text(today.note)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        Spacer()
                    }
                }
                .padding(16)
                .background(today.mood.color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: FeltTheme.cardRadius, style: .continuous))
                .padding(.horizontal)
            } else {
                Button {
                    showCheckIn = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("How are you feeling today?")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding(16)
                    .background(FeltTheme.accent.opacity(0.1))
                    .foregroundStyle(FeltTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: FeltTheme.cardRadius, style: .continuous))
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Mood Chart

    private var moodChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)
                .padding(.horizontal)

            if last7Days.count >= 2 {
                Chart(last7Days) { entry in
                    LineMark(
                        x: .value("Day", entry.date, unit: .day),
                        y: .value("Mood", entry.mood.numericValue)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(FeltTheme.accent.gradient)

                    PointMark(
                        x: .value("Day", entry.date, unit: .day),
                        y: .value("Mood", entry.mood.numericValue)
                    )
                    .foregroundStyle(entry.mood.color)
                    .symbolSize(40)

                    AreaMark(
                        x: .value("Day", entry.date, unit: .day),
                        y: .value("Mood", entry.mood.numericValue)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(FeltTheme.accent.opacity(0.08).gradient)
                }
                .chartYScale(domain: 0...9)
                .chartYAxis {
                    AxisMarks(values: [2, 4, 6, 8]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text(moodLabel(for: v))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                }
                .frame(height: 160)
                .padding(.horizontal)
            } else {
                Text("Check in for a few days to see your mood trend.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 20)
            }
        }
        .padding(.vertical, 12)
        .feltCard()
        .padding(.horizontal)
    }

    private func moodLabel(for value: Int) -> String {
        switch value {
        case 8: return "😊"
        case 6: return "🙂"
        case 4: return "😕"
        case 2: return "😢"
        default: return ""
        }
    }

    // MARK: - Recent Entries

    private var recentEntries: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent")
                .font(.headline)
                .padding(.horizontal)

            ForEach(entries.prefix(10)) { entry in
                Button {
                    selectedEntry = entry
                } label: {
                    HStack(spacing: 12) {
                        Text(entry.mood.emoji)
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                                .font(.subheadline.weight(.medium))
                            if !entry.note.isEmpty {
                                Text(entry.note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        Circle()
                            .fill(entry.mood.color)
                            .frame(width: 10, height: 10)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Entry Detail

struct EntryDetailView: View {
    let entry: DayEntry
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Mood hero
                    VStack(spacing: 12) {
                        Text(entry.mood.emoji)
                            .font(.system(size: 64))

                        Text(entry.mood.label)
                            .font(.system(.title, design: .serif, weight: .bold))
                            .foregroundStyle(entry.mood.color)

                        Text(entry.date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)

                    if !entry.note.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Thoughts")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(entry.note)
                                .font(.body)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .feltCard()
                        .padding(.horizontal)
                    }

                    if !entry.gratitude.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Grateful for")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(entry.gratitude)
                                .font(.body)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .feltCard()
                        .padding(.horizontal)
                    }

                    Spacer()
                }
            }
            .background(FeltTheme.background)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
