import SwiftUI

struct ConflictStatusView: View {
    let result: ShortcutConflictResult

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: iconName)
                .foregroundStyle(tint)
            Text(result.message)
                .font(.callout)
                .foregroundStyle(tint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
    }

    private var iconName: String {
        switch result.level {
        case .knownConflict: return "xmark.circle.fill"
        case .potentialConflict: return "exclamationmark.triangle.fill"
        case .clear: return "checkmark.circle.fill"
        case .unknown: return "questionmark.circle"
        }
    }

    private var tint: Color {
        switch result.level {
        case .knownConflict: return .red
        case .potentialConflict: return .orange
        case .clear: return .green
        case .unknown: return .secondary
        }
    }
}
