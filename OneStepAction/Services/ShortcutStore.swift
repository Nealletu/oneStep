import Foundation

/// Persists shortcut bindings. UserDefaults + Codable is enough for MVP.
@MainActor
@Observable
final class ShortcutStore {
    private static let storageKey = "onestep.shortcutBindings.v1"

    private(set) var bindings: [ShortcutBinding] = []

    init() {
        load()
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey) else {
            bindings = []
            return
        }
        do {
            bindings = try JSONDecoder().decode([ShortcutBinding].self, from: data)
        } catch {
            // Do not silently discard a corrupt payload — surface empty state and keep raw data intact.
            bindings = []
            NSLog("OneStep: failed to decode bindings: \(error)")
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(bindings)
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        } catch {
            NSLog("OneStep: failed to encode bindings: \(error)")
        }
    }

    func add(_ binding: ShortcutBinding) {
        bindings.append(binding)
        save()
    }

    func update(_ binding: ShortcutBinding) {
        guard let index = bindings.firstIndex(where: { $0.id == binding.id }) else { return }
        bindings[index] = binding
        save()
    }

    func delete(id: UUID) {
        bindings.removeAll { $0.id == id }
        save()
    }

    func setEnabled(_ enabled: Bool, id: UUID) {
        guard let index = bindings.firstIndex(where: { $0.id == id }) else { return }
        bindings[index].isEnabled = enabled
        save()
    }

    func binding(forID id: UUID) -> ShortcutBinding? {
        bindings.first { $0.id == id }
    }

    func hasInternalConflict(keyCode: UInt16, modifiers: UInt64, excludingID: UUID?) -> Bool {
        bindings.contains {
            $0.id != excludingID
                && $0.keyCode == keyCode
                && $0.modifiers == modifiers
        }
    }
}
