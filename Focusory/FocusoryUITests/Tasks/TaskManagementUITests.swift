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
