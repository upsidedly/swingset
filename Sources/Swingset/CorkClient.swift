import Foundation
import Darwin

actor CorkClient {
    func add(manifest: URL, widget: String, state: Value) async throws {
        let executable = "/Applications/Cork.app/Contents/MacOS/cork-mcp"
        guard FileManager.default.isExecutableFile(atPath: executable) else { throw ToyError("Install Cork in Applications, then add this toy again.") }
        let process = Process(), input = Pipe(), output = Pipe()
        process.executableURL = URL(fileURLWithPath: executable); process.standardInput = input; process.standardOutput = output; process.standardError = FileHandle.nullDevice
        try process.run()
        defer { try? input.fileHandleForWriting.close(); if process.isRunning { process.terminate() } }
        var counter = 0, buffered = Data()
        func rpc(_ method: String, _ params: [String: Any]) throws -> [String: Any] {
            counter += 1
            let request: [String: Any] = ["jsonrpc":"2.0", "id":counter, "method":method, "params":params]
            var data = try JSONSerialization.data(withJSONObject: request); data.append(10); try input.fileHandleForWriting.write(contentsOf: data)
            let deadline = Date().addingTimeInterval(35)
            while !buffered.contains(10) {
                var event = pollfd(fd: output.fileHandleForReading.fileDescriptor, events: Int16(POLLIN), revents: 0)
                let remaining = max(0, deadline.timeIntervalSinceNow)
                guard remaining > 0, poll(&event, 1, Int32(remaining * 1000)) > 0 else { throw ToyError("Cork did not respond. Inspect the wall before adding this toy again.") }
                let chunk = output.fileHandleForReading.availableData
                guard !chunk.isEmpty else { throw ToyError("Cork closed its connection.") }
                buffered.append(chunk); guard buffered.count <= 4_000_000 else { throw ToyError("Cork returned too much data.") }
            }
            guard let newline = buffered.firstIndex(of: 10) else { throw ToyError("Invalid Cork reply.") }
            let line = buffered.prefix(upTo: newline); buffered.removeSubrange(...newline)
            guard let reply = try JSONSerialization.jsonObject(with: line) as? [String: Any] else { throw ToyError("Invalid Cork reply.") }
            if let error = reply["error"] as? [String: Any] { throw ToyError(error["message"] as? String ?? "Cork rejected the request.") }
            return reply["result"] as? [String: Any] ?? [:]
        }
        func call(_ name: String, _ arguments: [String: Any]) throws -> [String: Any] {
            let result = try rpc("tools/call", ["name":name, "arguments":arguments])
            let content = result["content"] as? [[String: Any]], text = content?.first?["text"] as? String ?? ""
            if result["isError"] as? Bool == true { throw ToyError(text) }
            return (try? JSONSerialization.jsonObject(with: Data(text.utf8))) as? [String: Any] ?? [:]
        }
        _ = try rpc("initialize", ["protocolVersion":"2025-11-25", "clientInfo":["name":"Swingset", "version":"0.1.0"], "capabilities":[:]])
        var idle = 0
        for _ in 0..<20 {
            do { let board = try call("cork_get_board", [:]); idle = board["saving"] as? Bool == false ? idle + 1 : 0 }
            catch { idle = 0 }
            if idle >= 2 { break }
            try await Task.sleep(for: .milliseconds(150))
        }
        guard idle >= 2 else { throw ToyError("Cork is busy. Try adding this toy once the wall has finished saving.") }
        let registry = try call("cork_get_widgets", [:])
        let own = try JSONSerialization.jsonObject(with: Data(contentsOf: manifest)) as? [String: Any]
        let existing = (registry["providers"] as? [[String: Any]])?.first { ($0["manifest"] as? [String: Any])?["id"] as? String == "dev.upsided.swingset" }
        let installedVersion = (existing?["manifest"] as? [String: Any])?["version"] as? String
        if installedVersion != own?["version"] as? String || existing?["source"] as? String != manifest.resolvingSymlinksInPath().path {
            _ = try call("cork_register_widgets", ["path":manifest.path])
        }
        let transfer = try JSONSerialization.jsonObject(with: state.data())
        _ = try call("cork_add_widget", ["provider":"dev.upsided.swingset", "widget":widget, "widget_state":transfer])
    }
}
