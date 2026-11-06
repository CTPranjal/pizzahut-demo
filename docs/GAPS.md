# Gaps

Anything that could not be fetched, or had to be approximated, is listed here. Nothing below was invented: where data was missing, a neutral placeholder or an explicit rule was used instead.

## Phase 0: brand and content

### Brand
- Heading typeface on pizzahut.com.my is **RLAqua**, a proprietary font that is not publicly licensed. Web uses **Rubik** (Google Fonts) for headings as the closest match; body text uses **Open Sans**, which is what the real site uses. iOS uses the system font (SF Pro) for both, since Open Sans and Rubik are only available as variable fonts or WOFF2 and the system font is the documented fallback.
- Subcategory names were normalised from the site's upper-case data (for example "HUT'S POPPER" to "Hut's Poppers", "MERDEKA LTO" to "Merdeka LTO"). The site's placeholder subcategory "SUB CATEGORY" for the Cheesy Lava deals was renamed to "Hut's Cheesy Lava Deals", the label the site's own navigation uses for that collection.
- The real site has no "Desserts" menu category. Lava and chocolate cakes live under Sides (subcategory Hut Lava), so the demo keeps that structure.
- The real app calls the second order mode **Pickup**. The brief asks for **Takeaway**, so the demo uses Takeaway everywhere (brief wins for naming).
- The real loyalty programme counts "Slices" (1 slice per RM 30). The brief asks for points (1 point per RM 1, configurable), labelled "My Rewards". The demo follows the brief.
- The real site loads its store list client-side behind an app token, so outlet data could not be read from pizzahut.com.my. Real outlet names and coordinates were taken from OpenStreetMap instead (18 Klang Valley outlets with a branch or street tag). Store opening hours and phone numbers were not available and are not shown.
- The "Free Cheesy Bites" crust (code SSC) appears in the site data only as a promotional variant, so it is left out of the crust picker.

### Pizza pricing rule
- Size, crust and topping prices were read from five real pizza product pages. Each pizza is assigned a tier from its subcategory: Favourite and Fun 5 pizzas use the Chicken Pepperoni deltas (Regular +RM 21.40, Large +RM 33.40); Supreme and Hut's Signature pizzas use the Super Supreme deltas (Regular +RM 22.40, Large +RM 35.40); Rasa Malaysia pizzas use the Laksa Kari deltas (Regular +RM 24.40, no Large). Individual pizzas may differ slightly on the live site.
- Topping lists differ per pizza on the live site (each pizza only offers its own ingredients as extras). The demo offers one shared extra-topping list per size, with real per-size prices.

### Products excluded
- Excluded "Huts Poppers Crispy Chicken" (Sides): site lists RM 1, which looks like an add-on or combo-only price, not a standalone price
- Excluded "Hut's Breadstix Cinnamon" (Sides): site lists RM 0, which looks like an add-on or combo-only price, not a standalone price
- Excluded "Hut's Breadstix Cheddar" (Sides): site lists RM 0, which looks like an add-on or combo-only price, not a standalone price
- Excluded "Krispy Wedges" (Sides): site lists RM 0, which looks like an add-on or combo-only price, not a standalone price
- Excluded "Krispy Onion Rings" (Sides): site lists RM 1, which looks like an add-on or combo-only price, not a standalone price

### Duplicate listings collapsed (same name in the same category)
- Duplicate listing skipped in Personal Combos: "Hut's Sliders Combo" (slug huts-sliders-combo-phxhslider2, RM 16.99)
- Duplicate listing skipped in Personal Combos: "Myfun Box Pizza" (slug myfun-box-pizza-phxmyfunpz, RM 12.99)
- Duplicate listing skipped in Personal Combos: "Myfun Box Melts" (slug myfun-box-melts-phxmyfunml, RM 12.99)
- Duplicate listing skipped in Personal Combos: "Myfun Box Pasta" (slug myfun-box-pasta-phxmyfunps, RM 15.99)
- Duplicate listing skipped in Personal Combos: "Mybox Baked Rice" (slug mybox-baked-rice-phxmybrice1, RM 16.99)
- Duplicate listing skipped in Personal Combos: "Mybox Melts Burger" (slug mybox-melts-burger-phxmybmeltsbg, RM 19.99)
- Duplicate listing skipped in Beverages: "Coke" (slug coke-canbvta1, RM 5.59)
- Duplicate listing skipped in Beverages: "Sprite" (slug sprite-canbvta3, RM 5.59)

### Products with no description on the site (shown without one)
- No description on site for "MyBox Fanta Combo" (my-box-fanta-combo-myboxfanta)
- No description on site for "2 X MyHeart Box With Free V Sticker" (2-x-my-heart-box-with-free-v-sticker-phrt24d)
- No description on site for "2nd Pizza @ 6.90" (2nd-pizza-6-90-ltomerdeka5)
- No description on site for "Mybox Rasa Malaysia" (mybox-rasa-malaysia-ltomerdeka1)
- No description on site for "Webox 2 Rasa Malaysia" (webox-2-rasa-malaysia-ltomerdeka2)
- No description on site for "Webox 4 Rasa Malaysia" (webox-4-rasa-malaysia-ltomerdeka3)
- No description on site for "Webox 6 Rasa Malaysia" (webox-6-rasa-malaysia-ltomerdeka4)
- No description on site for "App Special Mybox Rasa Malaysia" (app-special-mybox-rasa-malaysia-rasamysia1)
- No description on site for "App Special Webox 4 Rasa Malaysia" (app-special-webox-4-rasa-malaysia-rasamysia2)
- No description on site for "Mybox Bichi Mao Combo" (mybox-bichi-mao-combo-bichimybsleeve)
- No description on site for "2 Mybox Free Sticker" (2-mybox-free-sticker-bichimyb)
- No description on site for "Hut's Sliders Bichi Mao Combo" (huts-sliders-bichi-mao-combo-bichislidsleeve)
- No description on site for "2 Hut's Sliders Free Sticker" (2-huts-sliders-free-sticker-bichislid)
- No description on site for "The Looooooooong Party Box Free Coke" (the-looooooooong-party-box-free-coke-pzlong6)
- No description on site for "2 Pizzas Deal Rasa Malaysia" (2-pizzas-deal-rasa-malaysia-ltomerdeka6)
- No description on site for "2 Large Pizza Deal" (2-large-pizza-deal-dbox7)
- No description on site for "FUN 5 PERSONAL 5" (fun-5-personal-5-fun5f2)
- No description on site for "Durian Brulee Pizza" (durian-brulee-pizza-lt10)
- No description on site for "Laksa Kari Pizza" (laksa-kari-pizza-lt9)
- No description on site for "Laksa Kari Pasta" (laksa-kari-pasta-paslaksa)
- No description on site for "Durian Melts" (durian-melts-m26)
- No description on site for "Laksa Kari Melts" (laksa-kari-melts-m25)
- No description on site for "Huts Cheezy Lava Deal 3" (huts-cheezy-lava-deal-3-hclav2)
- No description on site for "Huts Cheezy Lava Deal 2" (huts-cheezy-lava-deal-2-hclav1)
- No description on site for "Hut's Cheesy Lava Chicken Pepperoni Bites" (huts-cheesy-lava-chicken-pepperoni-bites-clav3)
- No description on site for "Hut's Cheesy Lava Triple Cheese Bites" (huts-cheesy-lava-triple-cheese-bites-clav1)
- No description on site for "Hut's Cheesy Lava Creamy Mushroom Chicken Bites" (huts-cheesy-lava-creamy-mushroom-chicken-bites-clav2)
- No description on site for "Dip & Crunch Classic" (dip-crunch-classic-dipcrunch1)
- No description on site for "Coke" (coke-regbvta1)
- No description on site for "Fanta Strawberry" (fanta-strawberry-regbvta4)
- No description on site for "Lemonade" (lemonade-regbv6)
- No description on site for "Peach Tea" (peach-tea-regbv5)
- No description on site for "Sprite" (sprite-regbvta3)
- No description on site for "Coke Zero" (coke-zero-canbvta2)
- No description on site for "Red Bull" (red-bull-redbull)
- No description on site for "Fuze Lemon Tea" (fuze-lemon-tea-canbvta5)

## Scope and integration decisions

- **Website**: dropped at the client's request. No web pages, web SDK, web push, web inbox or Express proxy were built. PizzaHut Store Proximity Entered (a web-only simulation) is therefore not fired.
- **Promo API auth**: the overview page says Basic Auth (API Key and Secret Key); every per-API page and the common headers page use `X-CleverTap-Account-Id` and `X-CleverTap-Passcode`. Headers were chosen with the client and verified against the live API.
- **Push permission timing**: the push doc requests permission in `didFinishLaunching`. The app instead asks after the first add to cart. The brief asked for a branded soft prompt first; the CleverTap push primer was tried and removed at the client's request, so the iOS system alert shows directly.
- **Background modes**: the geofence doc lists `location`, `remote-notification`, `fetch` and `processing`; all four are set (doc wins for SDK mechanics). `BGTaskSchedulerPermittedIdentifiers` is declared because `processing` requires it.
- **Push impressions**: the service extension uses `CTNotificationServiceExtension` as its principal class (default keys approach, as briefed). That approach does not call `recordNotificationViewedEvent`, so push impressions from the extension are not raised. Enabling them needs the CleverTap SDK in the extension and an App Group to share the identity.
- **App Inbox tabs**: the CleverTap inbox always shows a first "All" tab, so the tabs are All, Offers and Orders.
- **Login**: the brief asked for a Name / Email / Phone form with +63 validation and a sign-up flow. At the client's request the app has a single user, so the login screen offers one option, "Log in as Aisyah", and PizzaHut Signup Completed is not fired.
- **Demo profiles**: the brief asked for three personas; the client asked for a single master profile (Identity `PH001`, separate from Phone `+639178420101`). It uses the Family feaster properties and recommendation history. The Lunch regular and Deal hunter histories are defined in `RecoEngine.WarmStart` but not attached to a login.
- **Delivery fee**: RM 5.00 below the free delivery threshold is a demo assumption; the real fee could not be read without a delivery address.
- **Payment methods**: the checkout options are generic mock labels; the real payment providers were not visible without placing an order.
- **Shared CleverTap account**: the coupon API also returns other brands' coupons (`MYXL80GB`, `MYXL120GB`). The app lists only applicable coupons.

## Recommendations

- No sales or popularity data exists in this demo. "Popular right now" labels a curated list (see docs/RECS.md), as specified in the brief.
- Pairings come from how the real site bundles products (MyBox, Half Price Deals, Wingstreet parties, the Rasa Malaysia campaign), not from basket data.
