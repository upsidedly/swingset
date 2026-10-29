import Foundation
import Observation

indirect enum Value: Codable, Equatable, Sendable {
    case object([String: Value]), array([Value]), string(String), number(Double), bool(Bool), null
    init(from decoder: any Decoder) throws { let c = try decoder.singleValueContainer(); if c.decodeNil() { self = .null } else if let v = try? c.decode(Bool.self) { self = .bool(v) } else if let v = try? c.decode(Double.self) { self = .number(v) } else if let v = try? c.decode(String.self) { self = .string(v) } else if let v = try? c.decode([Value].self) { self = .array(v) } else { self = .object(try c.decode([String: Value].self)) } }
    func encode(to encoder: any Encoder) throws { var c = encoder.singleValueContainer(); switch self { case .object(let v): try c.encode(v); case .array(let v): try c.encode(v); case .string(let v): try c.encode(v); case .number(let v): try c.encode(v); case .bool(let v): try c.encode(v); case .null: try c.encodeNil() } }
    func data() throws -> Data { let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]; return try encoder.encode(self) }
}
struct Toy: Codable, Identifiable, Sendable {
    let id: String, name: String, description: String
    let width: Double, height: Double
    var symbol: String { ["spinner":"fanblades", "bubbles":"circle.grid.3x3.fill", "clicker":"button.programmable", "toggles":"switch.2", "gears":"gearshape.2", "abacus":"slider.horizontal.3", "magnets":"circle.hexagongrid.fill", "elastic":"point.topleft.down.to.point.bottomright.curvepath", "zipper":"arrow.up.and.down", "cradle":"circle.grid.2x1.fill"][id] ?? "hand.draw" }
}
struct ToyManifest: Codable, Sendable { let widgets: [Toy] }
struct SavedShelf: Codable, Sendable {
    var version = 1
    var selected = "spinner"
    var sound = false
    var haptics = true
    var states: [String: Value] = [:]
}
actor ShelfStorage {
    let root: URL
    init() {
        if let custom = ProcessInfo.processInfo.environment["SWINGSET_DATA_DIR"], custom.hasPrefix("/") { root = URL(fileURLWithPath: custom) }
        else { root = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/Swingset") }
    }
    func load() throws -> SavedShelf {
        let file = root.appendingPathComponent("shelf.json")
        guard FileManager.default.fileExists(atPath: file.path) else { return SavedShelf() }
        let data = try Data(contentsOf: file); guard data.count <= 2_000_000 else { throw ToyError("The saved shelf is too large.") }
        return try JSONDecoder().decode(SavedShelf.self, from: data)
    }
    func save(_ shelf: SavedShelf) throws {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        let file = root.appendingPathComponent("shelf.json")
        try encoder.encode(shelf).write(to: file, options: [.atomic])
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
    }
}
struct ToyError: Error, LocalizedError, Sendable { let message: String; init(_ message: String) { self.message = message }; var errorDescription: String? { message } }

@MainActor @Observable final class SwingsetModel {
    private(set) var toys: [Toy] = []
    private(set) var shelf = SavedShelf()
    private(set) var ready = false
    private(set) var adding = false
    var active = true
    var notice: String?
    var error: String?
    var resetRequest = 0
    @ObservationIgnored let storage = ShelfStorage()
    @ObservationIgnored let client = CorkClient()
    @ObservationIgnored private var startup: Task<Void, Never>?
    @ObservationIgnored private var saveTask: Task<Void, Never>?
    @ObservationIgnored private var addTask: Task<Void, Never>?
    var selected: Toy? { toys.first { $0.id == shelf.selected } }
    var manifest: URL? { Bundle.main.url(forResource: "manifest", withExtension: "json", subdirectory: "Widgets") }
    var entry: URL? { Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Widgets") }
    var state: Value { shelf.states[shelf.selected] ?? .object([:]) }
    func start() {
        guard startup == nil else { return }
        startup = Task { [weak self] in
            guard let self else { return }
            do {
                guard let manifest = self.manifest, self.entry != nil else { throw ToyError("Swingset's toy package is missing. Rebuild or reinstall the app.") }
                let data = try await Task.detached { try Data(contentsOf: manifest) }.value
                self.toys = try JSONDecoder().decode(ToyManifest.self, from: data).widgets
                self.shelf = try await self.storage.load()
                if !self.toys.contains(where: { $0.id == self.shelf.selected }) { self.shelf.selected = "spinner" }
                self.ready = true
            } catch { self.error = error.localizedDescription }
        }
    }
    func select(_ id: String) { guard toys.contains(where: { $0.id == id }) else { return }; shelf.selected = id; notice = nil; scheduleSave() }
    func preferences(sound: Bool? = nil, haptics: Bool? = nil) { if let sound { shelf.sound = sound }; if let haptics { shelf.haptics = haptics }; scheduleSave() }
    func update(_ state: Value, toy: String) { guard shelf.states[toy] != state else { return }; shelf.states[toy] = state; scheduleSave() }
    private func scheduleSave() {
        saveTask?.cancel()
        let snapshot = shelf
        saveTask = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(150)); try Task.checkCancellation(); try await self?.storage.save(snapshot) }
            catch is CancellationError { }
            catch { self?.error = error.localizedDescription }
        }
    }
    func addToCork() {
        guard !adding, let toy = selected, let manifest else { return }
        adding = true; notice = nil
        var state = state
        if case .object(var values) = state { values["sound"] = .bool(shelf.sound); values["haptics"] = .bool(shelf.haptics); state = .object(values) }
        let transfer = state
        addTask = Task { [weak self] in
            guard let self else { return }; defer { self.adding = false }
            do { try await self.client.add(manifest: manifest, widget: toy.id, state: transfer); self.notice = "Added \(toy.name) to Cork." }
            catch { self.error = error.localizedDescription }
        }
    }
    func finish() async { await startup?.value; await saveTask?.value; await addTask?.value; do { try await storage.save(shelf) } catch { self.error = error.localizedDescription } }
}
