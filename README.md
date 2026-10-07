# FocusLock

A minimal Opal-style iPhone app in SwiftUI. Pick the apps you want to limit (Reddit,
YouTube, TikTok, …). Once you've used them for **30 minutes in a day** (adjustable), iOS
blocks them until midnight.

It uses Apple's Screen Time API:

| Part | Framework | Job |
|---|---|---|
| `FocusLock/` (app) | FamilyControls, DeviceActivity | Permission, app picker, starts the daily monitor |
| `ActivityMonitor/` (extension) | DeviceActivity, ManagedSettings | Woken by iOS when the limit is hit → blocks the apps; clears the block at midnight |
| `ShieldConfig/` (extension) | ManagedSettingsUI | The "Time's up for today" screen shown on blocked apps |
| `Shared/` | — | Settings shared through an App Group |

> Apple doesn't let apps name other apps directly (no "block com.reddit"). You choose them
> once in Apple's picker, and FocusLock stores the private tokens it gets back.

## Requirements

- A Mac with Xcode 15.3+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- A **real iPhone** on iOS 17+ (Screen Time doesn't work properly in the Simulator)
- An Apple Developer account. Family Controls works for development builds. For
  TestFlight or the App Store you must
  [request the distribution entitlement](https://developer.apple.com/contact/request/family-controls-distribution).

## Setup

1. Replace `com.example.focuslock` with your own prefix (e.g. `com.yourname.focuslock`) in
   `project.yml` **and** `Shared/SharedStore.swift`. This changes the bundle IDs and the App Group.
2. In `project.yml`, set `DEVELOPMENT_TEAM` to your Team ID (Xcode → Settings → Accounts).
3. Generate and open the project:
   ```sh
   xcodegen generate
   open FocusLock.xcodeproj
   ```
4. For each of the 3 targets, check **Signing & Capabilities**: your team should be selected
   and *Family Controls* plus *App Groups* should be listed. Let Xcode register them if it asks.
5. Plug in your iPhone, select it, and press **Run**.

## Using it

1. Tap **Allow Screen Time access** and confirm with Face ID / passcode.
2. **Choose apps & websites** → tick Reddit, YouTube, TikTok (and their websites, if you like).
3. Leave the allowance at 30 min and tap **Start daily limit**.

Tip for testing: set the allowance to 5 minutes, use one of the apps, and it should get blocked.

## Notes

- The 30 minutes is **combined** across all selected apps, not per app.
- The day runs 00:00–23:59, and the block lifts at midnight.
- On iOS 17.4+ time already spent today counts, so stopping and restarting the limit doesn't
  give you a fresh 30 minutes.
- Turning the limit off from the app removes the block right away. Opal-style "hard mode"
  (no way out) would be a later addition.
