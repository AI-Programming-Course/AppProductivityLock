import FamilyControls
import ManagedSettings
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: LimitModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var showPicker = false
    @State private var showUnlockChallenge = false
    @State private var showRaiseChallenge = false

    private let ticker = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            Group {
                if model.isAuthorized {
                    limitForm
                } else {
                    onboarding
                }
            }
            .navigationTitle("FocusLock")
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.refresh() }
        }
        // Picks up a limit reached while the app is open.
        .onReceive(ticker) { _ in
            if scenePhase == .active { model.refresh() }
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var onboarding: some View {
        VStack(spacing: 20) {
            Image(systemName: "hourglass")
                .font(.system(size: 64))
                .foregroundStyle(.indigo)
            Text("Limit distracting apps")
                .font(.title2.bold())
            Text("FocusLock uses Screen Time to block the apps you choose once you've used them for your daily allowance.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Allow Screen Time access") {
                Task { await model.requestAuthorization() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
        }
        .padding(32)
    }

    private var limitForm: some View {
        Form {
            if !model.isAppGroupAvailable {
                Section {
                    Label("Setup problem: the App Group isn't available, so limits can't work.", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                } footer: {
                    Text("In project.yml, check BUNDLE_PREFIX and DEVELOPMENT_TEAM, run xcodegen generate, and make sure App Groups is enabled for FocusLock and ActivityMonitor under Signing & Capabilities.")
                }
            }

            Section {
                statusRow
            }

            Section("Apps to limit") {
                Button {
                    showPicker = true
                } label: {
                    HStack {
                        Text("Choose apps & websites")
                        Spacer()
                        Text(model.selectedCount == 0 ? "None" : "\(model.selectedCount) selected")
                            .foregroundStyle(.secondary)
                    }
                }
                .familyActivityPicker(isPresented: $showPicker, selection: $model.selection)

                ForEach(Array(model.selection.categoryTokens), id: \.self) { token in
                    Label(token)
                }
                ForEach(Array(model.selection.applicationTokens), id: \.self) { token in
                    Label(token)
                }
                ForEach(Array(model.selection.webDomainTokens), id: \.self) { token in
                    Label(token)
                }
            }

            Section {
                Stepper(value: $model.limitMinutes, in: 5...240, step: 5) {
                    HStack {
                        Text("Daily allowance")
                        Spacer()
                        Text("\(model.limitMinutes) min").monospacedDigit()
                    }
                }
            } header: {
                Text("Limit")
            } footer: {
                Text("Combined time across all selected apps. Resets at midnight.")
            }

            Section {
                Button(model.isActive ? "Save changes" : "Start daily limit") {
                    if model.isRaisingLimit {
                        showRaiseChallenge = true
                    } else {
                        model.start()
                    }
                }
                .disabled(model.selectedCount == 0 || (model.isActive && !model.hasUnsavedChanges))

                if model.hasUnsavedChanges {
                    Button("Discard changes") {
                        model.discardChanges()
                    }
                }

                if model.isActive {
                    Button("Turn off limit", role: .destructive) {
                        showUnlockChallenge = true
                    }
                }
            } footer: {
                if model.isRaisingLimit {
                    Text("Raising the allowance takes 6 math questions.")
                        .foregroundStyle(.orange)
                } else if model.isActive && model.hasUnsavedChanges {
                    Text("You have unsaved changes. They take effect when you tap Save changes.")
                        .foregroundStyle(.orange)
                }
            }
        }
        .sheet(isPresented: $showUnlockChallenge) {
            MathChallengeView(questionCount: 3, actionTitle: "Turn off limit") {
                model.stop()
            }
        }
        .sheet(isPresented: $showRaiseChallenge) {
            MathChallengeView(questionCount: 6, actionTitle: "Raise allowance") {
                model.start()
            }
        }
    }

    @ViewBuilder
    private var statusRow: some View {
        if !model.isActive {
            Label("Limit is off", systemImage: "pause.circle")
                .foregroundStyle(.secondary)
        } else if model.isBlockedToday {
            Label("Blocked until midnight", systemImage: "lock.fill")
                .foregroundStyle(.red)
        } else {
            Label("\(model.limitMinutes) min per day", systemImage: "hourglass")
                .foregroundStyle(.indigo)
        }
    }
}
