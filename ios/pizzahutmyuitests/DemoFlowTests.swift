import XCTest

/// Walks the demo flows on the simulator. Screenshots go to $SCREENSHOT_DIR when set
/// (pass TEST_RUNNER_SCREENSHOT_DIR=/some/path to xcodebuild).
final class DemoFlowTests: XCTestCase {
    private var app: XCUIApplication!
    private let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()
    }

    // MARK: Anonymous: browse, customise, add to cart, push permission, checkout, track

    func testAnonymousFlow() {
        skipOnboarding()
        XCTAssertTrue(app.staticTexts["Our"].firstMatch.waitForExistence(timeout: 10) || app.buttons["Order"].exists)
        snap("01-home")

        app.buttons["Order"].tap()
        tapChip("Pizza")
        snap("02-menu-pizza")
        tapStarting("Super Supreme")
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Add to Cart'")).firstMatch.waitForExistence(timeout: 5))
        tapStarting("Large")
        tapStarting("Stuffed Crust")
        tapContaining("Mushrooms")
        snap("03-product-detail")
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Add to Cart'")).firstMatch.tap()

        // iOS notification permission alert after the first add to cart.
        let sysAllow = springboard.buttons["Allow"]
        if sysAllow.waitForExistence(timeout: 8) {
            snap("04-push-permission")
            sysAllow.tap()
        }

        tapContaining("View Cart")
        XCTAssertTrue(app.navigationBars["My Cart"].waitForExistence(timeout: 5))
        snap("05-cart")
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Checkout'")).firstMatch.tap()

        let address = app.textFields["House number, street, area, postcode"]
        XCTAssertTrue(address.waitForExistence(timeout: 5))
        address.tap()
        address.typeText("23, Jalan Bangsar, 59000 Kuala Lumpur")
        app.navigationBars["Checkout"].tap()
        snap("06-checkout")
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Place Order'")).firstMatch.tap()

        XCTAssertTrue(app.staticTexts["Order placed!"].waitForExistence(timeout: 20))
        snap("07-confirmation-anon")
        app.buttons["Track my order"].tap()
        XCTAssertTrue(app.staticTexts["Order Received"].firstMatch.waitForExistence(timeout: 5))
        snap("08-tracking")
    }

    // MARK: Logged in: persona, rewards, coupon, order, points, store locator

    func testPersonaFlow() {
        skipOnboarding()
        let logo = app.images["Pizza Hut"].firstMatch
        XCTAssertTrue(logo.waitForExistence(timeout: 10))
        logo.press(forDuration: 1.3)
        XCTAssertTrue(app.navigationBars["Demo profile"].waitForExistence(timeout: 5))
        snap("10-personas")
        tapContaining("Master demo profile")
        sleep(4) // let onUserLogin create the profile before calling the Promo APIs
        snap("11-home-persona")

        app.buttons["Rewards"].tap()
        XCTAssertTrue(app.staticTexts["My Rewards"].waitForExistence(timeout: 5))
        _ = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Points'")).firstMatch.waitForExistence(timeout: 15)
        sleep(2)
        snap("12-rewards")

        app.buttons["Order"].tap()
        tapChip("Pizza")
        tapStarting("Chicken Pepperoni")
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Add to Cart'")).firstMatch.tap()
        dismissPushAlert(app)

        tapContaining("View Cart")
        XCTAssertTrue(app.navigationBars["My Cart"].waitForExistence(timeout: 5))
        let code = app.textFields["Enter coupon code"]
        XCTAssertTrue(code.waitForExistence(timeout: 5))
        code.tap()
        code.typeText("FLAT10")
        app.buttons["Apply"].tap()
        let applied = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'applied' OR label CONTAINS 'coupon' OR label CONTAINS 'Coupon'")).firstMatch
        _ = applied.waitForExistence(timeout: 15)
        sleep(1)
        snap("13-cart-coupon")

        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Checkout'")).firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Checkout"].waitForExistence(timeout: 5))
        snap("14-checkout-persona")
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Place Order'")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Order placed!"].waitForExistence(timeout: 30))
        sleep(1)
        snap("15-confirmation-points")
        app.buttons["Back to home"].tap()

        app.buttons["Rewards"].tap()
        sleep(6)
        snap("16-rewards-after-order")

        app.buttons["Profile"].tap()
        snap("17-profile")
        tapContaining("Find a Hut")
        if app.buttons["Allow location"].waitForExistence(timeout: 5) {
            snap("18-location-explainer")
            app.buttons["Allow location"].tap()
            for label in ["Allow While Using App", "Allow Once", "Allow"] {
                let b = springboard.buttons[label]
                if b.waitForExistence(timeout: 3) { b.tap(); break }
            }
        }
        sleep(3)
        let firstStore = app.cells.buttons.firstMatch
        XCTAssertTrue(firstStore.waitForExistence(timeout: 5))
        firstStore.tap()
        sleep(1)
        snap("19-store-locator")
    }

    // MARK: Helpers

    private func skipOnboarding() {
        let skip = app.buttons["Skip"]
        if skip.waitForExistence(timeout: 6) { skip.tap() }
    }

    private func tapChip(_ name: String) {
        let chip = app.scrollViews.buttons[name].firstMatch
        XCTAssertTrue(chip.waitForExistence(timeout: 5), "chip \(name)")
        let bar = app.scrollViews.containing(.button, identifier: name).firstMatch
        var tries = 0
        while chip.frame.maxX > app.windows.firstMatch.frame.maxX - 8 && tries < 6 {
            bar.swipeLeft(velocity: .slow); tries += 1
        }
        chip.tap()
    }

    private func tapContaining(_ text: String, file: StaticString = #filePath, line: UInt = #line) {
        let el = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
        XCTAssertTrue(el.waitForExistence(timeout: 8), "button containing \(text)", file: file, line: line)
        if !el.isHittable { app.swipeUp(velocity: .slow) }
        el.tap()
    }

    private func tapStarting(_ text: String, file: StaticString = #filePath, line: UInt = #line) {
        let el = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", text)).firstMatch
        XCTAssertTrue(el.waitForExistence(timeout: 8), "button starting \(text)", file: file, line: line)
        var tries = 0
        while !el.isHittable && tries < 4 { app.swipeUp(velocity: .slow); tries += 1 }
        el.tap()
    }

    private func snap(_ name: String) {
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? shot.pngRepresentation.write(to: URL(fileURLWithPath: dir).appendingPathComponent(name + ".png"))
        }
    }
}

/// Recommendation check: view two Rasa Malaysia pizzas, return to Home, and the
/// "Picked for you" row re-ranks with a "Because you viewed" reason. Anonymous, no login.
final class RecoFlowTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()
    }

    func testRasaViewsReorderPickedForYou() {
        let skip = app.buttons["Skip"]
        if skip.waitForExistence(timeout: 6) { skip.tap() }

        // Cold start: the Home row shows the curated popular list.
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Popular right now'")).firstMatch.waitForExistence(timeout: 10))
        app.swipeUp(velocity: .slow)
        snap("20-home-cold-start")
        let firstBefore = firstRecoCardId()

        app.buttons["Order"].tap()
        let chip = app.scrollViews.buttons["Pizza"].firstMatch
        XCTAssertTrue(chip.waitForExistence(timeout: 5))
        var tries = 0
        while chip.frame.maxX > app.windows.firstMatch.frame.maxX - 8 && tries < 6 {
            app.scrollViews.containing(.button, identifier: "Pizza").firstMatch.swipeLeft(velocity: .slow); tries += 1
        }
        chip.tap()

        for name in ["Durian Brulee Pizza", "Laksa Kari Pizza"] {
            let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", name)).firstMatch
            XCTAssertTrue(row.waitForExistence(timeout: 8), name)
            row.tap()
            XCTAssertTrue(app.buttons["Close"].waitForExistence(timeout: 6))
            snap(name == "Laksa Kari Pizza" ? "21-detail-goes-great-with" : "21a-detail-durian")
            app.buttons["Close"].firstMatch.tap()
            sleep(1)
        }

        app.buttons["Home"].tap()
        let reason = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Because you viewed'")).firstMatch
        app.swipeUp(velocity: .slow)
        XCTAssertTrue(reason.waitForExistence(timeout: 6), "Because you viewed label")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Picked for you'")).firstMatch.exists, "Picked for you title")
        sleep(1)
        let firstAfter = firstRecoCardId()
        XCTAssertNotEqual(firstBefore, firstAfter, "row reordered")
        snap("22-home-picked-for-you")
    }

    func testCartAndConfirmationRows() {
        let skip = app.buttons["Skip"]
        if skip.waitForExistence(timeout: 6) { skip.tap() }
        app.buttons["Order"].tap()
        let chip = app.scrollViews.buttons["Pizza"].firstMatch
        XCTAssertTrue(chip.waitForExistence(timeout: 5))
        var tries = 0
        while chip.frame.maxX > app.windows.firstMatch.frame.maxX - 8 && tries < 6 {
            app.scrollViews.containing(.button, identifier: "Pizza").firstMatch.swipeLeft(velocity: .slow); tries += 1
        }
        chip.tap()
        let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Super Supreme'")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 8))
        row.tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Add to Cart'")).firstMatch.tap()
        dismissPushAlert(app)

        app.buttons.matching(NSPredicate(format: "label CONTAINS 'View Cart'")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Complete your meal'")).firstMatch.waitForExistence(timeout: 6))
        // No drink in the cart, so a drink leads the row.
        let firstCard = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'reco-'")).firstMatch
        XCTAssertTrue(firstCard.waitForExistence(timeout: 5))
        XCTAssertTrue(["reco-coke", "reco-sprite", "reco-fanta", "reco-lemonade", "reco-peach", "reco-red-bull", "reco-fuze"].contains { firstCard.identifier.hasPrefix($0) },
                      "first card should be a drink, got \(firstCard.identifier)")
        snap("23-cart-complete-your-meal")
        firstCard.tap()
        sleep(1)
        snap("24-cart-after-one-tap-add")

        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Checkout'")).firstMatch.tap()
        let address = app.textFields["House number, street, area, postcode"]
        XCTAssertTrue(address.waitForExistence(timeout: 5))
        address.tap()
        address.typeText("23, Jalan Bangsar, 59000 Kuala Lumpur")
        app.navigationBars["Checkout"].tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Place Order'")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Order placed!"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Next time, try'")).firstMatch.waitForExistence(timeout: 5))
        snap("25-confirmation-next-time-try")
    }

    private func firstRecoCardId() -> String {
        let cards = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'reco-'"))
        return cards.firstMatch.exists ? cards.firstMatch.identifier : ""
    }

    private func snap(_ name: String) {
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? shot.pngRepresentation.write(to: URL(fileURLWithPath: dir).appendingPathComponent(name + ".png"))
        }
    }
}

/// Opens the Profile tab while logged out and checks the single-user login option. Does not log in.
final class LoginScreenTests: XCTestCase {
    func testSingleUserLoginOption() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()
        let skip = app.buttons["Skip"]
        if skip.waitForExistence(timeout: 6) { skip.tap() }
        app.buttons["Profile"].tap()
        XCTAssertTrue(app.buttons["Log in as Aisyah"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.textFields.firstMatch.exists, "no form fields")
        let shot = XCUIScreen.main.screenshot()
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? shot.pngRepresentation.write(to: URL(fileURLWithPath: dir).appendingPathComponent("30-login.png"))
        }
    }
}

/// Dismisses the iOS notification permission alert if it is showing.
func dismissPushAlert(_ app: XCUIApplication) {
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    let dontAllow = springboard.buttons["Don\u{2019}t Allow"]
    let dontAllowAscii = springboard.buttons["Don't Allow"]
    if dontAllow.waitForExistence(timeout: 6) { dontAllow.tap() } else if dontAllowAscii.exists { dontAllowAscii.tap() }
}
