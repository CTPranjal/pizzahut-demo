# Event tracking plan (iOS)

The website is out of scope, so this plan covers the iOS app only.

## Rules

- Every custom event name is `EVENT_PREFIX` + a space + the name. The prefix is `DemoConfig.eventPrefix` (`PizzaHut`) and names are built by `AppEvent.name` in `ios/pizzahutmy/CleverTap/Analytics.swift`. No full event name is typed anywhere else.
- Event property keys are unprefixed.
- Every event carries `Platform` (`"iOS"`) and `Currency` (`"MYR"`), added by `Analytics.track`.
- Prices and amounts are numbers in MYR.
- System events (App Launched, Notification Viewed, Notification Clicked and so on) are recorded by the CleverTap SDK and are not listed here.

## Events

| Event | Properties (type) | Where fired |
|---|---|---|
| PizzaHut Home Viewed | Order Mode (String), Store Name (String) | Home appears |
| PizzaHut Order Mode Selected | Mode (String: Delivery / Takeaway), Store Name (String) | Delivery / Takeaway toggle on Home and Checkout |
| PizzaHut Store Selected | Store ID (String), Store Name (String), Source (String: Home Header, Checkout, Account, Deep Link) | Store Locator row tap |
| PizzaHut Store Locator Viewed | Stores Shown (Number) | Store Locator appears |
| PizzaHut Category Viewed | Category (String) | Menu category chip selected, or a category opened from Home or a deep link |
| PizzaHut Search Performed | Query (String), Results Count (Number) | Menu search submitted |
| PizzaHut Deal Viewed | Deal ID (String), Deal Name (String), Price (Number) | Deal tile or featured deal tapped |
| PizzaHut Product Viewed | Product ID (String), Product Name (String), Category (String), Price (Number), Image URL (String), Source (String: Recommendation / Browse), Slot (String, only when Source is Recommendation) | Product detail appears |
| PizzaHut Product Customised | Product ID (String), Size (String), Crust (String), Toppings (String, comma separated or "None") | Pizza added to cart from product detail |
| PizzaHut Added To Cart | Product ID (String), Product Name (String), Category (String), Price (Number), Quantity (Number), Cart Value (Number), Source (String: Recommendation / Browse), Slot (String, only when Source is Recommendation) | Add to Cart on product detail, one-tap add in the cart row, cart quantity +, static cart upsell |
| PizzaHut Removed From Cart | Product ID (String), Quantity (Number), Cart Value (Number) | Cart quantity reduced or removed |
| PizzaHut Cart Viewed | Item Count (Number), Cart Value (Number) | Cart opens |
| PizzaHut Checkout Started | Item Count (Number), Cart Value (Number), Order Mode (String) | Checkout appears |
| PizzaHut Coupon Applied | Coupon Code (String), Discount (Number), Result (String: Applied / Not Applicable / Failed) | Cart coupon validated with the Validate Coupon API |
| PizzaHut Order Placed | Order ID (String), Amount (Number), Discount (Number), Payment Method (String), Order Mode (String), Item Count (Number), Points Earned (Number), Items (array of objects, see below) | Place Order succeeds |
| PizzaHut Order Tracked | Order ID (String), Status (String) | Tracking screen appears and each time the mock status advances |
| PizzaHut Rewards Viewed | Active Points (Number) | Rewards loads for a logged-in user |
| PizzaHut Login | Method (String: Demo Persona) | "Log in as Aisyah" on the login screen, or the hidden demo panel |
| PizzaHut Logout | none beyond Platform and Currency | Log out |
| PizzaHut Push Permission Response | Granted (Boolean) | iOS notification permission alert (after first add to cart) answered |
| PizzaHut Location Permission Response | Granted (Boolean) | System location prompt answered from the Store Locator explainer |
| PizzaHut Recommendation Viewed | Slot (String), Strategy (String: personalised / popular), Product IDs (String, comma separated, in display order), Count (Number) | Once per recommendation row per screen appearance, only when the row has items |
| PizzaHut Recommendation Clicked | Slot (String), Strategy (String), Product ID (String), Position (Number, 1-based), Reason (String: the card's reason, or Pinned / Popular) | Card tapped in any recommendation row |

PizzaHut Signup Completed is not fired: the app has a single demo user and no sign-up form.

PizzaHut Store Proximity Entered was specified for the web simulation only and is not fired on iOS. Geofence entry on iOS is recorded by the CleverTap Geofence SDK as its own system event.

### Order Placed Items

`Items` is an array of nested objects (supported from CleverTap iOS SDK 7.5.0; the app uses 7.8.2):

| Key | Type | Notes |
|---|---|---|
| Product ID | String | |
| Product Name | String | |
| Category | String | |
| Quantity | Number | |
| Unit Price | Number | Includes size, crust and topping add-ons |
| Size | String | Empty for non-pizza items |
| Crust | String | Empty for non-pizza items |
| Source | String | Recommendation / Browse, carried from the moment the line was added |
| Slot | String | Only when Source is Recommendation |

### Recommendation slots

| Slot value | Surface |
|---|---|
| `home_picked_for_you` | Home, "Picked for you" (or "Popular right now" on cold start) |
| `product_goes_great_with` | Product detail, "Goes great with" |
| `cart_complete_your_meal` | Cart, "Complete your meal" |
| `order_next_time_try` | Order confirmation, "Next time, try" |

## User profile

Standard CleverTap keys stay unprefixed and are sent with `onUserLogin`: `Identity`, `Name`, `Email`, `Phone`, `MSG-push`, `MSG-email`, `MSG-sms`, `MSG-whatsapp`. Identity is separate from Phone. There is one user, the master demo profile: Identity `PH001`, Phone `+639178420101`.

Custom keys are built from the prefix by `ProfileKey.key`:

| Key | Type | Set when |
|---|---|---|
| PizzaHut Preferred Order Mode | String | Login, order mode switch |
| PizzaHut Preferred Store | String | Login, store selected |
| PizzaHut Favourite Category | String | Login (demo profile), most viewed category changes |
| PizzaHut Loyalty Tier | String: Bronze / Silver / Gold | Login, after each order (5+ orders Silver, 15+ Gold) |
| PizzaHut Total Orders | Number | Login, after each order |
| PizzaHut Last Order Value | Number | After each order |
| PizzaHut Preferred Payment | String | After each order |
| PizzaHut Signup Platform | String: iOS | Demo profile login |
| PizzaHut Last Coupon Used | String | After an order with a coupon |
| PizzaHut App Language | String: English | Login |
| PizzaHut Top Affinity | String (subcategory name) | After a recommendation scoring change, only when the top subcategory changes |

Behavioural properties are pushed with `profilePush`, followed by `fetchVariables` so Product Experiences segments re-evaluate.

## Product Experiences variables

All variables are nested under the `PizzaHut` group (`PizzaHut.<name>`):

| Variable | Type | Default |
|---|---|---|
| PizzaHut.home_headline | String | Feed Good Times |
| PizzaHut.home_subheadline | String | Hot pizza, delivered or ready for takeaway. |
| PizzaHut.featured_deal_id | String | my-box-fanta-combo-myboxfanta |
| PizzaHut.primary_cta_text | String | Order Now |
| PizzaHut.free_delivery_threshold | Number (RM) | 60 |
| PizzaHut.show_rewards_tab | Boolean | true |
| PizzaHut.menu_category_order | String (comma separated category IDs) | limited-time-offers,group-combos,personal-combos,pizza,pasta,rice,melts,huts-sliders,wingstreet,sides,beverages |
| PizzaHut.reco_strategy | String: personalised / popular / off | personalised |
| PizzaHut.reco_pinned_ids | String (comma separated product IDs) | empty |
| PizzaHut.reco_row_title | String | Picked for you |
