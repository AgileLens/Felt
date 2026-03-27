import SwiftUI
import SwiftData
import Charts
#if os(iOS)
import UIKit
#endif

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
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    } label: {
                        Image(systemName: "calendar")
                    }

                    if todayEntry == nil {
                        Button {
                            showCheckIn = true
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            #endif
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
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    #endif
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Weekly mood chart")
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
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
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
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(entry.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())), felt \(entry.mood.label.lowercased())\(!entry.note.isEmpty ? ", \(entry.note)" : "")")
            }
        }
    }
}

// MARK: - Entry Detail

struct EntryDetailView: View {
    @Bindable var entry: DayEntry
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var isEditing = false
    @State private var editMood: Mood?
    @State private var editNote = ""
    @State private var editGratitude = ""
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Mood hero
                    VStack(spacing: 12) {
                        if isEditing {
                            moodEditGrid
                        } else {
                            Text(entry.mood.emoji)
                                .font(.system(size: 64))
                        }

                        Text((isEditing ? editMood ?? entry.mood : entry.mood).label)
                            .font(.system(.title, design: .serif, weight: .bold))
                            .foregroundStyle((isEditing ? editMood ?? entry.mood : entry.mood).color)

                        Text(entry.date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)

                    if isEditing {
                        // Editable fields
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Thoughts")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            TextField("What was on your mind?", text: $editNote, axis: .vertical)
                                .lineLimit(3...6)
                                .padding(12)
                                .background(FeltTheme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Grateful for")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            TextField("Optional...", text: $editGratitude, axis: .vertical)
                                .lineLimit(2...4)
                                .padding(12)
                                .background(FeltTheme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)

                        Button {
                            saveEdits()
                        } label: {
                            Text("Save Changes")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background((editMood ?? entry.mood).color)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    } else {
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
                    }

                    // Delete button
                    if !isEditing {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete Entry", systemImage: "trash")
                                .font(.subheadline)
                                .foregroundStyle(.red)
                        }
                        .padding(.top, 20)
                    }

                    Spacer()
                }
            }
            .background(FeltTheme.background)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if isEditing {
                        Button("Cancel") {
                            isEditing = false
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if !isEditing {
                        Menu {
                            Button {
                                editMood = entry.mood
                                editNote = entry.note
                                editGratitude = entry.gratitude
                                isEditing = true
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button("Done") { dismiss() }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .confirmationDialog("Delete this entry?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    #if os(iOS)
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    #endif
                    modelContext.delete(entry)
                    try? modelContext.save()
                    dismiss()
                }
            }
        }
    }

    // MARK: - Mood Edit Grid

    private var moodEditGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 8) {
            ForEach(Mood.allCases) { mood in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        editMood = mood
                    }
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                } label: {
                    Text(mood.emoji)
                        .font(.system(size: 32))
                        .scaleEffect(editMood == mood ? 1.2 : 1.0)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(editMood == mood ? mood.color.opacity(0.15) : .clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(editMood == mood ? mood.color : .clear, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Save Edits

    private func saveEdits() {
        if let mood = editMood {
            entry.mood = mood
        }
        entry.note = editNote
        entry.gratitude = editGratitude
        try? modelContext.save()
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
        withAnimation { isEditing = false }
    }
}
