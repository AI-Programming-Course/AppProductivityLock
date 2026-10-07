import DeviceActivity
import FamilyControls
import Foundation

@MainActor
final class LimitModel: ObservableObject {
    @Published var selection: FamilyActivitySelection
    @Published var limitMinutes: Int
    @Published private(set) var isActive: Bool
    @Published private(set) var isBlockedToday: Bool
    @Published private(set) var isAuthorized: Bool
    @Published var errorMessage: String?

    let isAppGroupAvailable = SharedConfig.isAppGroupAvailable

    /// What's currently stored and being monitored, to detect unsaved edits.
    private var savedSelection: FamilyActivitySelection
    private var savedLimitMinutes: Int

    private let center = DeviceActivityCenter()

    init() {
        let selection = SharedStore.selection
        let limitMinutes = SharedStore.limitMinutes
        self.selection = selection
        self.limitMinutes = limitMinutes
        savedSelection = selection
        savedLimitMinutes = limitMinutes
        isActive = SharedStore.isActive
        isBlockedToday = SharedStore.isBlockedToday
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
        refresh()
    }

    var selectedCount: Int {
        selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count
    }

    var hasUnsavedChanges: Bool {
        limitMinutes != savedLimitMinutes
            || selection.applicationTokens != savedSelection.applicationTokens
            || selection.categoryTokens != savedSelection.categoryTokens
            || selection.webDomainTokens != savedSelection.webDomainTokens
    }

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        } catch {
            errorMessage = "Screen Time access was not granted: \(error.localizedDescription)"
        }
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    }

    func refresh() {
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
        if isActive {
            SharedStore.resetIfNewDay()
        }
        isBlockedToday = SharedStore.isBlockedToday
    }

    /// Saves the selection and (re)starts the daily usage monitor.
    func start() {
        guard selectedCount > 0 else {
            errorMessage = "Pick at least one app first."
            return
        }
        SharedStore.selection = selection
        SharedStore.limitMinutes = limitMinutes

        // One schedule covering the whole day, repeating every day.
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
            repeats: true
        )
        // Count time already spent today, so restarting doesn't reset the allowance.
        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: DateComponents(minute: limitMinutes),
            includesPastActivity: true
        )

        do {
            center.stopMonitoring([.daily])
            try center.startMonitoring(.daily, during: schedule, events: [.limitReached: event])
            SharedStore.isActive = true
            isActive = true
            savedSelection = selection
            savedLimitMinutes = limitMinutes
            // If the limit was already hit today, keep the new selection blocked.
            // The extension does the same when monitoring restarts.
            if SharedStore.isBlockedToday {
                Shield.apply(selection)
            }
        } catch {
            errorMessage = "Couldn't start the daily limit: \(error.localizedDescription)"
        }
        refresh()
    }

    func stop() {
        center.stopMonitoring([.daily])
        Shield.clear()
        SharedStore.isActive = false
        SharedStore.blockedOn = nil
        isActive = false
        refresh()
    }

    func discardChanges() {
        selection = savedSelection
        limitMinutes = savedLimitMinutes
    }
}
