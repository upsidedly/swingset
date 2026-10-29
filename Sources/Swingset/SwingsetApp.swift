import AppKit
import SwiftUI

@main enum SwingsetApp {
    @MainActor static func main() {
        let app = NSApplication.shared; app.setActivationPolicy(.regular)
        let delegate = SwingsetDelegate(); app.delegate = delegate; app.run(); withExtendedLifetime(delegate) {}
    }
}
@MainActor final class SwingsetDelegate: NSObject, NSApplicationDelegate {
    let model = SwingsetModel()
    var window: NSWindow?
    var termination: Task<Void, Never>?
    private var awake = true
    private var sessionActive = true
    func applicationDidFinishLaunching(_ notification: Notification) {
        let menu = NSMenu(), appMenu = NSMenu()
        let about = NSMenuItem(title: "About Swingset", action: #selector(about), keyEquivalent: ""); about.target = self; appMenu.addItem(about)
        appMenu.addItem(.separator()); let quit = NSMenuItem(title: "Quit Swingset", action: #selector(quit), keyEquivalent: "q"); quit.target = self; appMenu.addItem(quit)
        let app = NSMenuItem(); app.submenu = appMenu; menu.addItem(app)
        let file = NSMenu(), fileItem = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
        let close = NSMenuItem(title: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"); file.addItem(close); fileItem.submenu = file; menu.addItem(fileItem)
        NSApp.mainMenu = menu
        let workspace = NSWorkspace.shared.notificationCenter
        for (name, selector) in [(NSWorkspace.screensDidSleepNotification, #selector(sleeping)), (NSWorkspace.screensDidWakeNotification, #selector(waking)), (NSWorkspace.sessionDidResignActiveNotification, #selector(sessionInactive)), (NSWorkspace.sessionDidBecomeActiveNotification, #selector(sessionBecameActive))] { workspace.addObserver(self, selector: selector, name: name, object: nil) }
        model.start(); showWindow()
    }
    func showWindow() {
        if window == nil {
            let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 940, height: 650), styleMask: [.titled,.closable,.miniaturizable,.resizable], backing: .buffered, defer: false)
            window.title = "Swingset"; window.minSize = CGSize(width: 780, height: 560); window.toolbarStyle = .unifiedCompact; window.setFrameAutosaveName("Swingset"); window.center(); window.isReleasedWhenClosed = false
            window.contentViewController = NSHostingController(rootView: SwingsetView(model: model)); self.window = window
        }
        window?.deminiaturize(nil); window?.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { showWindow(); return true }
    func applicationDidBecomeActive(_ notification: Notification) { model.active = awake && sessionActive }
    func applicationDidResignActive(_ notification: Notification) { model.active = false }
    @objc private func sleeping() { awake = false; model.active = false }
    @objc private func waking() { awake = true; model.active = NSApp.isActive && sessionActive }
    @objc private func sessionInactive() { sessionActive = false; model.active = false }
    @objc private func sessionBecameActive() { sessionActive = true; model.active = NSApp.isActive && awake }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if termination == nil { termination = Task { await model.finish(); NSApp.reply(toApplicationShouldTerminate: true) } }; return .terminateLater
    }
    @objc func about() { NSApp.orderFrontStandardAboutPanel(options: [.applicationName:"Swingset", .applicationVersion:"0.1.0", .credits:NSAttributedString(string:"Ten small things to play with. A sibling to Tuck, Snap and Cork.")]) }
    @objc func quit() { NSApp.terminate(nil) }
}
struct SwingsetView: View {
    @Bindable var model: SwingsetModel
    var body: some View {
        VStack(spacing: 0) {
            if let error = model.error {
                HStack(alignment: .top) { Image(systemName: "exclamationmark.triangle"); Text(error).textSelection(.enabled); Spacer(); Button("Dismiss", systemImage: "xmark") { model.error = nil }.labelStyle(.iconOnly).buttonStyle(.plain) }.padding(12).background(.quaternary)
            }
            GeometryReader { area in
                HSplitView {
                    List(selection: Binding<String?>(get: { model.shelf.selected }, set: { if let id = $0 { model.select(id) } })) {
                        ForEach(model.toys) { toy in Label(toy.name, systemImage: toy.symbol).padding(.vertical, 6).tag(toy.id) }
                    }.listStyle(.sidebar).frame(minWidth: 180, idealWidth: 210, maxWidth: 230).frame(height: area.size.height)
                    if let toy = model.selected {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .firstTextBaseline) { Text(toy.name).font(.title2.weight(.semibold)); Spacer(); Button("Reset", systemImage: "arrow.counterclockwise") { model.resetRequest += 1 }.keyboardShortcut("0", modifiers: .command) }
                            Text(toy.description).font(.callout).foregroundStyle(.secondary)
                            ToyPreview(model: model, toy: toy).id(toy.id).frame(maxWidth: .infinity, maxHeight: .infinity).accessibilityLabel(toy.name)
                            HStack { Toggle("Sound", isOn: Binding(get: { model.shelf.sound }, set: { model.preferences(sound: $0) })); Toggle("Haptics", isOn: Binding(get: { model.shelf.haptics }, set: { model.preferences(haptics: $0) })); Spacer(); Text("Space to play · R to reset").font(.caption).foregroundStyle(.secondary) }.toggleStyle(.checkbox)
                        }.padding(24).frame(minWidth: 530, maxWidth: .infinity).frame(height: area.size.height)
                    } else { ProgressView("Opening the toy box…").frame(maxWidth: .infinity, maxHeight: .infinity).frame(height: area.size.height) }
                }
            }
            Divider()
            HStack { Text(model.notice ?? "Play here, or pin a toy to your desktop with Cork.").font(.callout).foregroundStyle(.secondary); Spacer(); Button(model.adding ? "Adding…" : "Add to Cork", systemImage: "pin") { model.addToCork() }.disabled(!model.ready || model.adding).keyboardShortcut("a", modifiers: [.command,.shift]) }.padding(.horizontal, 18).padding(.vertical, 12)
        }
    }
}
