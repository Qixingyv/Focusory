import XCTest

/// 在不同界面配置下启动应用并保留初始界面截图。
final class FocusoryUITestsLaunchTests: XCTestCase {

    /// 让启动截图覆盖每种目标应用 UI 配置。
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    /// 在每个启动测试前启用失败即停。
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// 启动应用并保留当前初始界面截图。
    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
