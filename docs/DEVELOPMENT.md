# Swingset development

Swingset 0.1.0 (build 3) targets macOS 14+, Swift 6, AppKit/SwiftUI and WebKit. It uses the existing Command Line Tools macOS 26.5 SDK on this host. No full Xcode setup, external JavaScript dependencies or network service is required.

## Structure

- `SwingsetApp.swift` owns the native menu, resizable window, sidebar, controls and sleep/session activation. The split-view children have explicit available height.
- `Model.swift` holds the observable shelf and owned startup, save and pin tasks. `ShelfStorage` serializes atomic JSON writes. `SWINGSET_DATA_DIR` selects isolated verification storage.
- `ToySurface.swift` hosts the bundled local page in a nonpersistent WebKit store. State and rate-limited output haptics are its only script messages. The page restores only when state changes, preventing a save/restore animation loop.
- `CorkClient.swift` speaks stdio JSON-RPC to `/Applications/Cork.app/Contents/MacOS/cork-mcp`. It checks readiness, reuses the current provider version when possible, then makes one add mutation. Requests have bounded replies/timeouts; ambiguous mutations are not retried.
- `Resources/Widgets/physics.js` contains pure deterministic models for all ten toys. `toys.js` draws materials and connects pointer, keyboard, optional sound, feedback, persistence and lifecycle. `manifest.json` is the local Cork provider contract. The build stamps its version with the app build to invalidate stale registrations.

The animation loop runs only while dragging or moving. Pause is idempotent, so a native state update cannot wake a settled toy repeatedly. State is saved after actions, once per second during sustained motion, and when settled. The native shelf debounces writes for 150 ms and flushes on orderly quit. Each embedded surface removes its message handler during teardown.

All artwork, toy drawing, sounds and the monochrome cradle icon are original code created for this project. No third-party toy images, fonts or recordings are bundled. Fidget toys are for play; the app makes no medical or treatment claim.

## Verification — 28 October 2026

On Apple Silicon/macOS 27.2, Swift 6.3.2 and SDK 26.5:

- Release build and installation in Applications complete without compiler warnings; strict bundle signature verification passes.
- 21 deterministic checks cover all ten models, finite state and serialization, damping, linked gears, bead constraints, spring settling, zipper detents, magnet attraction, cradle momentum transfer and malformed restored state.
- All ten toys were rendered and exercised in the real native app using pointer and/or keyboard input. Bubble Wrap reached two popped bubbles; Clicker reached three clicks without double counting; switches flipped, gears rotated, an abacus bead slid to the opposite side, magnets separated, elastic returned, the zipper moved, and the cradle transferred motion to the opposite end.
- Exact restart comparison preserved all ten saved toy states, the selected toy and Sound/Haptics preferences in an isolated shelf. The selected Bubble Wrap state was transferred through the native Add to Cork button into Cork 0.6.0. Cork registered all ten definitions, copied the assets and displayed the live toy after Swingset quit.
- Playing the Cork preview advanced the independent bubble count from two to four. That state saved without changing the layout revision or replacing layout Undo history. Cork’s package isolation canary blocked fetch/image requests and access to an outside fixture file.

The physical sensation of haptics and subjective sound quality require human evaluation. Only macOS 27.2 on this Mac was exercised; macOS 14–26 fallback runtimes and other hardware were not run. No logout/reboot was performed.

## Bare desktop toys — build 3

Matthew requested each widget be only its physical toy. The shared HTML now contains only its accessible canvas. The footer, instructions, reset control and preference checkboxes are removed from the widget. Canvas surfaces are transparent; decorative wood sheets, colour backdrops, separate display plates and explanatory print are removed. Physical housings, the bubble sheet, abacus frame and mechanical counter remain part of their toys. Each toy uses explicit art bounds shared by drawing and pointer conversion, preserving hit targets after the tighter framing. Mouse clicks do not leave a rectangular focus outline; keyboard focus remains visible. Native app controls and saved preferences are retained. Cork receives the new copied provider package without rebuilding its executable or changing board geometry/state.

Verification for build 3: release build/install and strict signature verification pass; JavaScript syntax checks pass. All ten updated toys were inspected in the native app, and a pointer press on the refitted Clicker incremented exactly once before resetting its test value. Existing Cork Spinner, Bubble Wrap and Clicker previews render with transparent surrounds and no widget footer controls; their seven popped bubbles and eleven clicks were preserved. The provider refresh to `0.1.0+3` left every live board item, per-instance state, position, hidden/show choice, desktop option and revision unchanged. Physics models were unchanged, so the prior 21 passing model checks remain applicable. This focused presentation update is ACCEPT; Cork’s unrelated OS permission blocker is unchanged.
