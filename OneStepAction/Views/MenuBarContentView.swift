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

        Button {
            model.accessibility.openSystemSettings()
        } label: {
            if model.accessibility.isTrusted {
                Text(String(localized: "menu.accessibilityStatus.on"))
            } else {
                Text(String(localized: "menu.accessibilityStatus.off"))
            }
        }

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
