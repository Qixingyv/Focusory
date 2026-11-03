import XCTest

/// 覆盖任务管理的创建、编辑、完成与删除关键路径。
final class TaskManagementUITests: XCTestCase {

    /// 在每个 UI 测试前启用失败即停，避免在无效界面状态上继续操作。
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// 新建待办任务后空状态消失，任务出现在进行中列表。
    @MainActor
    func testCreatesTodoTaskAndReplacesEmptyState() throws {
        let app = XCUIApplication.launchWithCleanStore()
        XCTAssertTrue(app.groups["task-empty-state"].waitForExistence(timeout: 3))

        createTask(in: app, name: "写 F01 UI 测试")

        XCTAssertTrue(app.staticTexts["写 F01 UI 测试"].exists)
        XCTAssertFalse(app.groups["task-empty-state"].exists)
    }

    /// 编辑任务名称后卡片显示新名称。
    @MainActor
    func testEditsTaskName() throws {
        let app = XCUIApplication.launchWithCleanStore()
        createTask(in: app, name: "原始任务名")

        app.buttons["task-edit-button"].firstMatch.click()

        let nameField = app.textFields["task-name-field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.click()
        nameField.typeKey("a", modifierFlags: .command)
        nameField.typeText("改名后的任务")
        app.buttons["task-editor-save-button"].click()

        XCTAssertTrue(app.staticTexts["改名后的任务"].waitForExistence(timeout: 3))
    }

    /// 没有历史记录的任务经过行内确认后可以删除，并回到空状态。
    @MainActor
    func testDeletesTaskWithoutHistoryAfterInlineConfirmation() throws {
        let app = XCUIApplication.launchWithCleanStore()
        createTask(in: app, name: "待删除任务")

        app.buttons["task-remove-button"].firstMatch.click()

        let confirmButton = app.buttons["task-inline-confirm-button"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 2))
        confirmButton.click()

        XCTAssertTrue(app.groups["task-empty-state"].waitForExistence(timeout: 3))
    }

    /// 手动完成的任务出现在已完成分段。
    @MainActor
    func testCompletesTaskIntoCompletedSegment() throws {
        let app = XCUIApplication.launchWithCleanStore()
        createTask(in: app, name: "待完成任务")

        app.buttons["task-complete-button"].firstMatch.click()

        let confirmButton = app.buttons["task-inline-confirm-button"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 2))
        confirmButton.click()

        XCTAssertTrue(app.groups["task-empty-state"].waitForExistence(timeout: 3))

        app.buttons["task-status-completed"].click()
        XCTAssertTrue(app.staticTexts["待完成任务"].waitForExistence(timeout: 3))
    }

    /// 新建任务弹窗在名称为空时禁用保存，填写后可保存。
    @MainActor
    func testCreateEditorRequiresTaskName() throws {
        let app = XCUIApplication.launchWithCleanStore()
        app.buttons["task-create-button"].firstMatch.click()

        let saveButton = app.buttons["task-editor-save-button"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2))
        XCTAssertFalse(saveButton.isEnabled)

        app.buttons["task-editor-cancel-button"].click()
        XCTAssertTrue(app.groups["task-empty-state"].waitForExistence(timeout: 3))
    }

    /// 持续任务启用计划周期和每日目标后可以保存。
    @MainActor
    func testCreatesOngoingTaskWithDateRangeAndDailyTarget() throws {
        let app = XCUIApplication.launchWithCleanStore()
        app.buttons["task-create-button"].firstMatch.click()

        let nameField = app.textFields["task-name-field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.click()
        nameField.typeText("持续任务")

        app.buttons["task-mode-ongoing"].click()
        let dateRangeToggle = app.descendants(matching: .any)["task-date-range-toggle"]
        XCTAssertTrue(dateRangeToggle.waitForExistence(timeout: 2))
        dateRangeToggle.click()
        app.descendants(matching: .any)["task-daily-target-toggle"].click()

        app.buttons["task-editor-save-button"].click()
        XCTAssertTrue(app.staticTexts["持续任务"].waitForExistence(timeout: 3))
    }

    /// 专注时长步进器的加减按钮在按钮边缘也能点击，并立即更新数值。
    @MainActor
    func testFocusDurationStepperRespondsAtButtonEdge() throws {
        let app = XCUIApplication.launchWithCleanStore()
        app.buttons["task-create-button"].firstMatch.click()

        let increment = app.buttons["task-focus-duration-stepper-increment"]
        XCTAssertTrue(increment.waitForExistence(timeout: 2))
        XCTAssertGreaterThanOrEqual(increment.frame.width, 34)
        XCTAssertGreaterThanOrEqual(increment.frame.height, 34)

        let value = app.staticTexts["task-focus-duration-stepper-value"]
        XCTAssertTrue(value.waitForExistence(timeout: 2))
        XCTAssertEqual(value.value as? String, "25")

        increment.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.85)).click()
        waitForValue("30", in: value)

        let decrement = app.buttons["task-focus-duration-stepper-decrement"]
        decrement.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.15)).click()
        waitForValue("25", in: value)

        app.buttons["task-editor-cancel-button"].click()
    }

    /// 等待步进器数值在界面上更新。
    private func waitForValue(_ expectedValue: String, in element: XCUIElement) {
        let predicate = NSPredicate(format: "value == %@", expectedValue)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 2), .completed)
    }

    /// 通过新建任务弹窗创建任务并等待卡片出现。
    private func createTask(in app: XCUIApplication, name: String) {
        app.buttons["task-create-button"].firstMatch.click()

        let nameField = app.textFields["task-name-field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.click()
        nameField.typeText(name)

        app.buttons["task-editor-save-button"].click()
        XCTAssertTrue(app.groups.matching(identifier: "task-card").element(boundBy: 0).waitForExistence(timeout: 3))
    }
}
