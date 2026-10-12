import XCTest

final class FocusoryUITests: XCTestCase {

    /// 在每个 UI 测试前启用失败即停，避免在无效界面状态上继续操作。
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// 验证任务页面、空状态和新建任务编辑器可以访问。
    @MainActor
    func testTaskScreenAndEditorAreAvailable() throws {
        let app = XCUIApplication.launchWithCleanStore()

        XCTAssertTrue(app.buttons["task-status-active"].exists)
        XCTAssertTrue(app.groups["task-empty-state"].exists)

        let newTaskButton = app.buttons["task-create-button"].firstMatch
        XCTAssertTrue(newTaskButton.exists)
        newTaskButton.click()

        XCTAssertTrue(app.buttons["task-editor-save-button"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["task-mode-todo"].exists)
        XCTAssertTrue(app.staticTexts["task-editor-title"].exists)
    }

    /// 验证系统标签侧边栏可以在任务、专注和统计三个顶层页面之间切换。
    @MainActor
    func testTopLevelTabsSwitchFeaturePages() throws {
        let app = XCUIApplication()
        app.launch()

        let sidebar = app.outlines.firstMatch
        XCTAssertTrue(sidebar.waitForExistence(timeout: 2))

        // 系统 TabView 不公开 TabContent 的 identifier；header 后的三个 cell 按 AppDestination 顺序对应顶层标签。
        let sidebarItems = sidebar.cells
        let focusTab = sidebarItems.element(boundBy: 2)
        XCTAssertTrue(focusTab.waitForExistence(timeout: 2))
        focusTab.click()
        XCTAssertTrue(app.groups["focus-placeholder"].waitForExistence(timeout: 2))

        let statisticsTab = sidebarItems.element(boundBy: 3)
        XCTAssertTrue(statisticsTab.exists)
        statisticsTab.click()
        XCTAssertTrue(app.groups["statistics-placeholder"].waitForExistence(timeout: 2))

        let tasksTab = sidebarItems.element(boundBy: 1)
        XCTAssertTrue(tasksTab.exists)
        tasksTab.click()
        XCTAssertTrue(app.buttons["task-status-active"].waitForExistence(timeout: 2))
    }

    /// 测量应用从启动到界面可用的耗时。
    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
