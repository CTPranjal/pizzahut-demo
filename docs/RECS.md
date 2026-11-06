# On-device recommendations

The iOS app ranks products on the device with `RecoEngine` (`ios/pizzahutmy/Reco/`). No product data is invented: every recommended item comes from the scraped catalog (`ios/assets-source/data/catalog.json`), and both data files below only reference IDs that exist in it. A load-time filter drops any unknown ID as a second safeguard.

## Data files

- `recs/pairings.json`: what pairs well with each pizza subcategory and each non-pizza category.
- `recs/popular.json`: the cold-start list, shown as "Popular right now".

Both are bundled into the app as resources (`project.yml`, `../recs`).

### How pairings were chosen

Pairings follow what Pizza Hut Malaysia itself bundles together on pizzahut.com.my, so the logic is the brand's, not ours:

- MyBox combos are sold as "1 main + 1 Side + 1 Drink" (MyBox Melts, MyBox Baked Rice, MyBox Wings), so every category gets at least one side and one drink.
- Half Price Deals and Hut's Celebration bundle Regular pizzas with Cream of Mushroom Soup, sides and drinks, so the Favourite and Supreme pizza lists include soup, Garlic Bread and Coke.
- MyBox Pasta lists a "Special Add On Chocolate Lava Cake", so Hut's Lava Chocolate Cake pairs with pasta and personal combos.
- Wingstreet Party For 2 includes fries and a 1.5L Coke, so Wingstreet pairs with Krispy Fries and Coke.
- The Rasa Malaysia campaign (homepage hero banner "Laksa Kari & Durian") runs Laksa Kari and Durian across pizza, melts and pasta, so Rasa Malaysia pizzas pair with Laksa Kari Melts, Durian Melts and Laksa Kari Pasta, plus the Lemongrass Chili dipper.
- Fun 5 pizzas are drizzled with nacho cheese (from their descriptions), so they pair with the Nacho Cheese dipper and kid-friendly sides.
- Hut's Signature Golden Shrimp pairs with Krispy Prawn; the signature range pairs with Hut's Signature Sauce.
- Drinks pair back to the most common sides (Garlic Bread, Krispy Fries, Cheesy Lava Bites) and dessert.

| Key | Paired products |
|---|---|
| Favourite Pizza | Garlic Bread, Cream Of Mushroom Soup, Hut's Cheesy Lava Triple Cheese Bites, Krispy Wings Original, Hut's Lava Chocolate Cake, Coke, Sprite |
| Fun 5 Pizza | Krispy Fries, Hut's Poppers Hash Bites, Hut's Dippers Nacho Cheese, Hut's Moist Chocolate Cake, Fanta Strawberry, Coke |
| Supreme Pizza | Garlic Bread, Cream Of Mushroom Soup, Krispy Wings Bbq, Hut's Poppers Cheezy, Hut's Lava Chocolate Cake, Coke, Coke Zero |
| Hut's Signature | Krispy Prawn, Hut's Cheesy Lava Chicken Pepperoni Bites, Garlic Bread, Hut's Signature Sauce, Hut's Lava Chocolate Cake, Coke |
| Rasa Malaysia Pizza | Laksa Kari Melts, Durian Melts, Laksa Kari Pasta, Hut's Dippers Lemongrass Chili, Peach Tea, Coke |
| limited-time-offers | Garlic Bread, Hut's Cheesy Lava Triple Cheese Bites, Hut's Lava Chocolate Cake, Coke |
| group-combos | Krispy Wings Original, Garlic Bread, Hut's Lava Chocolate Cake, Hut's Moist Chocolate Cake, Coke Zero |
| personal-combos | Hut's Lava Chocolate Cake, Hut's Cheesy Lava Triple Cheese Bites, Hut's Poppers Hash Bites, Peach Tea |
| pasta | Garlic Bread, Cream Of Mushroom Soup, Hut's Lava Chocolate Cake, Lemonade |
| rice | Cream Of Mushroom Soup, Krispy Fries, Hut's Moist Chocolate Cake, Fuze Lemon Tea |
| melts | Krispy Fries, Krispy Curly Fries, Hut's Dippers Nacho Cheese, Coke |
| huts-sliders | Krispy Fries, Hut's Poppers Hash Bites, Hut's Moist Chocolate Cake, Sprite |
| wingstreet | Krispy Fries, Garlic Bread, Hut's Dipper Ghost Pepper, Coke |
| sides | Hut's Dippers Nacho Cheese, Hut's Lava Chocolate Cake, Coke, Sprite |
| beverages | Garlic Bread, Krispy Fries, Hut's Cheesy Lava Triple Cheese Bites, Hut's Lava Chocolate Cake |

### How the popular list was chosen

There is no sales data in this demo. The 8 items are a curated mix of what pizzahut.com.my features most prominently, so "Popular right now" is a demo label for a curated list, not a measured trend:

| Product | Type | Why |
|---|---|---|
| MyBox Fanta Combo | Deal | First homepage hero banner and first "Our Highlights" tile |
| 2 Regular Pizzas For RM22 | Deal | "Our Highlights" tile (Tuesday app deal) |
| 2nd Pizza @ 6.90 | Deal | "Our Highlights" tile (Rasa Malaysia RM6.90) |
| Super Supreme | Pizza | Signature Supreme pizza, product page used for real size and crust prices |
| Chicken Pepperoni | Pizza | Favourite range classic, product page used for real prices |
| Laksa Kari Pizza | Pizza | Current Rasa Malaysia hero campaign |
| Garlic Bread | Side | Hut's Signature Sides |
| Hut's Cheesy Lava Triple Cheese Bites | Side | Homepage hero banner (Hut's Cheesy Lava) |

## Engine

- **Scores** per product, subcategory and category. Weights: Product Viewed +1, Product Customised +2, Added To Cart +3, Order Placed +5 per unit.
- **Decay**: every new session multiplies all scores by 0.9. A session starts at launch, or when the app returns after 30 minutes or more.
- **Personalised list** (Home and order confirmation): items related to the 3 most recently viewed products (same subcategory, or the same named range across categories, for example Rasa Malaysia), pairings for those products, then the top 3 subcategories and top 2 categories. Items backed by more than one signal get a small boost. Recently viewed items are not re-recommended as "related" and are down-weighted elsewhere.
- **Exclusions**: items in the cart and items ordered in the current session.
- **Reasons** come only from the user's own data: "Because you viewed <product>", "More from <subcategory>", "Goes great with <product>". Pinned and popular items show no reason.
- **Cold start**: with no scores, Home and confirmation show `popular.json` titled "Popular right now".
- **Persistence**: scores live in UserDefaults on the device. Logout and "Reset recommendations" clear them.
- **Persona warm start**: logging in as the demo profile preloads its history so Home differs immediately (see below).

| Surface | Slot (event value) | Content |
|---|---|---|
| Home, below `home_strip` | `home_picked_for_you` | Personalised list, titled by `PizzaHut.reco_row_title`. Re-ranks on every appearance with a short spring animation |
| Product detail | `product_goes_great_with` | Pairings for this product |
| Cart | `cart_complete_your_meal` | Pairings for cart items. Drinks lead when the cart has no drink, then sides when it has no side. One tap adds with default options (preferred size, Regular by default, first crust) |
| Order confirmation | `order_next_time_try` | Personalised list without the items just ordered |

## Warm-start histories

| History | Preloaded activity | Used by |
|---|---|---|
| Family feaster | Supreme and Hut's Signature pizzas (Super Supreme, Meat Mania, Hut's Signature Meat Mania and Golden Shrimp) customised in Large, plus Garlic Bread, Krispy Wings Bbq and Cheesy Lava Bites | Master demo profile (PH001) |
| Lunch regular | Personal Combos (MyBox Melts, MyBox Pizza, MyBox Of The Day) and Melts (Chicken Mania, Tom Yum Chicken, Burger Chicken) | Not attached: only one demo profile exists |
| Deal hunter | Deals and 2nd pizza offers (2nd Pizza @ 6.90, 2 Regular Pizzas For RM22, 2 Pizzas Half Price Deal, 2 Pizzas Deal Rasa Malaysia, MyBox Fanta Combo) | Not attached: only one demo profile exists |

Anonymous users start cold.

## Dashboard control (Product Experiences, group PizzaHut)

| Variable | Type | Default | Effect |
|---|---|---|---|
| `PizzaHut.reco_strategy` | String | `personalised` | `popular` shows popular.json in every row (titled "Popular right now"); `off` hides every row (the cart then falls back to the static upsell) |
| `PizzaHut.reco_pinned_ids` | String | empty | Comma separated product IDs, always first in every row; unknown IDs are ignored |
| `PizzaHut.reco_row_title` | String | `Picked for you` | Title of the Home row when the user has scores |

Variables are re-read whenever the SDK reports a change, and the rows re-render.

## Rehearsal tools

Long press the logo to open the hidden demo panel:

- **Reset recommendations** clears all scores (back to cold start).
- **Why this?** shows each card's score, signal type and reason in small text under the card.

## Verified on the simulator

`RecoFlowTests` (anonymous, no login) views Durian Brulee Pizza and Laksa Kari Pizza, returns to Home, and checks that the row changed from "Popular right now" to "Picked for you", that the first card changed, and that a "Because you viewed" label is shown (Durian Melts, Laksa Kari Melts, Laksa Kari Pasta: "Because you viewed Laksa Kari Pizza"). A second test checks the cart row leads with a drink, one-tap add works, and "Next time, try" shows on confirmation.
