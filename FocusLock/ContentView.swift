import FamilyControls
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: LimitModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var showPicker = false

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
                    model.start()
                }
                .disabled(model.selectedCount == 0)

                if model.isActive {
                    Button("Turn off limit", role: .destructive) {
                        model.stop()
                    }
                }
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
