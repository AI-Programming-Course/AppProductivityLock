import Foundation
import DeviceActivity
import ManagedSettings

/// iOS calls this in the background:
/// - when a day's interval starts (midnight, or when the app restarts monitoring)
///   we lift any block from a previous day but keep today's,
/// - when today's usage of the selected apps hits the limit we block them.
final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        SharedStore.resetIfNewDay()
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        guard event == .limitReached else { return }
        Shield.apply(SharedStore.selection)
        SharedStore.blockedOn = Date()
    }
}
