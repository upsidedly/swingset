# Swingset
Native macOS 14+ fidget app. Swift 6, AppKit/SwiftUI and local WebKit; no runtime packages or network service.
- Build with `scripts/build.sh`; install with `scripts/install.sh --no-build`. Quit Swingset before replacing its signed bundle. Use the existing Command Line Tools SDK, without Xcode selection/license changes.
- The ten working canvas toys live in Resources/Widgets and are shared with Cork through the local widget manifest. Keep physics pure/testable, keyboard actions accessible, animation dormant when settled/paused, sound optional, and feedback tied to actual detents/impacts.
- `node Tests/physics.test.js` verifies model behavior. Inspect the native app and the real Cork integration after changes; a screenshot of a mockup is not an interaction test.
- Swingset owns its local state. Use SWINGSET_DATA_DIR for isolated tests; do not overwrite real Cork or Swingset data with fixtures.
- Add to Cork uses the installed cork-mcp stdio bridge. Provider registration copies only local package assets. No arbitrary shell, remote widget store, account, telemetry, public action, or permission grant.
- Match Tuck/Snap/Cork's native monochrome icon and README family. Utility controls stay native; toys have physical materials and motion.
- Desktop widgets show only the physical toy on transparency. Do not add wrapper cards, inset backdrops, instruction labels, footer bars or on-widget checkboxes. Keep utility controls in the native app and preserve keyboard access.
