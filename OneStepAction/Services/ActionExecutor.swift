import AppKit
import Darwin
import Foundation

/// Executes ShortcutActions. Decoupled from the event tap / UI.
enum ActionExecutorError: LocalizedError {
    case invalidURL(String)
    case appNotFound(String)
    case lockScreenUnavailable(String)
    case shellFailed(exitCode: Int32, stderr: String)

    var errorDescription: String? {
        switch self {
        case let .invalidURL(url):
            return String(format: String(localized: "error.invalidURL"), url)
        case let .appNotFound(name):
            return String(format: String(localized: "error.appNotFound"), name)
        case let .lockScreenUnavailable(detail):
            return String(format: String(localized: "error.lockScreen"), detail)
        case let .shellFailed(code, stderr):
            let trimmed = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                return String(format: String(localized: "error.shell"), code)
            }
            return String(format: String(localized: "error.shellDetail"), code, trimmed)
        }
    }
}

enum ActionExecutor {
    @MainActor
    static func execute(_ action: ShortcutAction) async throws {
        switch action {
        case .lockScreen:
            try lockScreen()
        case let .launchApplication(bundleID, appName, appPath):
            try launchApplication(bundleID: bundleID, appName: appName, appPath: appPath)
        case let .openURL(raw):
            try openURL(raw)
        case let .shellCommand(command):
            try await runShell(command)
        }
    }

    // MARK: - Lock Screen

    /// Locks the console session.
    ///
    /// macOS has **no public lock-screen API**. System `LockScreen.app` is an ARD overlay
    /// and cannot be launched as a normal app; `CGSession -suspend` was removed years ago.
    ///
    /// The de-facto approach used by Hammerspoon / Raycast-class tools is `SACLockScreenImmediate`
    /// from `login.framework`, resolved at runtime via `dlsym` (no compile-time private link).
    /// This is not keystroke simulation (⌃⌘Q).
    @MainActor
    private static func lockScreen() throws {
        typealias LockFn = @convention(c) () -> Void

        let path = "/System/Library/PrivateFrameworks/login.framework/Versions/Current/login"
        guard let handle = dlopen(path, RTLD_LAZY) else {
            let detail = dlerror().map { String(cString: $0) } ?? "dlopen failed"
            throw ActionExecutorError.lockScreenUnavailable(detail)
        }
        // Keep the handle loaded for process lifetime.
        guard let symbol = dlsym(handle, "SACLockScreenImmediate") else {
            throw ActionExecutorError.lockScreenUnavailable("SACLockScreenImmediate not found")
        }
        let lock = unsafeBitCast(symbol, to: LockFn.self)
        lock()
    }

    // MARK: - Launch App

    @MainActor
    private static func launchApplication(bundleID: String?, appName: String, appPath: String?) throws {
        if let appPath, !appPath.isEmpty {
            let url = URL(fileURLWithPath: appPath)
            let configuration = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.openApplication(at: url, configuration: configuration) { _, error in
                if let error {
                    NSLog("OneStep: open app at path failed: \(error)")
                }
            }
            return
        }

        if let bundleID, !bundleID.isEmpty,
           let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            let configuration = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.openApplication(at: url, configuration: configuration) { _, error in
                if let error {
                    NSLog("OneStep: open app by bundle id failed: \(error)")
                }
            }
            return
        }

        // Last resort: search common application locations by name.
        let candidatePaths = [
            "/Applications/\(appName).app",
            "\(NSHomeDirectory())/Applications/\(appName).app",
            "/System/Applications/\(appName).app",
        ]
        for path in candidatePaths where FileManager.default.fileExists(atPath: path) {
            let url = URL(fileURLWithPath: path)
            let configuration = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.openApplication(at: url, configuration: configuration) { _, error in
                if let error {
                    NSLog("OneStep: open app by name failed: \(error)")
                }
            }
            return
        }
        throw ActionExecutorError.appNotFound(appName)
    }

    // MARK: - Open URL

    @MainActor
    private static func openURL(_ raw: String) throws {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        var candidate = trimmed
        if !trimmed.lowercased().hasPrefix("http://"), !trimmed.lowercased().hasPrefix("https://"),
           !trimmed.contains("://") {
            candidate = "https://\(trimmed)"
        }
        guard let url = URL(string: candidate), url.scheme != nil else {
            throw ActionExecutorError.invalidURL(raw)
        }
        NSWorkspace.shared.open(url)
    }

    // MARK: - Shell

    private static func runShell(_ command: String) async throws {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ActionExecutorError.shellFailed(exitCode: -1, stderr: "Empty command")
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", trimmed]

        let stderrPipe = Pipe()
        process.standardError = stderrPipe
        process.standardOutput = Pipe()

        do {
            try process.run()
        } catch {
            throw ActionExecutorError.shellFailed(exitCode: -1, stderr: error.localizedDescription)
        }

        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        let stderr = String(data: stderrData, encoding: .utf8) ?? ""
        if process.terminationStatus != 0 {
            throw ActionExecutorError.shellFailed(exitCode: process.terminationStatus, stderr: stderr)
        }
    }
}
