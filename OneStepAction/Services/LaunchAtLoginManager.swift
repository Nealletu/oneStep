import AppKit
import Foundation
import ServiceManagement

/// Launch at login via SMAppService (no manual LaunchAgents).
@MainActor
@Observable
final class LaunchAtLoginManager {
    private(set) var isEnabled: Bool = false
    private(set) var lastError: String?

    init() {
        refresh()
    }

    func refresh() {
        switch SMAppService.mainApp.status {
        case .enabled:
            isEnabled = true
        case .notFound, .notRegistered, .requiresApproval:
            isEnabled = false
        @unknown default:
            isEnabled = false
        }
    }

    func setEnabled(_ enabled: Bool) {
        lastError = nil
        do {
            if enabled {
                if SMAppService.mainApp.status == .requiresApproval {
                    SMAppService.openSystemSettingsLoginItems()
                }
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            lastError = error.localizedDescription
        }
        refresh()
    }
}
