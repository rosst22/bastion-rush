import SwiftUI

enum LegalPage: String, Identifiable {
    case privacy
    case terms
    var id: String { rawValue }
    var title: String { self == .privacy ? "Privacy Policy" : "Terms of Use" }
}

struct LegalView: View {
    @Environment(\.dismiss) private var dismiss
    let page: LegalPage

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(page == .privacy ? Self.privacyText : Self.termsText)
                    .font(.body).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(22)
            }
            .background(AppTheme.navy.ignoresSafeArea())
            .navigationTitle(page.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .preferredColorScheme(.dark)
    }

    private static let privacyText = """
    Effective September 4, 2026

    Bastion Rush is designed to work without an account. The game does not request your name, email address, contacts, precise location, photos, microphone, camera, or advertising identifier. It does not contain advertising or cross-app tracking.

    GAME DATA
    Coins, upgrades, settings, and scores are stored locally on your device using Apple’s standard preferences system. Deleting the app may delete this local progress.

    PURCHASES
    If you choose to buy the Commander Pack, Apple processes the payment. RevenueCat helps validate the purchase and restore access. Apple and RevenueCat may process purchase records, an app-scoped user identifier, device/app information, and diagnostic information under their own privacy policies. Bastion Rush does not receive your complete payment card number.

    CHILDREN
    Bastion Rush is not directed at children under 13 and does not knowingly collect personal information from children.

    RETENTION AND DELETION
    Local game data remains until you reset progress or delete the app. Purchase records are retained by Apple and RevenueCat as required to provide and restore purchases.

    CONTACT
    Questions or deletion requests can be sent to support@rosstoma.me. Because there is no Bastion Rush account, we generally cannot identify or delete device-local data remotely.
    """

    private static let termsText = """
    Effective September 4, 2026

    Bastion Rush is provided for personal entertainment. You may use the app only in compliance with applicable law and Apple’s platform terms.

    PURCHASES
    The Commander Pack is a one-time, non-consumable in-app purchase processed by Apple. It unlocks the features described on the purchase screen. You can use Restore Purchases on devices signed in to the purchasing Apple ID. Refund requests are handled under Apple’s policies.

    ACCEPTABLE USE
    Do not reverse engineer, exploit, interfere with, or redistribute the app except where applicable law expressly permits it.

    AVAILABILITY
    The app is provided “as is.” We may update gameplay, fix defects, or discontinue online services. The current version does not require an online game account.

    LIABILITY
    To the maximum extent permitted by law, the developer is not liable for indirect or consequential losses arising from use of the app.

    APPLE TERMS
    Apple is not responsible for support or maintenance. These terms are in addition to Apple’s Standard Licensed Application End User License Agreement.

    CONTACT
    support@rosstoma.me
    """
}
