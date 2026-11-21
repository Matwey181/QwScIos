import XCTest

final class ImportUITests: XCTestCase {
    func testPickTwoPNGFilesAndReturnToApp() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Файлы"].tap()
        app.buttons["importFiles"].tap()
        let browser = app.collectionViews["File View"]
        XCTAssertTrue(browser.waitForExistence(timeout: 30), app.debugDescription)
        let back = app.buttons.matching(NSPredicate(format: "label IN %@", ["On My iPhone", "На iPhone"])).firstMatch
        XCTAssertTrue(back.waitForExistence(timeout: 10), app.debugDescription)
        back.tap()
        let folder = browser.cells.matching(NSPredicate(format: "label BEGINSWITH %@", "Import Fixtures")).firstMatch
        XCTAssertTrue(folder.waitForExistence(timeout: 30), app.debugDescription)
        folder.tap()
        let select = app.buttons.matching(NSPredicate(format: "label IN %@", ["Select", "Выбрать"])).firstMatch
        if select.exists { select.tap() }
        else {
            let menu = app.buttons["DOC.itemCollectionMenuButton.Icons"]
            if menu.exists {
                menu.tap()
                if select.waitForExistence(timeout: 2) { select.tap() }
                else { app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.5)).tap() }
            }
        }
        for name in ["import-test-a", "import-test-b"] {
            // The app's own list is still in the AX tree behind the modal.
            // Only interact with the system picker's collection cells.
            let file = browser.cells.matching(NSPredicate(format: "label BEGINSWITH %@", name)).firstMatch
            XCTAssertTrue(file.waitForExistence(timeout: 20), app.debugDescription)
            file.tap()
        }
        let open = app.buttons.matching(NSPredicate(format: "label IN %@", ["Open", "Открыть", "Add", "Добавить", "Done", "Готово"])).firstMatch
        XCTAssertTrue(open.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(open.isEnabled)
        open.tap()
        // Inputs belong to a separate app, just like files in Downloads or a
        // different Files provider. Neither may already exist in this app.
        XCTAssertTrue(app.buttons["file-import-test-a.png"].waitForExistence(timeout: 20), app.debugDescription)
        XCTAssertTrue(app.buttons["file-import-test-b.png"].waitForExistence(timeout: 20), app.debugDescription)
        XCTAssertTrue(app.buttons["importFiles"].isEnabled)
        XCTAssertTrue(app.buttons["importFiles"].isHittable)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Multiple files imported"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
