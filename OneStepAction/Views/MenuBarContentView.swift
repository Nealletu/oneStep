import SwiftUI

struct MenuBarContentView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button(String(localized: "menu.settings")) {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }

        Divider()

        // Same left-column checkmark layout as Launch at Login.
        // Click opens System Settings; the toggle never flips on its own.
        Toggle(String(localized: "menu.accessibility"), isOn: Binding(
            get: { model.accessibility.isTrusted },
            set: { _ in
                model.accessibility.openSystemSettings()
            }
        ))

        Toggle(String(localized: "menu.loginItem"), isOn: Binding(
            get: { model.loginItem.isEnabled },
            set: { model.loginItem.setEnabled($0) }
        ))

        Divider()

        Button(String(localized: "menu.about")) {
            AboutPresenter.show()
        }

        Button(String(localized: "menu.quit")) {
            NSApp.terminate(nil)
        }
    }
}
