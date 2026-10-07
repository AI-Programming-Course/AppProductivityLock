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

    private let center = DeviceActivityCenter()

    init() {
        selection = SharedStore.selection
        limitMinutes = SharedStore.limitMinutes
        isActive = SharedStore.isActive
        isBlockedToday = SharedStore.isBlockedToday
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    }

    var selectedCount: Int {
        selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count
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
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        let threshold = DateComponents(minute: limitMinutes)
        let event: DeviceActivityEvent
        if #available(iOS 17.4, *) {
            // Count time already spent today, so restarting doesn't reset the allowance.
            event = DeviceActivityEvent(
                applications: selection.applicationTokens,
                categories: selection.categoryTokens,
                webDomains: selection.webDomainTokens,
                threshold: threshold,
                includesPastActivity: true
            )
        } else {
            event = DeviceActivityEvent(
                applications: selection.applicationTokens,
                categories: selection.categoryTokens,
                webDomains: selection.webDomainTokens,
                threshold: threshold
            )
        }

        do {
            center.stopMonitoring([.daily])
            try center.startMonitoring(.daily, during: schedule, events: [.limitReached: event])
            SharedStore.isActive = true
            isActive = true
            // If the limit was already hit today, keep the new selection blocked.
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
}
