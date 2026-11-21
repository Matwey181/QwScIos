import XCTest
final class EditorUITests:XCTestCase {
    func testCreateEditReopenProject() {
        continueAfterFailure=false
        let app=XCUIApplication();app.launch()
        app.buttons["newProject"].tap()
        app.swipeUp()
        app.buttons["createProject"].tap()
        let addButton=app.buttons["panel-add"]
        XCTAssertTrue(addButton.waitForExistence(timeout:10));addButton.tap()
        let insertShot=XCTAttachment(screenshot:app.screenshot());insertShot.name="Original insert panel";insertShot.lifetime = .keepAlways;add(insertShot)
        let rect=app.buttons["add-RECT"]
        XCTAssertTrue(rect.waitForExistence(timeout:10));rect.tap()
        let undo=app.buttons["undo"]
        XCTAssertTrue(undo.waitForExistence(timeout:10));XCTAssertTrue(undo.isEnabled)
        undo.tap()
        let attachment=XCTAttachment(screenshot:app.screenshot());attachment.name="Qwel iOS editor";attachment.lifetime = .keepAlways;add(attachment)
        app.buttons["Закрыть редактор"].tap()
        XCTAssertTrue(app.buttons["newProject"].waitForExistence(timeout:10))
    }
}
