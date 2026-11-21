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
        // Fixtures exist at the Documents root; successful import adds a second
        // copy in Imports. Seeing only the originals must not pass this test.
        let a = app.buttons.matching(identifier: "file-import-test-a.png")
        let imported = expectation(for: NSPredicate(format: "count == 2"), evaluatedWith: a)
        wait(for: [imported], timeout: 20)
        XCTAssertEqual(app.buttons.matching(identifier: "file-import-test-b.png").count, 2, app.debugDescription)
        XCTAssertTrue(app.buttons["importFiles"].isEnabled)
        XCTAssertTrue(app.buttons["importFiles"].isHittable)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Multiple files imported"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
