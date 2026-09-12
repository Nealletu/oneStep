import Foundation

/// Action attached to a global shortcut. New cases can be added without touching the event tap.
enum ShortcutAction: Hashable, Sendable {
    case lockScreen
    case launchApplication(bundleID: String?, appName: String, appPath: String?)
    case openURL(String)
    case shellCommand(String)
}

// MARK: - Display

extension ShortcutAction {
    var defaultName: String {
        switch self {
        case .lockScreen:
            return String(localized: "action.lockScreen")
        case let .launchApplication(_, appName, _):
            return String(localized: "action.launchApp.\(appName)")
        case let .openURL(url):
            return String(format: String(localized: "action.openURL"), url)
        case let .shellCommand(command):
            var trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count > 28 {
                trimmed = String(trimmed.prefix(28)) + "…"
            }
            return String(format: String(localized: "action.shell"), trimmed)
        }
    }

    var typeDisplayName: String {
        switch self {
        case .lockScreen:
            return String(localized: "type.system")
        case .launchApplication:
            return String(localized: "type.app")
        case .openURL:
            return String(localized: "type.url")
        case .shellCommand:
            return String(localized: "type.shell")
        }
    }
}

// MARK: - Codable

extension ShortcutAction: Codable {
    private enum CodingKeys: String, CodingKey {
        case kind
        case bundleID
        case appName
        case appPath
        case url
        case command
    }

    private enum Kind: String, Codable {
        case lockScreen
        case launchApplication
        case openURL
        case shellCommand
        // Reserved for future extension (architecture allows it).
        case appleScript
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        switch kind {
        case .lockScreen:
            self = .lockScreen
        case .launchApplication:
            self = .launchApplication(
                bundleID: try container.decodeIfPresent(String.self, forKey: .bundleID),
                appName: try container.decode(String.self, forKey: .appName),
                appPath: try container.decodeIfPresent(String.self, forKey: .appPath)
            )
        case .openURL:
            self = .openURL(try container.decode(String.self, forKey: .url))
        case .shellCommand:
            self = .shellCommand(try container.decode(String.self, forKey: .command))
        case .appleScript:
            throw DecodingError.dataCorruptedError(
                forKey: .kind,
                in: container,
                debugDescription: "appleScript action is reserved and not implemented in MVP"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .lockScreen:
            try container.encode(Kind.lockScreen, forKey: .kind)
        case let .launchApplication(bundleID, appName, appPath):
            try container.encode(Kind.launchApplication, forKey: .kind)
            try container.encodeIfPresent(bundleID, forKey: .bundleID)
            try container.encode(appName, forKey: .appName)
            try container.encodeIfPresent(appPath, forKey: .appPath)
        case let .openURL(url):
            try container.encode(Kind.openURL, forKey: .kind)
            try container.encode(url, forKey: .url)
        case let .shellCommand(command):
            try container.encode(Kind.shellCommand, forKey: .kind)
            try container.encode(command, forKey: .command)
        }
    }
}
