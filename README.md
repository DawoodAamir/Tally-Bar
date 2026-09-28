# Tally Bar

<img src="Tally%20Bar/Assets.xcassets/AppIcon.appiconset/icon-128%402x.png" width="96" alt="Tally Bar icon">

A native macOS menu bar time tracker. Start a named session, pause for a break, and finish to save it. Your timer and today's total are a click away.

## Features

- One active session with start, pause, resume, and finish controls.
- Live elapsed time in the menu bar, even when the panel is closed.
- Today's tracked time, including the active session. Overnight sessions count toward the appropriate day.
- Saved session history with confirmation before deleting a session.
- CSV export of finished sessions: name, start and end timestamps in UTC, and tracked seconds.
- Local storage, no account, no network access, and no third-party dependencies.
- Native SwiftUI controls, light and dark appearance, and accessibility labels.

## Run

Requires macOS 14 or later and Xcode 16 or later. Development was verified with Xcode 27.

1. Open `Tally Bar.xcodeproj`.
2. Select the **Tally Bar** scheme and **My Mac** destination.
3. Build and run, then click the timer in the menu bar. The app does not appear in the Dock.

The project uses local ad-hoc signing; no developer team is configured. App Store or outside distribution requires your own signing and notarization setup.

To build from Terminal:

```sh
xcodebuild -project 'Tally Bar.xcodeproj' -scheme 'Tally Bar' \
  -configuration Release -derivedDataPath build build
open 'build/Build/Products/Release/Tally Bar.app'
```

## Use

Enter a session name and choose **Start session**. An empty name becomes “Untitled session.” **Pause** stops counting; **Resume** continues the same session. **Finish** saves it to history and resets the timer.

Use the history button in the upper-right corner to review or delete sessions. **Export CSV…** saves all finished sessions to a file you choose; the active session is excluded. Pauses are excluded from the exported duration, so duration can be shorter than the interval between start and end.

A running session continues across sleep, quitting, and restarting the app. Pause it before leaving if you want to exclude that time. Elapsed time uses saved timestamps, so manual system-clock changes can affect a running session.

## Data

State is written atomically after every tracking change. In the sandboxed app, the file is stored at:

```text
~/Library/Containers/com.dd.tallybar/Data/Library/Application Support/Tally Bar/sessions.json
```

Back up this file to preserve history. If loading fails, the app preserves the original file and disables tracking instead of replacing it. If saving fails, the change is not applied and the app shows an error. CSV titles are quoted and formula-like titles are prefixed with an apostrophe for spreadsheet safety.

## Development

- `TrackerStore.swift`: session state, timestamp calculations, persistence, and CSV output.
- `ContentView.swift`: timer, history, and export panel.
- `TallyBarApp.swift`: menu bar entry point and live label.
- `Scripts/GenerateIcon.swift`: reproducible AppKit icon drawing at every required resolution.

Run the model regression checks:

```sh
bash Scripts/test.sh
```

These cover session transitions, persistence across relaunches, excluded pauses, midnight boundaries, CSV escaping, deletion, backward clock changes, corrupt files, and failed writes. They use temporary files and do not touch your session history.

Regenerate the icon from the repository root:

```sh
swift Scripts/GenerateIcon.swift
```

## Project description

Tally Bar is a lightweight time tracker for macOS that lives in the menu bar. Built with SwiftUI, it provides persistent session tracking, daily totals, session history, and CSV export without accounts or external services.
