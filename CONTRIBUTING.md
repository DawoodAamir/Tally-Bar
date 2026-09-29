# Contributing

Use Xcode 16 or later and preserve macOS 13 compatibility. Keep changes focused, use native controls, and avoid adding dependencies for small features.

Run `bash Scripts/test.sh` and `SWIFT_OPTIMIZATION=-O bash Scripts/test.sh`, then build the shared scheme in Debug and Release. Tests use disposable storage.

## Manual checks

- Start, pause, resume, and finish a session. Confirm paused time is excluded.
- Quit while running and relaunch; confirm the session continues. Repeat while paused.
- Check menu bar time, today's total, empty history, and deletion confirmation.
- Export CSV, cancel export, then open an export with a title containing quotes and commas.
- Check light and dark appearances, keyboard navigation, and VoiceOver labels.
- Verify the app stays out of the Dock and remains usable on macOS 13.

Use concise Conventional Commit messages, such as `fix: preserve paused sessions after relaunch`. Include reproduction steps and relevant verification in pull requests. Never include personal session files, credentials, signing identities, or build output.
