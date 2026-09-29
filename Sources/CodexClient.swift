import Foundation
import Darwin

enum CodexClientError: LocalizedError {
    case missingExecutable(String)
    case connectionClosed
    case timeout
    case malformedResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .missingExecutable(let path): return L10n.format("missing_executable", path)
        case .connectionClosed: return L10n.text("connection_closed")
        case .timeout: return L10n.text("timeout")
        case .malformedResponse: return L10n.text("malformed_response")
        case .server(let message): return L10n.format("server_error", message)
        }
    }
}

final class CodexClient {
    static let defaultExecutable = "/Applications/Codex.app/Contents/Resources/codex"
    static let bundledExecutable = "/Applications/ChatGPT.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex"

    static var executable: String {
        let override = ProcessInfo.processInfo.environment["CODEX_QUOTA_CODEX_PATH"]
        if let override = override, !override.isEmpty { return override }
        if let saved = UserDefaults.standard.string(forKey: "codexExecutablePath"), !saved.isEmpty {
            return saved
        }
        if FileManager.default.isExecutableFile(atPath: defaultExecutable) { return defaultExecutable }
        if FileManager.default.isExecutableFile(atPath: bundledExecutable) { return bundledExecutable }
        return defaultExecutable
    }

    static func fetch() throws -> QuotaState {
        let path = executable
        guard FileManager.default.isExecutableFile(atPath: path) else {
            throw CodexClientError.missingExecutable(path)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = ["app-server", "--listen", "stdio://"]
        let input = Pipe()
        let output = Pipe()
        guard Darwin.fcntl(input.fileHandleForWriting.fileDescriptor, F_SETNOSIGPIPE, 1) == 0 else {
            throw CodexClientError.connectionClosed
        }
        process.standardInput = input
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice

        try process.run()
        let deadline = Date().addingTimeInterval(20)
        let timeout = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
        timeout.schedule(deadline: .now() + 20)
        timeout.setEventHandler {
            stop(process)
        }
        timeout.resume()
        defer {
            timeout.cancel()
            input.fileHandleForWriting.closeFile()
            stop(process)
            process.waitUntilExit()
        }

        var reader = LineReader(handle: output.fileHandleForReading)
        try send([
            "id": 1,
            "method": "initialize",
            "params": ["clientInfo": [
                "name": "codex_quota_touch_bar",
                "title": "Codex Quota Touch Bar",
                "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.0"
            ]]
        ], to: input.fileHandleForWriting)

        while true {
            let message = try reader.next(deadline: deadline)
            guard (message["id"] as? NSNumber)?.intValue == 1 else { continue }
            try checkError(message)
            break
        }

        try send(["method": "initialized", "params": [String: Any]()], to: input.fileHandleForWriting)
        try send(["id": 2, "method": "account/rateLimits/read"], to: input.fileHandleForWriting)

        var limits: RateLimitsResponse?
        while Date() < deadline {
            let message: [String: Any]
            do { message = try reader.next(deadline: deadline) }
            catch {
                if let limits = limits { return QuotaState(rateLimits: limits) }
                throw error
            }
            guard let id = (message["id"] as? NSNumber)?.intValue else { continue }
            if id == 2 {
                try checkError(message)
                guard let result = message["result"] else { throw CodexClientError.malformedResponse }
                limits = try decode(RateLimitsResponse.self, from: result)
                break
            }
        }
        guard let limits = limits else { throw CodexClientError.timeout }
        if limits.codexLimit.planType != nil { return QuotaState(rateLimits: limits) }

        // account/read may include an email address. Request it only when the
        // quota response omitted the plan needed to choose the UI layout.
        try send(["id": 3, "method": "account/read", "params": ["refreshToken": false]],
                 to: input.fileHandleForWriting)
        while Date() < deadline {
            guard let message = try? reader.next(deadline: deadline) else { break }
            guard (message["id"] as? NSNumber)?.intValue == 3 else { continue }
            if let result = message["result"],
               let account = try? decode(AccountResponse.self, from: result) {
                return QuotaState(rateLimits: limits, accountPlan: account.account?.planType)
            }
            break
        }
        return QuotaState(rateLimits: limits)
    }

    private static func stop(_ process: Process) {
        guard process.isRunning else { return }
        process.terminate()
        let pid = process.processIdentifier
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 2) {
            if process.isRunning { _ = Darwin.kill(pid, SIGKILL) }
        }
    }

    private static func send(_ object: [String: Any], to handle: FileHandle) throws {
        var data = try JSONSerialization.data(withJSONObject: object, options: [.fragmentsAllowed])
        data.append(10)
        try data.withUnsafeBytes { bytes in
            guard let base = bytes.baseAddress else { return }
            var offset = 0
            while offset < bytes.count {
                let count = Darwin.write(handle.fileDescriptor, base.advanced(by: offset),
                                         bytes.count - offset)
                if count < 0 {
                    if errno == EINTR { continue }
                    throw CodexClientError.connectionClosed
                }
                if count == 0 { throw CodexClientError.connectionClosed }
                offset += count
            }
        }
    }

    private static func checkError(_ message: [String: Any]) throws {
        if let error = message["error"] as? [String: Any] {
            throw CodexClientError.server((error["message"] as? String) ?? "未知错误")
        }
    }

    private static func decode<T: Decodable>(_ type: T.Type, from object: Any) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: object, options: [.fragmentsAllowed])
        do { return try JSONDecoder().decode(type, from: data) }
        catch { throw CodexClientError.malformedResponse }
    }
}

private struct LineReader {
    let handle: FileHandle
    private var pending = Data()

    init(handle: FileHandle) { self.handle = handle }

    mutating func next(deadline: Date) throws -> [String: Any] {
        var buffer = [UInt8](repeating: 0, count: 4096)
        while true {
            if let newline = pending.firstIndex(of: 10) {
                let line = pending.prefix(upTo: newline)
                pending.removeSubrange(...newline)
                guard !line.isEmpty else { continue }
                guard let object = try? JSONSerialization.jsonObject(with: Data(line)),
                      let dictionary = object as? [String: Any] else {
                    throw CodexClientError.malformedResponse
                }
                return dictionary
            }
            guard Date() < deadline else { throw CodexClientError.timeout }
            let count = buffer.withUnsafeMutableBytes { bytes in
                Darwin.read(handle.fileDescriptor, bytes.baseAddress, bytes.count)
            }
            if count < 0 {
                if errno == EINTR { continue }
                throw CodexClientError.connectionClosed
            }
            guard count > 0 else {
                throw Date() >= deadline ? CodexClientError.timeout : CodexClientError.connectionClosed
            }
            pending.append(contentsOf: buffer.prefix(count))
            if pending.count > 2_000_000 { throw CodexClientError.malformedResponse }
        }
    }
}
