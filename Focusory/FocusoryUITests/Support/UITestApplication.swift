import XCTest

/// UI 测试共用的应用启动入口。
extension XCUIApplication {
    /// 启动一个使用内存存储的应用实例，保证测试从空数据开始。
    static func launchWithCleanStore() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("-focusory-in-memory-store")
        app.launch()
        return app
    }
}
