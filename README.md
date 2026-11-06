# Pizza Hut Malaysia demo (iOS) with CleverTap

A private sales demo for QSR Brands (Pizza Hut Malaysia): a SwiftUI iOS app that mirrors the real Pizza Hut Malaysia app and site, integrated with CleverTap. Not for public release. The website part of the original brief is out of scope.

## Layout

```
pizzahut-demo/
  ios/            project.yml (XcodeGen), Podfile, pizzahutmy/, notificationservice/, notificationcontent/,
                  pizzahutmyuitests/, assets-source/ (catalog.json and images), scripts/build_assets.py
  recs/           pairings.json, popular.json (on-device recommendations)
  docs/           EVENTS.md, DASHBOARD_TODO.md, RECS.md, ASSET_SOURCES.md, GAPS.md
```

## Run

```sh
cd ios
cp pizzahutmy/Secrets.example.plist pizzahutmy/Secrets.plist   # then fill in the passcode
python3 scripts/build_assets.py                                  # only after changing assets-source/
xcodegen generate
pod install
open pizzahutmy.xcworkspace                                      # always the workspace
```

Pick the `pizzahutmy` scheme and the iPhone 17 Pro simulator. For push on a real device, set `DEVELOPMENT_TEAM` in `project.yml` (placeholder today), regenerate, and follow `docs/DASHBOARD_TODO.md`.

Command-line build and tests:

```sh
xcodebuild -workspace pizzahutmy.xcworkspace -scheme pizzahutmy -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build
xcodebuild -workspace pizzahutmy.xcworkspace -scheme pizzahutmy -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build test \
  -only-testing:pizzahutmyuitests/RecoFlowTests
```

`DemoFlowTests/testPersonaFlow` logs in as the master demo profile (PH001) and places a real order against the Promo APIs. Run it only when you mean to.

## Configuration (single source of truth)

| Value | Where |
|---|---|
| CleverTap Account ID, Token | `ios/project.yml` (written to Info.plist as `CleverTapAccountID`, `CleverTapToken`). No region is set, so the SDK uses the default region |
| CleverTap IDFV | Disabled (`CleverTapDisableIDFV` = true) so profiles do not merge across installs |
| Passcode, Promo API base (`https://api.clevertap.com/1/promo`) | `ios/pizzahutmy/Secrets.plist` (git-ignored) |
| Wallet ID 1460, event prefix `PizzaHut`, phone code +63, earn rule | `ios/pizzahutmy/Config/DemoConfig.swift` |
| Product Experiences variables | `ios/pizzahutmy/CleverTap/ProductExperience.swift`, all under the `PizzaHut` group |

## Demo only

- **Promo APIs are called directly from the app** with the Account ID and Passcode headers (`X-CleverTap-Account-Id`, `X-CleverTap-Passcode`), as the per-API docs show. A passcode inside an app binary is not safe; a production app must call its own backend, which then calls CleverTap.
- Checkout is a mock. No payment is taken.
- Order tracking statuses are simulated (one step every 20 seconds).

## Demo script

1. Launch: splash, skippable onboarding, Home with the real banners and deals.
2. Browse anonymously: Order tab, Pizza, Laksa Kari Pizza and Durian Brulee Pizza. Back on Home, "Picked for you" re-ranks with "Because you viewed Laksa Kari Pizza".
3. Add a pizza: the iOS notification permission alert appears (first time only). Open the cart: "Complete your meal" leads with drinks; one tap adds a Coke.
4. Long press the logo: hidden demo panel with "Reset recommendations" and the "Why this?" toggle.
5. Profile tab, "Log in as Aisyah" (the only user: Identity `PH001`, Aisyah Rahman). No details to type. Then Home switches to a Supreme and Hut's Signature history. Rewards shows wallet 1460 points, history and coupons.
6. Apply a coupon in the cart (validated live), place the order, see "You earned X points" and "Next time, try".
7. Store Locator: branded location explainer, MapKit map of real outlets.

## Docs

- `docs/EVENTS.md`: every event, property, type and where it fires; profile keys; variables.
- `docs/RECS.md`: recommendation engine, data files and how each pairing was chosen.
- `docs/DASHBOARD_TODO.md`: what to set up on the CleverTap dashboard.
- `docs/ASSET_SOURCES.md`: source URL of every image and the store data.
- `docs/GAPS.md`: everything that could not be fetched or was approximated.
