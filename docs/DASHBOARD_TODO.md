# Dashboard to-do (CleverTap, account 489-7K5-676Z)

Everything the app needs that lives on the CleverTap dashboard. The website is out of scope, so web push, web pop-ups and the web inbox bell are not listed. Menu paths follow the linked CleverTap docs; check them against your dashboard version.

## 0. Before anything else

1. **Mark the demo device as a test profile** so the DEBUG build can sync variables. Find the profile by CleverTap ID (the simulator currently uses `-3ab8359cd1344145a5ace170e49d7b11`; it changes after a reinstall) or by Identity `PH001`, and mark it as a test profile ([guide](https://docs.clevertap.com/docs/user-profiles#mark-a-user-profile-as-a-test-profile)). Relaunch the app; the log should show "Variables synced successfully".
2. **Variables draft**: an earlier sync created ungrouped variables (`home_headline` and so on). Dismiss that draft, relaunch the app from the test profile, and publish the new draft, where every variable sits under the `PizzaHut` group.
3. **Archive other brands' coupons** on this shared account (`MYXL80GB`, `MYXL120GB`). The app hides coupons that are not applicable, but they still appear in the API response.

## 1. APNs auth key (push)

Per [iOS Push Notifications](https://developer.clevertap.com/docs/push-notifications-ios):

1. Apple Developer > Certificates, Identifiers & Profiles > Keys > +. Name it, tick Apple Push Notifications service (APNs), Continue, Register. Note the Key ID and download the `.p8` (only once; do not rename it).
2. CleverTap > Settings > Channels > Mobile Push > iOS. Authentication type: Provider authentication token (Auth key).
3. Upload the `.p8`, enter your Team ID, bundle ID `com.clevertap.demo.pizzahutmy`, and choose the APNs push mode. Use Development for debug builds run from Xcode.
4. Set the same Team ID in `ios/project.yml` (`DEVELOPMENT_TEAM`) and run on a real device; push does not reach the simulator.
5. For rich push, create campaigns with category `CTNotification` and Mutable Content on ([Rich Push](https://developer.clevertap.com/docs/rich-push-notifications)). Deep links: `pizzahutmy://product/<productId>`, `pizzahutmy://deals`, `pizzahutmy://rewards`, `pizzahutmy://cart`, `pizzahutmy://menu/<categoryId>`, `pizzahutmy://stores`, `pizzahutmy://inbox`.

## 2. In-app campaigns

1. Messages > Campaigns > + Campaign > In-App.
2. Suggested triggers: `PizzaHut Cart Viewed` with Cart Value under 60 ("Add RM X for free delivery"), `PizzaHut Product Viewed` with Category = Pizza (half interstitial promoting Garlic Bread).
3. Buttons can deep link (`pizzahutmy://...`) or send custom key-value `deeplink` = `pizzahutmy://...`; the app handles both.
4. The app shows no in-app of its own. Any in-app pop-up comes from a dashboard campaign (this account is shared, so check for live campaigns targeting all users).

## 3. Native Display (one campaign per slot)

Messages > Campaigns > + Campaign > Native Display. For each campaign add a custom key-value pair `slot` with one of these values:

| `slot` | Where | Suggested template |
|---|---|---|
| `home_hero` | Top banner on Home | Simple, image 900x500, action URL `pizzahutmy://product/my-box-fanta-combo-myboxfanta` |
| `home_strip` | Below the order mode toggle | Simple, short image or text strip |
| `menu_top` | Top of Menu | Simple, image banner |
| `cart_upsell` | Inside Cart | Simple, image plus title, action URL `pizzahutmy://product/garlic-bread-gab` |
| `rewards_banner` | Rewards | Simple, image plus title |

Without a campaign each slot shows its static brand fallback. The app records viewed and clicked for every unit.

## 4. App Inbox

1. Settings > Engage > App Inbox (or the App Inbox channel in campaign creation) and create inbox campaigns.
2. Use message tags `Offers` and `Orders` to fill the matching tabs. The first tab, All, shows everything (the SDK always adds it).
3. Suggested: an `Orders` message triggered by `PizzaHut Order Placed`, and an `Offers` carousel of deals.

## 5. Product Experiences variables

After step 0, variables appear under the `PizzaHut` group. Create campaigns that override defaults for segments, for example:

| Variable | Default | Demo idea |
|---|---|---|
| PizzaHut.home_headline | Feed Good Times | Gold tier: "Welcome back, Gold member" |
| PizzaHut.home_subheadline | Hot pizza, delivered or ready for takeaway. | Takeaway users: "Ready when you are at your Hut" |
| PizzaHut.featured_deal_id | my-box-fanta-combo-myboxfanta | Deal seekers: `2-regular-pizzas-for-rm-22-appdeal3` |
| PizzaHut.primary_cta_text | Order Now | "Grab the deal" |
| PizzaHut.free_delivery_threshold | 60 | 40 for Gold tier |
| PizzaHut.show_rewards_tab | true | false for an A/B test |
| PizzaHut.menu_category_order | limited-time-offers,group-combos,... | Put `pizza` first for users with Favourite Category = Pizza |
| PizzaHut.reco_strategy | personalised | `popular` or `off` as a control group |
| PizzaHut.reco_pinned_ids | (empty) | `laksa-kari-pizza-lt9` to pin the campaign hero |
| PizzaHut.reco_row_title | Picked for you | "Your next favourite" |

## 6. Geofences

1. Settings > Geofences (see [Geofence iOS](https://developer.clevertap.com/docs/geofence-ios)). Add circular fences around the outlets in `docs/ASSET_SOURCES.md` (Stores section), for example Pizza Hut Jalan Bangsar (3.128890, 101.679842) with a 500 m radius.
2. Create a push campaign triggered by Geofence Entered for those fences.
3. Users must allow location (Always) from the Store Locator explainer.

## 7. Wallet 1460 earn and burn rules

The app identifies the wallet only by `walletId == 1460` and credits points itself after each order (1 point per RM 1 paid, via the Debit/Credit Wallet API, sale channel `iOS App`). On the dashboard:

1. Promo > Wallets > wallet 1460: confirm the points name and the expiry duration.
2. Optional earn rules: bonus points on `PizzaHut Signup Completed`, or double points for Gold tier.
3. Optional burn rule: allow redeeming points against coupons.

## 8. Coupons

Codes on the account that work today for this brand: `FLAT10` (RM 10 off the entire order, one use per user), `WELCOME20` (20% off), `ADI` (RM 56 off). Suggested additions:

1. Promo > Coupons > Create. Make a Single Code "All Users" coupon such as `TUESDAY22` (entire cart, absolute) and tick code visibility so it appears in the Rewards coupon tray.
2. A rule-based coupon for users with `PizzaHut Loyalty Tier` = Gold.
3. Leave per-user limits at 1 for one-time offers; the app shows "You have already used this coupon" when it is exhausted.

## 9. Segments

There is one master demo profile (Identity `PH001`, Family feaster history). Useful segments built on the prefixed properties:

| Segment | Definition |
|---|---|
| Family feasters | `PizzaHut Preferred Order Mode` = Delivery AND `PizzaHut Favourite Category` = Pizza AND `PizzaHut Loyalty Tier` = Gold |
| Lunch regulars | `PizzaHut Preferred Order Mode` = Takeaway AND did `PizzaHut Order Placed` on weekdays between 11:00 and 15:00 |
| Deal hunters | `PizzaHut Last Coupon Used` is set OR did `PizzaHut Coupon Applied` at least 2 times |
| Recommendation engaged | did `PizzaHut Recommendation Clicked` in the last 7 days |
| Rasa Malaysia fans | `PizzaHut Top Affinity` = Rasa Malaysia Pizza |
