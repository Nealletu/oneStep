import Foundation

/// A single global shortcut binding: one key combo → one action.
struct ShortcutBinding: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var keyCode: UInt16
    /// Carbon-style modifier flags (cmdKey, shiftKey, optionKey, controlKey).
    var modifiers: UInt64
    var action: ShortcutAction
    var isEnabled: Bool
    var name: String?

    init(
        id: UUID = UUID(),
        keyCode: UInt16,
        modifiers: UInt64,
        action: ShortcutAction,
        isEnabled: Bool = true,
        name: String? = nil
    ) {
        self.id = id
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.action = action
        self.isEnabled = isEnabled
        self.name = name
    }

    /// Display title: user-provided name, otherwise action default.
    var displayName: String {
        if let name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return name
        }
        return action.defaultName
    }

    var displayType: String {
        action.typeDisplayName
    }
}
