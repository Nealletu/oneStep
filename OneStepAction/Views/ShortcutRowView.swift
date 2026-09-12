import SwiftUI

struct ShortcutRowView: View {
    let binding: ShortcutBinding
    let onToggle: (Bool) -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(ShortcutFormatter.display(for: binding))
                .font(.body.monospaced())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
                .frame(width: 88, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(binding.displayName)
                    .font(.body)
                Text(binding.displayType)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { binding.isEnabled },
                set: { onToggle($0) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.small)

            Button(action: onEdit) {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
            .help(String(localized: "common.edit"))

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help(String(localized: "common.delete"))
        }
        .padding(.vertical, 4)
        .opacity(binding.isEnabled ? 1 : 0.55)
    }
}
