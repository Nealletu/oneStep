import SwiftUI

struct PermissionBanner: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.shield.fill")
                .foregroundStyle(.orange)
                .imageScale(.large)

            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "permission.title"))
                    .font(.headline)
                Text(String(localized: "permission.message"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(String(localized: "permission.openSettings")) {
                model.accessibility.requestAccess()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(12)
        .background(.orange.opacity(0.12))
    }
}

struct PermissionSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 36))
                .foregroundStyle(.orange)

            Text(String(localized: "permission.title"))
                .font(.title3.weight(.semibold))

            Text(String(localized: "permission.message"))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Button(String(localized: "permission.later")) {
                    dismiss()
                }
                Button(String(localized: "permission.openSettings")) {
                    model.accessibility.requestAccess()
                    model.accessibility.refresh()
                    if model.accessibility.isTrusted {
                        model.syncShortcuts()
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(28)
        .frame(width: 400)
        .onAppear {
            model.accessibility.refresh()
        }
        .onChange(of: model.accessibility.isTrusted) { _, trusted in
            if trusted {
                model.syncShortcuts()
                dismiss()
            }
        }
    }
}
