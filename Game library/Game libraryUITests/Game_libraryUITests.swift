import XCTest

final class Game_libraryUITests: XCTestCase {
    @MainActor private func launch(_ app: XCUIApplication) {
        app.launch()
        app.activate()
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 10), "Test window did not open")
    }

    @MainActor func testTestLaunchIgnoresBuildKeyAndExplainsKeychainOverride() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        launch(app)
        app.buttons["Oyun Ekle"].click()
        app.buttons["API Anahtarını Ayarla"].click()
        let explanation = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", "derleme sırasında konan anahtarın önüne geçer", "derleme sırasında konan anahtarın önüne geçer")).firstMatch
        XCTAssertTrue(explanation.waitForExistence(timeout: 5))
        let screenshot = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
        screenshot.name = "RAWG anahtar önceliği açıklaması"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.buttons["Vazgeç"].click()
        XCTAssertTrue(app.staticTexts["Katalog araması için RAWG API anahtarınızı ayarlayın. Elle ekleme her zaman kullanılabilir."].exists)
    }

    @MainActor func testBulkImportStopsAtQuotaAndResumesAfterRelaunch() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["GAME_LIBRARY_TEST_STORE_ID"] = UUID().uuidString
        app.launchArguments = ["--ui-testing", "--ui-testing-bulk", "--ui-testing-bulk-quota"]
        launch(app)
        app.buttons["Oyun Ekle"].click()
        let manual = app.textFields["manualTitle"]
        XCTAssertTrue(manual.waitForExistence(timeout: 5))
        manual.click()
        manual.typeText("Toplu Oyun 1")
        app.buttons["Elle Ekle"].click()
        XCTAssertTrue(app.buttons["detailDismiss"].waitForExistence(timeout: 5))
        app.buttons["detailDismiss"].click()
        app.buttons["Oyun Ekle"].click()
        setBulkTestKey(app)
        revealBulkControls(app)
        app.buttons["bulkStart"].click()
        let quota = app.staticTexts["RAWG istek kotası doldu. Lütfen daha sonra tekrar deneyin veya elle ekleyin."]
        XCTAssertTrue(quota.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue((app.staticTexts["bulkProgress"].value as? String ?? "").contains("Sıradaki sayfa: 2"), app.debugDescription)
        XCTAssertEqual(app.buttons["Tüm Oyunlar"].value as? String, "2")
        app.terminate()

        app.launchArguments = ["--ui-testing", "--ui-testing-bulk"]
        launch(app)
        XCTAssertTrue(app.buttons["Oyun Ekle"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["Tüm Oyunlar"].value as? String, "2")
        app.buttons["Oyun Ekle"].click()
        setBulkTestKey(app)
        revealBulkControls(app)
        XCTAssertTrue((app.staticTexts["bulkProgress"].value as? String ?? "").contains("Sıradaki sayfa: 2"))
        app.buttons["bulkStart"].click()
        XCTAssertTrue(app.staticTexts["Katalog aktarımı tamamlandı."].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons["Tüm Oyunlar"].value as? String, "3")
        XCTAssertFalse((app.buttons["gameCard-Toplu Oyun 2"].value as? String ?? "").contains("Puan"))
        let screenshot = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
        screenshot.name = "Phase 6 resumed bulk import"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.terminate()
    }

    @MainActor private func setBulkTestKey(_ app: XCUIApplication) {
        app.buttons["API Anahtarını Ayarla"].click()
        let key = app.secureTextFields.firstMatch
        XCTAssertTrue(key.waitForExistence(timeout: 5))
        key.click()
        key.typeText("synthetic-not-real")
        app.buttons["Kaydet"].click()
    }

    @MainActor private func revealBulkControls(_ app: XCUIApplication) {
        let button = app.buttons["bulkStart"]
        let form = app.scrollViews.containing(.textField, identifier: "manualTitle").firstMatch
        for _ in 0..<12 where !button.isHittable { form.swipeUp() }
        XCTAssertTrue(button.isHittable, app.debugDescription)
    }

    @MainActor func testDiskRelaunchAndOfflineEditing() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["GAME_LIBRARY_TEST_STORE_ID"] = UUID().uuidString
        app.launchArguments = ["--ui-testing", "--ui-testing-catalog"]
        launch(app)
        app.buttons["Oyun Ekle"].click()
        let query = app.textFields["searchTitle"]
        XCTAssertTrue(query.waitForExistence(timeout: 5))
        query.click()
        query.typeText("Katalog")
        app.buttons["Ara"].click()
        XCTAssertTrue(app.buttons["Seç"].firstMatch.waitForExistence(timeout: 5))
        app.buttons["Seç"].firstMatch.click()
        let confirm = app.buttons["Seçilen Oyunu Ekle"]
        for _ in 0..<10 where !confirm.isHittable { app.scrollViews.firstMatch.swipeUp() }
        confirm.click()
        XCTAssertTrue(app.checkBoxes["Kütüphanem"].waitForExistence(timeout: 5))
        app.checkBoxes["Kütüphanem"].click()
        app.checkBoxes["Bitti"].click()
        app.menuButtons["Kişisel puan"].click()
        app.menuItems["9/10"].click()
        app.buttons["detailDismiss"].click()
        app.terminate()

        app.launchArguments = ["--ui-testing", "--ui-testing-offline"]
        launch(app)
        let card = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "gameCard-")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        XCTAssertTrue((card.value as? String ?? "").contains("Puan: 9/10"))
        XCTAssertTrue((card.value as? String ?? "").contains("Bitti"))
        XCTAssertTrue(app.links["RAWG kaynağında görüntüle"].exists)
        card.click()
        XCTAssertTrue(app.checkBoxes["Kütüphanem"].waitForExistence(timeout: 5))
        XCTAssertFalse(isOff(app.checkBoxes["Kütüphanem"]))
        XCTAssertTrue(isOff(app.checkBoxes["Oynandı"]))
        app.checkBoxes["Wishlist"].click()
        app.menuButtons["Kişisel puan"].click()
        app.menuItems["Puanı kaldır"].click()
        app.buttons["detailDismiss"].click()
        app.buttons["Oyun Ekle"].click()
        XCTAssertTrue(query.waitForExistence(timeout: 5))
        query.click()
        query.typeText("Offline")
        app.buttons["Ara"].click()
        XCTAssertTrue(app.staticTexts["Ağ bağlantısı kurulamadı. Tekrar deneyebilir veya elle ekleyebilirsiniz."].waitForExistence(timeout: 5))
        let manual = app.textFields["manualTitle"]
        manual.click()
        manual.typeKey("a", modifierFlags: .command)
        manual.typeText("Offline Manual")
        app.buttons["Elle Ekle"].click()
        XCTAssertTrue(app.buttons["detailDismiss"].waitForExistence(timeout: 5))
        app.buttons["detailDismiss"].click()
        app.terminate()
        launch(app)
        XCTAssertTrue(app.buttons["gameCard-Offline Manual"].waitForExistence(timeout: 5))
        app.descendants(matching: .any)["Wishlist"].firstMatch.click()
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        XCTAssertFalse((card.value as? String ?? "").contains("Puan:"))
        XCTAssertTrue((card.value as? String ?? "").contains("Wishlist"))
        let screenshot = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
        screenshot.name = "Phase 4 offline relaunch"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.terminate()
    }

    @MainActor func testFailedEditShowsErrorAndRevertsStatus() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-edit-save-failure"]
        launch(app)
        app.buttons["Oyun Ekle"].click()
        let title = app.textFields["manualTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.click()
        title.typeText("Failed Edit")
        app.buttons["Elle Ekle"].click()
        let status = app.checkBoxes["Wishlist"]
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        status.click()
        XCTAssertTrue(app.staticTexts["Değişiklik kaydedilemedi. Lütfen tekrar deneyin."].waitForExistence(timeout: 5))
        XCTAssertTrue(isOff(status))
        app.buttons["detailDismiss"].click()
        XCTAssertFalse((app.buttons["gameCard-Failed Edit"].value as? String ?? "").contains("Wishlist"))
    }

    @MainActor func testFourTabsManualAddAndSameNameConfirmation() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        launch(app)
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
        let screenshot = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
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
        XCTAssertTrue(app.buttons["detailDismiss"].waitForExistence(timeout: 5))
    }

    @MainActor func testCatalogSelectionRequiresConfirmation() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-catalog"]
        launch(app)
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
        let screenshot = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
        screenshot.name = "Phase 2 catalog selection and manual fallback"
        screenshot.lifetime = .keepAlways
        self.add(screenshot)
        add.click()
        XCTAssertTrue(app.buttons["detailDismiss"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.links["RAWG kaynağında görüntüle"].waitForExistence(timeout: 5), app.debugDescription)
    }

    @MainActor func testFailedSaveRetainsManualInputAndSheet() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-save-failure"]
        launch(app)
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

    @MainActor func testStatusAndRatingAreEditedFromGameDetail() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        launch(app)
        app.buttons["Oyun Ekle"].click()
        let title = app.textFields["manualTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.click()
        title.typeText("Durum Oyunu")
        app.buttons["Elle Ekle"].click()
        XCTAssertTrue(app.checkBoxes["Kütüphanem"].waitForExistence(timeout: 5), app.debugDescription)
        app.checkBoxes["Kütüphanem"].click()
        app.checkBoxes["Wishlist"].click()
        app.checkBoxes["Oynanacak"].click()
        app.checkBoxes["Bitti"].click()
        XCTAssertTrue(isOff(app.checkBoxes["Oynandı"]), "Oynandı value \(String(describing: app.checkBoxes["Oynandı"].value))")
        app.menuButtons["Kişisel puan"].click()
        XCTAssertTrue(app.menuItems["9/10"].waitForExistence(timeout: 5), app.debugDescription)
        app.menuItems["9/10"].click()
        XCTAssertEqual(app.menuButtons["Kişisel puan"].value as? String, "9/10")
        app.buttons["detailDismiss"].click()
        let card = app.buttons["gameCard-Durum Oyunu"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        let value = card.value as? String ?? ""
        XCTAssertTrue(value.contains("Kütüphane"), value)
        XCTAssertTrue(value.contains("Wishlist"), value)
        XCTAssertTrue(value.contains("Oynanacak"), value)
        XCTAssertTrue(value.contains("Bitti"), value)
        XCTAssertFalse(value.contains("Oynandı"), value)
        XCTAssertTrue(value.contains("Puan: 9/10"), value)

        card.click()
        XCTAssertTrue(app.checkBoxes["Wishlist"].waitForExistence(timeout: 5))
        app.checkBoxes["Wishlist"].click()
        app.menuButtons["Kişisel puan"].click()
        XCTAssertTrue(app.menuItems["Puanı kaldır"].waitForExistence(timeout: 5))
        app.menuItems["Puanı kaldır"].click()
        app.buttons["detailDismiss"].click()
        let updated = card.value as? String ?? ""
        XCTAssertFalse(updated.contains("Wishlist"), updated)
        XCTAssertFalse(updated.contains("Puan"), updated)
        XCTAssertTrue(updated.contains("Kütüphane"), updated)
        XCTAssertTrue(updated.contains("Bitti"), updated)
    }

    @MainActor func testEmptyManualAddWhitespaceRenameAndFilteredEmptyCopy() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        launch(app)

        app.buttons["Oyun Ekle"].click()
        let title = app.textFields["manualTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        app.buttons["Elle Ekle"].click()
        XCTAssertTrue(
            app.staticTexts["Oyun adı boş olamaz. Bir ad yazıp tekrar deneyin."].waitForExistence(timeout: 5),
            app.debugDescription
        )
        XCTAssertTrue(app.buttons["Elle Ekle"].exists)

        title.click()
        title.typeText("Yeniden Adlandır")
        app.buttons["Elle Ekle"].click()
        XCTAssertTrue(app.textFields["detailTitle"].waitForExistence(timeout: 5))
        let detailTitle = app.textFields["detailTitle"]
        detailTitle.click()
        detailTitle.typeKey("a", modifierFlags: .command)
        detailTitle.typeText("   ")
        app.buttons["Adı Kaydet"].click()
        XCTAssertTrue(
            app.staticTexts["Oyun adı boş olamaz. Bir ad yazıp tekrar deneyin."].waitForExistence(timeout: 5),
            app.debugDescription
        )
        XCTAssertTrue(
            app.staticTexts["Yeniden Adlandır"].firstMatch.exists,
            "Navigation title should stay after whitespace rename. \(app.debugDescription)"
        )
        app.buttons["detailDismiss"].click()
        XCTAssertTrue(app.buttons["gameCard-Yeniden Adlandır"].waitForExistence(timeout: 5))

        app.descendants(matching: .any)["Wishlist"].firstMatch.click()
        let filteredEmpty = "Bu sekmede henüz oyun yok. Bir oyunu açıp durumunu seçebilirsiniz."
        XCTAssertTrue(
            app.staticTexts[filteredEmpty].waitForExistence(timeout: 5),
            app.debugDescription
        )
        let emptyCopy = app.staticTexts[filteredEmpty].label
        XCTAssertFalse(emptyCopy.contains("sonraki aşama"))
    }

    @MainActor func testKeyboardCatalogSelectionReachesSourceLink() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-catalog"]
        launch(app)
        app.typeKey("n", modifierFlags: .command)
        let search = app.textFields["searchTitle"]
        XCTAssertTrue(search.waitForExistence(timeout: 5), app.debugDescription)
        search.click()
        search.typeText("Katalog\n")
        let select = app.buttons["select-1"]
        XCTAssertTrue(select.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertEqual(select.label, "Seç")
        select.click()
        let confirm = app.buttons["Seçilen Oyunu Ekle"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), app.debugDescription)
        app.typeKey(.return, modifierFlags: [])
        let link = app.links["gameSourceLink"]
        XCTAssertTrue(link.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertEqual(link.label, "RAWG kaynağında görüntüle")
        let card = app.buttons["gameCard-Katalog Oyunu 1"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        XCTAssertTrue((card.value as? String ?? "").contains("RAWG kataloğundan eklendi"))
        XCTAssertFalse((card.value as? String ?? "").contains("Puan"))
    }

    @MainActor func testCommandShortcutSelectsLibraryTab() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        launch(app)
        XCTAssertTrue(
            app.staticTexts["Başlamak için araç çubuğundan Oyun Ekle'yi seçin."].waitForExistence(timeout: 5),
            app.debugDescription
        )
        app.activate()
        app.windows.firstMatch.click()
        app.typeKey("2", modifierFlags: .command)
        let filteredEmpty = "Bu sekmede henüz oyun yok. Bir oyunu açıp durumunu seçebilirsiniz."
        let switched = app.staticTexts[filteredEmpty].waitForExistence(timeout: 5)
        if !switched {
            XCTFail("Command-2 did not select Kütüphanem (filtered empty copy missing). \(app.debugDescription)")
        }
    }

    @MainActor func testDestroyRemovesManualGameFromShelf() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["GAME_LIBRARY_TEST_STORE_ID"] = UUID().uuidString
        app.launchArguments = ["--ui-testing"]
        launch(app)
        app.buttons["Oyun Ekle"].click()
        let title = app.textFields["manualTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.click()
        title.typeText("Silinecek Oyun")
        app.buttons["Elle Ekle"].click()
        let destroy = app.buttons["detailDestroy"]
        let form = app.scrollViews.firstMatch
        for _ in 0..<8 where !destroy.waitForExistence(timeout: 1) || !destroy.isHittable {
            form.swipeUp()
        }
        XCTAssertTrue(destroy.waitForExistence(timeout: 5), app.debugDescription)
        destroy.click()
        let confirm = app.sheets.buttons["Sil"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), app.debugDescription)
        confirm.click()
        XCTAssertTrue(
            app.buttons["gameCard-Silinecek Oyun"].waitForNonExistence(timeout: 5),
            app.debugDescription
        )
    }

    @MainActor private func isOff(_ element: XCUIElement) -> Bool {
        switch element.value {
        case let number as NSNumber: return number.intValue == 0
        case let text as String: return text == "0" || text == "off"
        case let flag as Bool: return flag == false
        default: return false
        }
    }
}
