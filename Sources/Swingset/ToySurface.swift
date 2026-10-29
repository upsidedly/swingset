import AppKit
import WebKit
import SwiftUI

@MainActor final class ToySurface: NSView, WKScriptMessageHandler, WKNavigationDelegate {
    let web: WKWebView
    let toyID: String
    private var loaded = false
    private var lastState = Data()
    private var reset = 0
    private var lastFeedback = 0.0
    var onState: ((Value) -> Void)?
    var initialState: Value
    var sound = false, haptics = true, active = true
    init(entry: URL, toy: String, state: Value) {
        toyID = toy; initialState = state
        let config = WKWebViewConfiguration(); config.websiteDataStore = .nonPersistent(); config.preferences.javaScriptCanOpenWindowsAutomatically = false
        web = WKWebView(frame: .zero, configuration: config)
        super.init(frame: .zero); web.navigationDelegate = self; web.setValue(false, forKey: "drawsBackground")
        config.userContentController.add(self, name: "cork"); addSubview(web)
        var url = URLComponents(url: entry, resolvingAgainstBaseURL: false); url?.fragment = toy
        web.loadFileURL(url?.url ?? entry, allowingReadAccessTo: entry.deletingLastPathComponent())
    }
    required init?(coder: NSCoder) { nil }
    override func layout() { super.layout(); web.frame = bounds }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { loaded = true; update(state: initialState, sound: sound, haptics: haptics, active: active, reset: reset) }
    func update(state: Value, sound: Bool, haptics: Bool, active: Bool, reset: Int) {
        self.initialState = state; self.sound = sound; self.haptics = haptics; self.active = active
        guard loaded else { self.reset = reset; return }
        if let data = try? state.data(), data != lastState { lastState = data; web.evaluateJavaScript("window.corkWidget?.restore(\(String(decoding: data, as: UTF8.self)))", completionHandler: nil) }
        web.evaluateJavaScript("window.corkWidget?.configure({nativeChrome:true,sound:\(sound),haptics:\(haptics)});window.corkWidget?.pause(\(!active));", completionHandler: nil)
        if self.reset != reset { self.reset = reset; web.evaluateJavaScript("window.corkWidget?.reset()", completionHandler: nil) }
    }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.frameInfo.isMainFrame, let body = message.body as? [String: Any], let type = body["type"] as? String else { return }
        if type == "feedback" { let now = ProcessInfo.processInfo.systemUptime; if haptics && now - lastFeedback > 0.025 { lastFeedback = now; NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now) }; return }
        guard type == "state", let state = body["state"] as? [String: Any], let data = try? JSONSerialization.data(withJSONObject: state), data.count <= 64_000, let value = try? JSONDecoder().decode(Value.self, from: data) else { return }
        lastState = (try? value.data()) ?? data; onState?(value)
    }
    func stop() { web.stopLoading(); web.configuration.userContentController.removeScriptMessageHandler(forName: "cork"); web.navigationDelegate = nil }
}
struct ToyPreview: NSViewRepresentable {
    let model: SwingsetModel
    let toy: Toy
    func makeNSView(context: Context) -> ToySurface {
        let entry = model.entry ?? URL(fileURLWithPath: "/nonexistent-swingset-toy.html")
        let view = ToySurface(entry: entry, toy: toy.id, state: model.state)
        view.onState = { [weak model] value in model?.update(value, toy: toy.id) }; return view
    }
    func updateNSView(_ view: ToySurface, context: Context) { view.update(state: model.state, sound: model.shelf.sound, haptics: model.shelf.haptics, active: model.active, reset: model.resetRequest) }
    static func dismantleNSView(_ view: ToySurface, coordinator: ()) { view.stop() }
}
