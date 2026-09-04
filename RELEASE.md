# App Store Release Checklist

## Required before TestFlight

- [ ] Confirm the App Store Connect bundle ID matches `com.rosstoma.BastionRush` (or change it in `project.yml`).
- [ ] Add the RevenueCat public iOS SDK key to `Config/Secrets.xcconfig`.
- [ ] Create the non-consumable `com.rosstoma.bastionrush.commanderpack` in App Store Connect.
- [ ] In RevenueCat, attach the product to entitlement `commander_pack` and the current offering.
- [ ] Confirm Paid Apps Agreement, tax, and banking are active.
- [x] Publish `docs/privacy.html` and `docs/support.html` through GitHub Pages.
- [ ] Confirm both public URLs in `docs/app-store-metadata.md` return successfully before submission.
- [ ] Run on at least one physical iPhone and test a sandbox purchase plus Restore Purchases.
- [ ] Test a clean install, airplane mode, interrupted purchase, and relaunch after purchase.
- [ ] Capture App Store screenshots on required iPhone display sizes.
- [ ] Capture a paywall screenshot for the IAP Review Information.

## App Store Connect privacy answers

Based on the current code and RevenueCat's published guidance:

- [ ] Tracking: **No**
- [ ] Data collected: **Purchases → Purchase History**
- [ ] Purchase History purposes: **App Functionality** and **Analytics**
- [ ] Linked to identity: **No** (the app uses RevenueCat's anonymous ID and has no account)
- [ ] Used for tracking: **No**
- [ ] Do not declare location, contacts, advertising data, health, user content, or diagnostics unless the code changes.

## Review submission

- [ ] Add the first non-consumable IAP to the same app-version submission.
- [ ] Paste `docs/app-review-notes.md` into App Review Notes.
- [ ] Upload the IAP review screenshot and localized name/description.
- [ ] Verify privacy policy and support links load without login.
- [ ] Confirm age rating answers: stylized/fantasy violence only; no gore, gambling, chat, ads, or user-generated content.
- [ ] Archive with Release configuration and validate the archive before upload.

## Product quality

- [ ] Confirm no placeholder RevenueCat warning appears in the release build.
- [ ] Confirm all three squad colors render and paid colors relock correctly when entitlement is absent.
- [ ] Confirm progress and upgrades survive relaunch.
- [ ] Confirm the fortress can be defeated without paid content.
- [ ] Review legal copy with qualified counsel if commercial risk warrants it.
