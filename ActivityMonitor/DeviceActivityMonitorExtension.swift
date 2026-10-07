import Foundation
import DeviceActivity
import ManagedSettings

/// iOS calls this in the background:
/// - at midnight (interval start) we lift yesterday's block,
/// - when today's usage of the selected apps hits the limit we block them.
final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        Shield.clear()
        SharedStore.blockedOn = nil
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        Shield.clear()
        SharedStore.blockedOn = nil
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        guard event == .limitReached else { return }
        Shield.apply(SharedStore.selection)
        SharedStore.blockedOn = Date()
    }
}
