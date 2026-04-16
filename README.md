# Felt

**How did today feel?**

Felt is a beautiful, private daily mood journal. One check-in per day — pick your mood, jot a thought, note something you're grateful for. Watch your emotional story unfold over time.

## Why Felt?

Mental wellness apps are an $8.4B market, but most share your data with advertisers despite promising confidentiality. Felt takes the opposite approach:

- **100% on-device** — your feelings stay on your device
- **No account required** — open and start immediately
- **No tracking, no analytics, no third-party SDKs**
- **Simple by design** — one check-in per day, that's it

Apple's Journal app validated the category but remains too basic. Day One charges $35/year and got bloated. Felt fills the gap: beautiful, private, simple.

## Features

### Daily Mood Check-in
Eight expressive mood levels from Radiant to Awful, each with distinctive colors. Select your mood, optionally add a note and something you're grateful for. Takes 15 seconds.

### Mood Timeline
See your recent entries with mood indicators. Beautiful line chart shows your emotional trend over the past week with smooth interpolation.

### Calendar View
Full month calendar with color-coded mood dots. See patterns at a glance. Monthly stats show entry count, average mood, and most common feeling.

### Gratitude Tracking
Optional gratitude prompt with each check-in. Small moments of thankfulness compound over time.

### Streak Tracking
Consecutive day counter encourages the daily habit without punishing breaks.

### Sample Data
Ships with 15 days of sample entries so the app feels alive from the first moment.

## Platforms

- **iOS 18+** — iPhone and iPad
- **macOS 15+** — native Mac app
- **visionOS 2+** — Apple Vision Pro

## Tech Stack

- SwiftUI + Swift Charts (mood trend visualization)
- SwiftData (on-device persistence)
- Swift 6 strict concurrency
- XcodeGen for project generation

## Getting Started

```bash
git clone https://github.com/AgileLens/Felt.git
cd Felt
xcodegen generate
open Felt.xcodeproj
```

## Things to Try

1. **Run the app and tap a mood emoji for today** — the entry animates in and the calendar view shows today highlighted with your mood color; the whole check-in takes under 10 seconds.
2. **Add a note and a gratitude line to today's entry** — tap the entry to expand it; both fields save automatically on dismiss, no save button needed.
3. **Scroll back through the calendar to a past day and tap it** — your previous mood and note appear; moods are never editable after midnight so the history stays honest.
4. **After logging a few days, open the Trends view** — a chart shows your mood distribution over the past week/month; tap a day on the chart to jump to that entry.
5. **Check the Privacy screen in Settings** — confirm all data is stored locally in SwiftData with no network calls; there should be no mention of a server URL or analytics SDK.

## Architecture

```
Felt/
├── FeltApp.swift         # App entry, navigation logic
├── FeltTheme.swift       # Design system (soft purples, cards)
├── Mood.swift            # 8-level mood enum with colors/emojis
├── DayEntry.swift        # SwiftData model
├── WelcomeView.swift     # First-launch experience
├── CheckInView.swift     # Daily mood check-in flow
├── TimelineView.swift    # Main view with chart + recent entries
├── CalendarView.swift    # Month calendar with mood dots
├── SampleEntries.swift   # First-launch sample data
└── Assets.xcassets/      # App icon, colors
```

## Privacy

Felt stores all data locally using SwiftData. Zero network requests. Zero analytics. Your mood data is yours alone.

## License

MIT

---

Built with care by [AgileLens](https://github.com/AgileLens).
