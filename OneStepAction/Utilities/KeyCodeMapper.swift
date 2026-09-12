import Carbon.HIToolbox
import Foundation

/// Maps between macOS hardware key codes and display symbols.
enum KeyCodeMapper {
    static let carbonModifiers: UInt64 = UInt64(cmdKey | shiftKey | optionKey | controlKey)

    /// Convert CGEventFlags to Carbon-style modifiers used by the data model.
    static func carbonModifiers(fromCGEventFlags flags: CGEventFlags) -> UInt64 {
        var result: UInt64 = 0
        if flags.contains(.maskCommand) { result |= UInt64(cmdKey) }
        if flags.contains(.maskShift) { result |= UInt64(shiftKey) }
        if flags.contains(.maskAlternate) { result |= UInt64(optionKey) }
        if flags.contains(.maskControl) { result |= UInt64(controlKey) }
        return result
    }

    static func cgEventFlags(fromCarbonModifiers modifiers: UInt64) -> CGEventFlags {
        var flags: CGEventFlags = []
        if modifiers & UInt64(cmdKey) != 0 { flags.insert(.maskCommand) }
        if modifiers & UInt64(shiftKey) != 0 { flags.insert(.maskShift) }
        if modifiers & UInt64(optionKey) != 0 { flags.insert(.maskAlternate) }
        if modifiers & UInt64(controlKey) != 0 { flags.insert(.maskControl) }
        return flags
    }

    static func symbol(forCarbonModifiers modifiers: UInt64) -> String {
        var parts: [String] = []
        if modifiers & UInt64(controlKey) != 0 { parts.append("⌃") }
        if modifiers & UInt64(optionKey) != 0 { parts.append("⌥") }
        if modifiers & UInt64(shiftKey) != 0 { parts.append("⇧") }
        if modifiers & UInt64(cmdKey) != 0 { parts.append("⌘") }
        return parts.joined()
    }

    static func displayString(keyCode: UInt16, modifiers: UInt64) -> String {
        symbol(forCarbonModifiers: modifiers) + keyName(for: keyCode)
    }

    static func keyName(for keyCode: UInt16) -> String {
        if let named = specialKeyNames[Int(keyCode)] {
            return named
        }
        return keyCodeToCharacter[keyCode] ?? "Key(\(keyCode))"
    }

    /// Whether the combo is a valid, recordable shortcut.
    /// Function keys (F1–F19) may stand alone; everything else requires a modifier
    /// so we never steal plain typing.
    static func isRecordable(keyCode: UInt16, modifiers: UInt64) -> Bool {
        let functionKeyCodes: Set<UInt16> = [
            UInt16(kVK_F1), UInt16(kVK_F2), UInt16(kVK_F3), UInt16(kVK_F4),
            UInt16(kVK_F5), UInt16(kVK_F6), UInt16(kVK_F7), UInt16(kVK_F8),
            UInt16(kVK_F9), UInt16(kVK_F10), UInt16(kVK_F11), UInt16(kVK_F12),
            UInt16(kVK_F13), UInt16(kVK_F14), UInt16(kVK_F15), UInt16(kVK_F16),
            UInt16(kVK_F17), UInt16(kVK_F18), UInt16(kVK_F19),
        ]
        if functionKeyCodes.contains(keyCode) {
            return true
        }
        return modifiers != 0
    }

    private static let specialKeyNames: [Int: String] = [
        kVK_Escape: "⎋",
        kVK_Tab: "⇥",
        kVK_Space: "Space",
        kVK_Return: "↩",
        kVK_Delete: "⌫",
        kVK_ForwardDelete: "⌦",
        kVK_LeftArrow: "←",
        kVK_RightArrow: "→",
        kVK_UpArrow: "↑",
        kVK_DownArrow: "↓",
        kVK_PageUp: "⇞",
        kVK_PageDown: "⇟",
        kVK_Home: "↖",
        kVK_End: "↘",
        kVK_Help: "?⃝",
        kVK_F1: "F1",
        kVK_F2: "F2",
        kVK_F3: "F3",
        kVK_F4: "F4",
        kVK_F5: "F5",
        kVK_F6: "F6",
        kVK_F7: "F7",
        kVK_F8: "F8",
        kVK_F9: "F9",
        kVK_F10: "F10",
        kVK_F11: "F11",
        kVK_F12: "F12",
        kVK_F13: "F13",
        kVK_F14: "F14",
        kVK_F15: "F15",
        kVK_F16: "F16",
        kVK_F17: "F17",
        kVK_F18: "F18",
        kVK_F19: "F19",
        kVK_ANSI_KeypadEnter: "⌤",
        kVK_ANSI_KeypadClear: "⌧",
    ]

    /// US layout mapping; sufficient for display of recorded keys.
    private static let keyCodeToCharacter: [UInt16: String] = [
        UInt16(kVK_ANSI_A): "A",
        UInt16(kVK_ANSI_B): "B",
        UInt16(kVK_ANSI_C): "C",
        UInt16(kVK_ANSI_D): "D",
        UInt16(kVK_ANSI_E): "E",
        UInt16(kVK_ANSI_F): "F",
        UInt16(kVK_ANSI_G): "G",
        UInt16(kVK_ANSI_H): "H",
        UInt16(kVK_ANSI_I): "I",
        UInt16(kVK_ANSI_J): "J",
        UInt16(kVK_ANSI_K): "K",
        UInt16(kVK_ANSI_L): "L",
        UInt16(kVK_ANSI_M): "M",
        UInt16(kVK_ANSI_N): "N",
        UInt16(kVK_ANSI_O): "O",
        UInt16(kVK_ANSI_P): "P",
        UInt16(kVK_ANSI_Q): "Q",
        UInt16(kVK_ANSI_R): "R",
        UInt16(kVK_ANSI_S): "S",
        UInt16(kVK_ANSI_T): "T",
        UInt16(kVK_ANSI_U): "U",
        UInt16(kVK_ANSI_V): "V",
        UInt16(kVK_ANSI_W): "W",
        UInt16(kVK_ANSI_X): "X",
        UInt16(kVK_ANSI_Y): "Y",
        UInt16(kVK_ANSI_Z): "Z",
        UInt16(kVK_ANSI_0): "0",
        UInt16(kVK_ANSI_1): "1",
        UInt16(kVK_ANSI_2): "2",
        UInt16(kVK_ANSI_3): "3",
        UInt16(kVK_ANSI_4): "4",
        UInt16(kVK_ANSI_5): "5",
        UInt16(kVK_ANSI_6): "6",
        UInt16(kVK_ANSI_7): "7",
        UInt16(kVK_ANSI_8): "8",
        UInt16(kVK_ANSI_9): "9",
        UInt16(kVK_ANSI_Minus): "-",
        UInt16(kVK_ANSI_Equal): "=",
        UInt16(kVK_ANSI_RightBracket): "]",
        UInt16(kVK_ANSI_LeftBracket): "[",
        UInt16(kVK_ANSI_Quote): "'",
        UInt16(kVK_ANSI_Semicolon): ";",
        UInt16(kVK_ANSI_Backslash): "\\",
        UInt16(kVK_ANSI_Comma): ",",
        UInt16(kVK_ANSI_Slash): "/",
        UInt16(kVK_ANSI_Period): ".",
        UInt16(kVK_ANSI_Grave): "`",
        UInt16(kVK_ANSI_KeypadDecimal): ".",
        UInt16(kVK_ANSI_KeypadMultiply): "*",
        UInt16(kVK_ANSI_KeypadPlus): "+",
        UInt16(kVK_ANSI_KeypadClear): "⌧",
        UInt16(kVK_ANSI_KeypadDivide): "/",
        UInt16(kVK_ANSI_KeypadEnter): "⌤",
        UInt16(kVK_ANSI_KeypadMinus): "-",
        UInt16(kVK_ANSI_KeypadEquals): "=",
        UInt16(kVK_ANSI_Keypad0): "0",
        UInt16(kVK_ANSI_Keypad1): "1",
        UInt16(kVK_ANSI_Keypad2): "2",
        UInt16(kVK_ANSI_Keypad3): "3",
        UInt16(kVK_ANSI_Keypad4): "4",
        UInt16(kVK_ANSI_Keypad5): "5",
        UInt16(kVK_ANSI_Keypad6): "6",
        UInt16(kVK_ANSI_Keypad7): "7",
        UInt16(kVK_ANSI_Keypad8): "8",
        UInt16(kVK_ANSI_Keypad9): "9",
    ]
}
