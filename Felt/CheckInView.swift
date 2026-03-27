import SwiftUI
import SwiftData
#if os(iOS)
import UIKit
#endif

struct CheckInView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DayEntry.date, order: .reverse) private var entries: [DayEntry]
    @State private var selectedMood: Mood?
    @State private var note = ""
    @State private var gratitude = ""
    @State private var showNote = false
    @State private var saved = false
    @State private var appear = false

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Hey there"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Greeting
                    VStack(spacing: 8) {
                        Text(greeting)
                            .font(.system(.largeTitle, design: .serif, weight: .bold))
                            .opacity(appear ? 1 : 0)

                        Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                            .font(.subheadline)
                            .foregroundStyle(FeltTheme.subtleText)
                            .opacity(appear ? 1 : 0)
                    }
                    .padding(.top, 40)

                    // Mood selector
                    VStack(spacing: 16) {
                        Text("How are you feeling?")
                            .font(.title3.weight(.medium))
                            .opacity(appear ? 1 : 0)

                        moodGrid
                    }

                    // Selected mood detail
                    if let mood = selectedMood {
                        VStack(spacing: 20) {
                            // Note
                            VStack(alignment: .leading, spacing: 8) {
                                Text("What's on your mind?")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)

                                TextField("A thought, a moment, anything...", text: $note, axis: .vertical)
                                    .lineLimit(3...6)
                                    .padding(12)
                                    .background(FeltTheme.cardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal)

                            // Gratitude
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Something you're grateful for?")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)

                                TextField("Optional...", text: $gratitude, axis: .vertical)
                                    .lineLimit(2...4)
                                    .padding(12)
                                    .background(FeltTheme.cardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal)

                            // Save
                            Button {
                                saveEntry(mood: mood)
                            } label: {
                                HStack {
                                    Text("Save")
                                        .font(.headline)
                                    Image(systemName: "checkmark")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(mood.color)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .padding(.horizontal)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    Spacer(minLength: 40)
                }
            }
            .background(FeltTheme.background)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
            .overlay {
                if saved {
                    savedOverlay
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    appear = true
                }
            }
        }
    }

    // MARK: - Mood Grid

    private var moodGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 12) {
            ForEach(Mood.allCases) { mood in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selectedMood = mood
                    }
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                } label: {
                    VStack(spacing: 6) {
                        Text(mood.emoji)
                            .font(.system(size: 36))
                            .scaleEffect(selectedMood == mood ? 1.2 : 1.0)

                        Text(mood.label)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(selectedMood == mood ? mood.color : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(selectedMood == mood ? mood.color.opacity(0.12) : .clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(selectedMood == mood ? mood.color : .clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(mood.label)\(selectedMood == mood ? ", selected" : "")")
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Save

    private func saveEntry(mood: Mood) {
        // Update existing entry for today, or create new
        if let existing = entries.first(where: { $0.isToday }) {
            existing.mood = mood
            existing.note = note
            existing.gratitude = gratitude
        } else {
            let entry = DayEntry(
                date: .now,
                mood: mood,
                note: note,
                gratitude: gratitude
            )
            modelContext.insert(entry)
        }
        try? modelContext.save()

        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif

        withAnimation(.spring(response: 0.4)) {
            saved = true
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            dismiss()
        }
    }

    private var savedOverlay: some View {
        VStack(spacing: 16) {
            if let mood = selectedMood {
                Text(mood.emoji)
                    .font(.system(size: 64))

                Text("Noted.")
                    .font(.system(.title2, design: .serif, weight: .medium))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .transition(.opacity)
    }
}
