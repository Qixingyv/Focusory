import SwiftUI

/// 启动 Focusory 主窗口并配置 macOS 窗口外观与尺寸的应用入口。
@main
struct FocusoryApp: App {
    /// 保存启动所需的依赖；创建失败时为空，改为显示重试界面。
    @State private var dependencies: AppDependencies?

    /// 启动应用并尝试装配依赖；UI 测试通过启动参数改用内存存储。
    init() {
        if ProcessInfo.processInfo.arguments.contains(AppDependencies.inMemoryStoreLaunchArgument) {
            _dependencies = State(initialValue: try? AppDependencies.makeInMemory())
        } else {
            _dependencies = State(initialValue: try? AppDependencies.makeDefault())
        }
    }

    /// 定义主窗口场景，配置初始尺寸、标题栏和最小尺寸约束。
    var body: some Scene {
        WindowGroup {
            if let dependencies {
                ContentView(dependencies: dependencies)
            } else {
                StartupFailureView {
                    dependencies = try? AppDependencies.makeDefault()
                }
            }
        }
        .defaultSize(width: 1180, height: 760)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
    }
}

/// 本地存储无法打开时显示的可重试启动错误界面。
struct StartupFailureView: View {
    /// 用户点击重试后执行的操作，由应用入口重新创建依赖。
    let onRetry: () -> Void

    /// 显示失败说明与重试入口。
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "externaldrive.badge.exclamationmark")
                .font(FocusoryTypography.pageIcon)
                .foregroundStyle(Color.focusoryWarning)

            Text(.tasksFailurePersistenceFailed)
                .font(FocusoryTypography.body)
                .foregroundStyle(Color.focusoryTextSecondary)

            Button(.tasksErrorRetry, action: onRetry)
                .focusoryPrimaryButton(
                    horizontalPadding: 16,
                    minHeight: 30,
                    cornerRadius: 9,
                    font: FocusoryTypography.supportingEmphasized
                )
                .accessibilityIdentifier("startup-retry-button")
        }
        .frame(minWidth: 900, minHeight: 620)
        .background(Color.focusoryPageBackground)
        .accessibilityIdentifier("startup-error-state")
    }
}
