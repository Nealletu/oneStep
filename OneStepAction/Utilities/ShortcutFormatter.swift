import Foundation

enum ShortcutFormatter {
    static func display(keyCode: UInt16, modifiers: UInt64) -> String {
        KeyCodeMapper.displayString(keyCode: keyCode, modifiers: modifiers)
    }

    static func display(for binding: ShortcutBinding) -> String {
        display(keyCode: binding.keyCode, modifiers: binding.modifiers)
    }
}
