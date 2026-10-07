import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

/// Must match the App Group in project.yml.
enum SharedConfig {
    static let appGroup = "group.com.example.focuslock"
    static let defaultLimitMinutes = 30
}

extension DeviceActivityName {
    static let daily = Self("daily")
}

extension DeviceActivityEvent.Name {
    static let limitReached = Self("limitReached")
}

extension ManagedSettingsStore.Name {
    static let daily = Self("daily")
}

/// State shared between the app and the monitor extension via the App Group.
enum SharedStore {
    private static let defaults = UserDefaults(suiteName: SharedConfig.appGroup) ?? .standard

    private enum Key {
        static let selection = "selection"
        static let limitMinutes = "limitMinutes"
        static let isActive = "isActive"
        static let blockedOn = "blockedOn"
    }

    static var selection: FamilyActivitySelection {
        get {
            guard let data = defaults.data(forKey: Key.selection),
                  let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
            else { return FamilyActivitySelection() }
            return selection
        }
        set { defaults.set(try? JSONEncoder().encode(newValue), forKey: Key.selection) }
    }

    static var limitMinutes: Int {
        get {
            let value = defaults.integer(forKey: Key.limitMinutes)
            return value > 0 ? value : SharedConfig.defaultLimitMinutes
        }
        set { defaults.set(newValue, forKey: Key.limitMinutes) }
    }

    static var isActive: Bool {
        get { defaults.bool(forKey: Key.isActive) }
        set { defaults.set(newValue, forKey: Key.isActive) }
    }

    /// The day the limit was last reached; nil once a new day starts.
    static var blockedOn: Date? {
        get { defaults.object(forKey: Key.blockedOn) as? Date }
        set { defaults.set(newValue, forKey: Key.blockedOn) }
    }

    static var isBlockedToday: Bool {
        guard let blockedOn else { return false }
        return Calendar.current.isDateInToday(blockedOn)
    }
}

/// Applies or removes the block on the selected apps, categories and websites.
enum Shield {
    private static let store = ManagedSettingsStore(named: .daily)

    static func apply(_ selection: FamilyActivitySelection) {
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
    }

    static func clear() {
        store.clearAllSettings()
    }
}
