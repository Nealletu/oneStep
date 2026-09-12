import AppKit
import Carbon.HIToolbox
import SwiftUI

/// Records a key combination by capturing keyDown in a focusable NSView.
/// Escape cancels recording. Recorded keys are not dispatched as shortcuts
/// because the event tap only matches enabled global bindings — while recording
/// we also swallow the key in this view.
struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var keyCode: UInt16?
    @Binding var modifiers: UInt64
    @Binding var isRecording: Bool

    func makeNSView(context: Context) -> RecorderNSView {
        let view = RecorderNSView()
        view.onCapture = { code, mods in
            keyCode = code
            modifiers = mods
            isRecording = false
        }
        view.onCancel = {
            isRecording = false
        }
        view.onRecordingChange = { recording in
            isRecording = recording
        }
        return view
    }

    func updateNSView(_ nsView: RecorderNSView, context: Context) {
        nsView.currentDisplay = {
            if let keyCode {
                return KeyCodeMapper.displayString(keyCode: keyCode, modifiers: modifiers)
            }
            return nil
        }()
        nsView.isRecording = isRecording
        if isRecording {
            nsView.window?.makeFirstResponder(nsView)
        }
    }
}

final class RecorderNSView: NSView {
    var onCapture: ((UInt16, UInt64) -> Void)?
    var onCancel: (() -> Void)?
    var onRecordingChange: ((Bool) -> Void)?

    var currentDisplay: String?
    var isRecording: Bool = false {
        didSet {
            needsDisplay = true
            onRecordingChange?(isRecording)
        }
    }

    override var acceptsFirstResponder: Bool { true }
    override var focusRingMaskBounds: NSRect { bounds }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        isRecording = true
        needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        // Escape cancels recording.
        if event.keyCode == UInt16(kVK_Escape), event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty {
            isRecording = false
            onCancel?()
            needsDisplay = true
            return
        }

        // Require a modifier for character keys (already enforced at save, but warn early).
        let mods = KeyCodeMapper.carbonModifiers(fromCGEventFlags: CGEventFlags(rawValue: UInt64(event.modifierFlags.rawValue)))
        let code = event.keyCode

        // Ignore pure modifier key events.
        if code == UInt16(0xFFFF) || code == 0 {
            return
        }

        if !KeyCodeMapper.isRecordable(keyCode: code, modifiers: mods) {
            NSSound.beep()
            return
        }

        onCapture?(code, mods)
        isRecording = false
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 8, yRadius: 8)
        NSColor.controlBackgroundColor.setFill()
        path.fill()

        if isRecording {
            NSColor.controlAccentColor.withAlphaComponent(0.12).setFill()
            path.fill()
            NSColor.controlAccentColor.setStroke()
        } else {
            NSColor.separatorColor.setStroke()
        }
        path.lineWidth = 1.5
        path.stroke()

        let text: String = {
            if isRecording {
                return String(localized: "recorder.listening")
            }
            if let currentDisplay {
                return currentDisplay
            }
            return String(localized: "recorder.placeholder")
        }()

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .regular), weight: .medium),
            .foregroundColor: isRecording ? NSColor.controlAccentColor : NSColor.labelColor,
        ]
        let size = text.size(withAttributes: attributes)
        let origin = NSPoint(x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2)
        text.draw(at: origin, withAttributes: attributes)
    }

    override func accessibilityLabel() -> String? {
        String(localized: "recorder.a11y")
    }
}
