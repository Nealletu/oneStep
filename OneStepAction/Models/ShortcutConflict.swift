import Foundation

/// Conflict assessment for a shortcut. macOS has no public API to enumerate all
/// third-party global hotkeys — we never claim 100% coverage.
enum ShortcutConflictLevel: Hashable, Sendable {
    /// Known macOS system shortcut or internal duplicate — should block save.
    case knownConflict
    /// Common app shortcut (⌘C/⌘V/⌘W…) — warn, allow save.
    case potentialConflict
    /// No known conflict found.
    case clear
    /// Cannot confirm — private third-party hotkeys are invisible.
    case unknown
}

struct ShortcutConflictResult: Hashable, Sendable {
    var level: ShortcutConflictLevel
    var message: String

    static let unknown = ShortcutConflictResult(
        level: .unknown,
        message: String(localized: "conflict.unknown")
    )

    static let clear = ShortcutConflictResult(
        level: .clear,
        message: String(localized: "conflict.clear")
    )

    static func known(_ message: String) -> ShortcutConflictResult {
        ShortcutConflictResult(level: .knownConflict, message: message)
    }

    static func potential(_ message: String) -> ShortcutConflictResult {
        ShortcutConflictResult(level: .potentialConflict, message: message)
    }
}
