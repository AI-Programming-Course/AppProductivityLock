import SwiftUI

@main
struct FocusLockApp: App {
    @StateObject private var model = LimitModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
        }
    }
}
