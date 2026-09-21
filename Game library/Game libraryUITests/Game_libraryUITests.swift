import XCTest

final class Game_libraryUITests: XCTestCase {
    @MainActor func testFourTabsManualAddAndSameNameConfirmation() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        for label in ["Tüm Oyunlar", "Kütüphanem", "Wishlist", "Oynanacak"] {
            XCTAssertTrue(app.descendants(matching: .any)[label].firstMatch.exists, "Missing tab: \(label) \(app.debugDescription)")
        }
        app.buttons["Oyun Ekle"].click()
        let title = app.textFields["manualTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.click()
        title.typeText("Portal UI")
        app.buttons["Elle Ekle"].click()
        XCTAssertTrue(app.staticTexts["Portal UI"].firstMatch.waitForExistence(timeout: 5))
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Phase 2 manual game detail"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.buttons["Kapat"].click()
        app.buttons["Oyun Ekle"].click()
        title.click()
        title.typeText("Portal UI")
        app.buttons["Elle Ekle"].click()
        let existing = app.buttons["Mevcut kaydı aç: Portal UI"]
        XCTAssertTrue(existing.waitForExistence(timeout: 5))
        existing.click()
        XCTAssertTrue(app.buttons["Kapat"].waitForExistence(timeout: 5))
    }

    @MainActor func testCatalogSelectionRequiresConfirmation() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-catalog"]
        app.launch()
        app.buttons["Oyun Ekle"].click()
        let query = app.textFields["searchTitle"]
        XCTAssertTrue(query.waitForExistence(timeout: 5), app.debugDescription)
        query.click()
        query.typeText("Katalog")
        app.buttons["Ara"].click()
        XCTAssertTrue(app.buttons["Seç"].firstMatch.waitForExistence(timeout: 5))
        app.buttons["Seç"].firstMatch.click()
        let add = app.buttons["Seçilen Oyunu Ekle"]
        for _ in 0..<10 where !add.isHittable { app.scrollViews.firstMatch.swipeUp() }
        XCTAssertTrue(add.isHittable)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Phase 2 catalog selection and manual fallback"
        screenshot.lifetime = .keepAlways
        self.add(screenshot)
        add.click()
        XCTAssertTrue(app.buttons["Kapat"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.links["RAWG'de görüntüle"].firstMatch.waitForExistence(timeout: 5), app.debugDescription)
    }

    @MainActor func testFailedSaveRetainsManualInputAndSheet() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-save-failure"]
        app.launch()
        app.buttons["Oyun Ekle"].click()
        let title = app.textFields["manualTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.click()
        title.typeText("Korunan Oyun")
        app.buttons["Elle Ekle"].click()
        XCTAssertEqual(title.value as? String, "Korunan Oyun")
        XCTAssertTrue(app.staticTexts["Yerel kayıt tamamlanamadı. Girdiğiniz ad korunuyor; tekrar deneyebilirsiniz."].exists)
        XCTAssertTrue(app.buttons["Elle Ekle"].exists)
    }
}
