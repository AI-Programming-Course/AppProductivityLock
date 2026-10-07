import ManagedSettings
import ManagedSettingsUI
import UIKit

/// The screen shown instead of a blocked app or website.
final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    private var shield: ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: UIColor(red: 0.08, green: 0.07, blue: 0.16, alpha: 1),
            icon: UIImage(systemName: "hourglass"),
            title: ShieldConfiguration.Label(text: "Time's up for today", color: .white),
            subtitle: ShieldConfiguration.Label(
                text: "You've used your daily allowance. It resets at midnight.",
                color: .lightGray
            ),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Close", color: .white),
            primaryButtonBackgroundColor: .systemIndigo
        )
    }

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        shield
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        shield
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        shield
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        shield
    }
}
