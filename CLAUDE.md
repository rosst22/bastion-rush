# Bastion Rush — Project Conventions

## Stack

- Swift 6, SwiftUI, SpriteKit
- iOS 18+
- XcodeGen generates `BastionRush.xcodeproj` from `project.yml`
- RevenueCat wraps StoreKit; no Stripe checkout in the iOS app

## Commands

```sh
xcodegen generate
xcodebuild -project BastionRush.xcodeproj -scheme BastionRush -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

## Architecture

- `PlayerProgress`: local persistent progression using `UserDefaults`
- `BattleScene`: deterministic game loop, spawning, combat, gates, and fortress
- `GameView`: SwiftUI bridge and result persistence
- `PurchaseService`: RevenueCat offering, purchase, entitlement, and restore state

## Rules

- Keep runs fully playable without purchasing.
- Paid content is cosmetic unless the product metadata and paywall are both updated.
- Do not add ads, tracking, accounts, permissions, or analytics without updating the privacy policy, privacy manifest, App Store privacy answers, and review notes.
- Do not add Stripe for digital in-app content.
- Never commit secret keys. RevenueCat's public iOS SDK key belongs in `Config/Secrets.xcconfig`.
- Balance constants belong in `GameRules` or `BattleConfiguration`, not views.
