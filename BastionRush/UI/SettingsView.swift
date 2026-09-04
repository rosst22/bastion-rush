import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PlayerProgress.self) private var progress
    @Environment(PurchaseService.self) private var purchases
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @State private var legalPage: LegalPage?
    @State private var showResetConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section("How to Play") {
                    helpRow("hand.draw.fill", "Drag left and right to steer the squad.")
                    helpRow("arrow.triangle.branch", "Cross one side of each gate; the other choice disappears.")
                    helpRow("scope", "Your soldiers fire automatically at the closest target.")
                    helpRow("shield.lefthalf.filled", "Keep enough soldiers alive to break the fortress.")
                }
                Section("Game") {
                    Toggle(isOn: $hapticsEnabled) { Label("Haptics", systemImage: "waveform") }
                    LabeledContent("Version", value: appVersion)
                }
                Section("Purchases") {
                    Button { Task { await purchases.restore() } } label: {
                        Label("Restore Purchases", systemImage: "arrow.clockwise")
                    }
                    LabeledContent("Commander Pack", value: purchases.isPremium ? "Active" : "Not purchased")
                    if let message = purchases.message {
                        Text(message).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section("Legal & Support") {
                    Button { legalPage = .privacy } label: { Label("Privacy Policy", systemImage: "hand.raised.fill") }
                    Button { legalPage = .terms } label: { Label("Terms of Use", systemImage: "doc.text.fill") }
                    Link(destination: URL(string: "mailto:support@rosstoma.me?subject=Bastion%20Rush%20Support")!) {
                        Label("Contact Support", systemImage: "envelope.fill")
                    }
                }
                Section {
                    Button(role: .destructive) { showResetConfirmation = true } label: {
                        Label("Reset Progress", systemImage: "trash")
                    }
                } footer: {
                    Text("Bastion Rush has no account, ads, location access, or cross-app tracking. Progress stays on this device.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.navy)
            .navigationTitle("Field Manual")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .preferredColorScheme(.dark)
        .sheet(item: $legalPage) { LegalView(page: $0) }
        .confirmationDialog("Reset all progress?", isPresented: $showResetConfirmation, titleVisibility: .visible) {
            Button("Reset Progress", role: .destructive) { progress.reset() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Coins, upgrades, and scores will be removed. Purchases can still be restored.")
        }
    }

    private func helpRow(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).foregroundStyle(AppTheme.cyan).frame(width: 24)
            Text(text).font(.subheadline)
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
