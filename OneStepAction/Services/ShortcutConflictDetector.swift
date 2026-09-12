import AppKit
import Carbon.HIToolbox
import Foundation

/// Conflict detection with explicit honesty about macOS API limits.
/// - Internal duplicates: 100%
/// - Known system shortcuts: curated public list
/// - Third-party private hotkeys: cannot enumerate → report unknown, never "no conflict"
enum ShortcutConflictDetector {
    // MARK: - Public API

    static func evaluate(
        keyCode: UInt16,
        modifiers: UInt64,
        existingBindings: [ShortcutBinding],
        excludingID: UUID?
    ) -> ShortcutConflictResult {
        if isInternalConflict(
            keyCode: keyCode,
            modifiers: modifiers,
            existingBindings: existingBindings,
            excludingID: excludingID
        ) {
            return .known(String(localized: "conflict.internal"))
        }

        if let systemMessage = systemConflictMessage(keyCode: keyCode, modifiers: modifiers) {
            return .known(systemMessage)
        }

        if let potentialMessage = potentialConflictMessage(keyCode: keyCode, modifiers: modifiers) {
            return .potential(potentialMessage)
        }

        if let menuMessage = frontmostAppMenuConflict(keyCode: keyCode, modifiers: modifiers) {
            return .potential(menuMessage)
        }

        // No known hit — still not "100% free".
        return .unknown
    }

    static func isInternalConflict(
        keyCode: UInt16,
        modifiers: UInt64,
        existingBindings: [ShortcutBinding],
        excludingID: UUID?
    ) -> Bool {
        existingBindings.contains {
            $0.id != excludingID
                && $0.keyCode == keyCode
                && $0.modifiers == modifiers
        }
    }

    // MARK: - Known macOS system shortcuts (curated, public)

    /// Combinations that are standard macOS system shortcuts.
    /// Source of truth is public Apple documentation / default system bindings.
    private static let knownSystemShortcuts: [String: String] = {
        var map: [String: String] = [:]
        func key(_ keyCode: Int, _ mods: UInt64) -> String {
            "\(keyCode)|\(mods)"
        }
        let cmd = UInt64(cmdKey)
        let cmdShift = UInt64(cmdKey | shiftKey)
        let cmdOption = UInt64(cmdKey | optionKey)
        let cmdControl = UInt64(cmdKey | controlKey)
        let controlCmd = UInt64(controlKey | cmdKey)
        let cmdShiftOption = UInt64(cmdKey | shiftKey | optionKey)
        let cmdShiftControl = UInt64(cmdKey | shiftKey | controlKey)
        let control = UInt64(controlKey)

        // Lock screen
        map[key(Int(kVK_ANSI_Q), controlCmd)] = String(localized: "system.lockScreen")
        // Force quit
        map[key(Int(kVK_Escape), cmdOption)] = String(localized: "system.forceQuit")
        // Spotlight
        map[key(Int(kVK_Space), cmd)] = String(localized: "system.spotlight")
        map[key(Int(kVK_F4), cmd)] = String(localized: "system.spotlight")
        // Screenshot (cmd-shift-3/4/5)
        map[key(Int(kVK_ANSI_3), cmdShift)] = String(localized: "system.screenshot")
        map[key(Int(kVK_ANSI_4), cmdShift)] = String(localized: "system.screenshot")
        map[key(Int(kVK_ANSI_5), cmdShift)] = String(localized: "system.screenshot")
        // Switch app / window
        map[key(Int(kVK_Tab), cmd)] = String(localized: "system.switchApp")
        map[key(Int(kVK_Tab), cmdShift)] = String(localized: "system.switchAppBack")
        map[key(Int(kVK_Tab), cmdOption)] = String(localized: "system.switchApp")
        map[key(Int(kVK_Tab), control)] = String(localized: "system.switchApp")
        // Mission Control / App Exposé
        map[key(Int(kVK_UpArrow), control)] = String(localized: "system.missionControl")
        map[key(Int(kVK_DownArrow), control)] = String(localized: "system.appExpose")
        map[key(Int(kVK_F3), UInt64(0))] = String(localized: "system.missionControl")
        map[key(Int(kVK_F3), cmd)] = String(localized: "system.missionControl")
        // Emoji & Symbols
        map[key(Int(kVK_Space), controlCmd)] = String(localized: "system.emoji")
        // Show Desktop
        map[key(Int(kVK_F11), UInt64(0))] = String(localized: "system.showDesktop")
        // Help
        map[key(Int(kVK_Help), cmdShift)] = String(localized: "system.help")
        // Log out immediately
        map[key(Int(kVK_ANSI_Q), cmdShiftOption)] = String(localized: "system.logout")
        _ = cmdShiftControl
        return map
    }()

    private static func systemConflictMessage(keyCode: UInt16, modifiers: UInt64) -> String? {
        knownSystemShortcuts["\(Int(keyCode))|\(modifiers)"]
    }

    // MARK: - Potential (common app shortcuts)

    private static let potentialKeys: Set<UInt16> = [
        UInt16(kVK_ANSI_C),
        UInt16(kVK_ANSI_V),
        UInt16(kVK_ANSI_X),
        UInt16(kVK_ANSI_W),
        UInt16(kVK_ANSI_Q),
        UInt16(kVK_ANSI_A),
        UInt16(kVK_ANSI_S),
        UInt16(kVK_ANSI_P),
        UInt16(kVK_ANSI_Z),
        UInt16(kVK_ANSI_F),
        UInt16(kVK_ANSI_N),
        UInt16(kVK_ANSI_T),
        UInt16(kVK_ANSI_L),
        UInt16(kVK_ANSI_H),
        UInt16(kVK_ANSI_M),
        UInt16(kVK_ANSI_Comma),
    ]

    private static let cmdOnly = UInt64(cmdKey)

    private static func potentialConflictMessage(keyCode: UInt16, modifiers: UInt64) -> String? {
        guard modifiers == cmdOnly, potentialKeys.contains(keyCode) else { return nil }
        return String(localized: "conflict.potential")
    }

    // MARK: - Frontmost app menu (best effort)

    /// Attempt to read the frontmost app's menu key equivalents.
    /// If menus are not readable, return nil — caller shows "unknown", not "clear".
    /// Always invoked from UI (MainActor); AppKit menu APIs require main.
    private static func frontmostAppMenuConflict(keyCode: UInt16, modifiers: UInt64) -> String? {
        MainActor.assumeIsolated {
            guard let front = NSWorkspace.shared.frontmostApplication else { return nil }
            if front.bundleIdentifier == Bundle.main.bundleIdentifier {
                return menuConflictInApp(NSApp, keyCode: keyCode, modifiers: modifiers)
            }
            // Other apps' menus are not reliably readable without private APIs.
            return nil
        }
    }

    private static func menuConflictInApp(_ app: NSApplication?, keyCode: UInt16, modifiers: UInt64) -> String? {
        MainActor.assumeIsolated {
            guard let app else { return nil }
            let target = KeyCodeMapper.displayString(keyCode: keyCode, modifiers: modifiers)
            return findKeyEquivalent(target, in: app.mainMenu)
        }
    }

    private static func findKeyEquivalent(_ target: String, in menu: NSMenu?) -> String? {
        guard let menu else { return nil }
        for item in menu.items {
            if !item.keyEquivalent.isEmpty {
                let mods = carbonModifiers(from: item.keyEquivalentModifierMask)
                let combo = KeyCodeMapper.displayString(
                    keyCode: 0, // not used for equality below
                    modifiers: mods
                )
                // Compare by reconstructed symbol + character
                let itemDisplay = combo + item.keyEquivalent.uppercased()
                if itemDisplay == target || item.keyEquivalent.uppercased() == String(target.suffix(1)).uppercased(),
                   combo == String(target.dropLast()) {
                    return String(format: String(localized: "conflict.menu"), item.title)
                }
            }
            if let found = findKeyEquivalent(target, in: item.submenu) {
                return found
            }
        }
        return nil
    }

    private static func carbonModifiers(from mask: NSEvent.ModifierFlags) -> UInt64 {
        var mods: UInt64 = 0
        if mask.contains(.command) { mods |= UInt64(cmdKey) }
        if mask.contains(.shift) { mods |= UInt64(shiftKey) }
        if mask.contains(.option) { mods |= UInt64(optionKey) }
        if mask.contains(.control) { mods |= UInt64(controlKey) }
        return mods
    }
}
