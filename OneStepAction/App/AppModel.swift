import Carbon.HIToolbox
import Foundation

/// App-level state wired to services.
@MainActor
@Observable
final class AppModel {
    let store = ShortcutStore()
    let accessibility = AccessibilityManager()
    let loginItem = LaunchAtLoginManager()

    private(set) var shortcutManager: GlobalShortcutManager!
    private(set) var lastActionError: String?

    var showPermissionSheet = false

    init() {
        shortcutManager = GlobalShortcutManager { [weak self] binding in
            self?.noteTriggered(binding)
        }
    }

    func bootstrap() {
        accessibility.refresh()
        if !accessibility.isTrusted {
            showPermissionSheet = true
        }
        accessibility.startMonitoring()
        syncShortcuts()
    }

    func syncShortcuts() {
        guard accessibility.isTrusted else {
            shortcutManager.stop()
            return
        }
        shortcutManager.apply(bindings: store.bindings)
    }

    func addOrUpdate(_ binding: ShortcutBinding) {
        let existingInternal = store.hasInternalConflict(
            keyCode: binding.keyCode,
            modifiers: binding.modifiers,
            excludingID: binding.id
        )
        if existingInternal {
            lastActionError = String(localized: "conflict.internal")
            return
        }

        if store.binding(forID: binding.id) != nil {
            store.update(binding)
        } else {
            store.add(binding)
        }
        syncShortcuts()
    }

    func delete(id: UUID) {
        store.delete(id: id)
        syncShortcuts()
    }

    func setEnabled(_ enabled: Bool, id: UUID) {
        store.setEnabled(enabled, id: id)
        syncShortcuts()
    }

    private func noteTriggered(_ binding: ShortcutBinding) {
        NSLog("OneStep: shortcut triggered \(ShortcutFormatter.display(for: binding))")
    }

    func clearActionError() {
        lastActionError = nil
    }
}
