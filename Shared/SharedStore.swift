import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

enum SharedConfig {
    /// Read from Info.plist, where project.yml sets it from APP_GROUP_ID.
    static let appGroup = Bundle.main.object(forInfoDictionaryKey: "AppGroupID") as? String ?? ""
    static let defaultLimitMinutes = 30

    /// False when the App Group is missing from the entitlements or not registered
    /// with Apple. The app and the monitor extension then can't share settings, so
    /// nothing would ever get blocked.
    static var isAppGroupAvailable: Bool {
        !appGroup.isEmpty
            && FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) != nil
    }
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
    // Falls back to private storage only so the app can still launch and report
    // the setup problem (see SharedConfig.isAppGroupAvailable).
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

    /// Lifts a block left over from a previous day; keeps today's block in place.
    /// Called at the start of each day and whenever the app opens, since iOS
    /// doesn't guarantee it wakes the extension at midnight.
    static func resetIfNewDay() {
        if isBlockedToday {
            Shield.apply(selection)
        } else {
            Shield.clear()
            blockedOn = nil
        }
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
