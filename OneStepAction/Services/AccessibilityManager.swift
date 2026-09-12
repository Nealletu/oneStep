import ApplicationServices
import Foundation
import AppKit

/// Tracks Accessibility permission required for CGEventTap global hotkeys.
@MainActor
@Observable
final class AccessibilityManager {
    private(set) var isTrusted: Bool = false

    private var pollTimer: Timer?

    /// Imported C var is not Sendable — use the documented key string instead.
    private static let axTrustedPromptKey = "AXTrustedCheckOptionPrompt"

    init() {
        refresh()
    }

    func refresh() {
        isTrusted = AXIsProcessTrusted()
    }

    /// Prompt the system dialog once; also open System Settings for the user.
    func requestAccess() {
        let options = [Self.axTrustedPromptKey: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        refresh()
        openSystemSettings()
    }

    func openSystemSettings() {
        // macOS Ventura+ Privacy & Security → Accessibility
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    /// Start observing permission changes while the app is active.
    func startMonitoring() {
        stopMonitoring()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
    }

    func stopMonitoring() {
        pollTimer?.invalidate()
        pollTimer = nil
    }
}
