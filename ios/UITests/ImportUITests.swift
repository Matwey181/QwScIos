import XCTest

final class ImportUITests: XCTestCase {
    func testPickTwoPNGFilesAndReturnToApp() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Файлы"].tap()
        app.buttons["importFiles"].tap()
        let select = app.buttons.matching(NSPredicate(format: "label IN %@", ["Select", "Выбрать"])).firstMatch
        if select.waitForExistence(timeout: 3) { select.tap() }
        for name in ["import-test-a", "import-test-b"] {
            let file = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", name)).firstMatch
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
