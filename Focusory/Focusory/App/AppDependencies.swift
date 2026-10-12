import Foundation
import SwiftData

/// 组装根：创建本地容器与共享上下文，并把端口实现装配为用例依赖。
@MainActor
final class AppDependencies {
    /// 本地模型容器。
    let container: ModelContainer
    /// 任务用例共享依赖。
    let taskEnvironment: TaskUseCaseEnvironment
    /// 当前本机工作空间的账户标识。
    let currentAccountID: AccountID
    /// 启动参数：改用内存存储，供 UI 测试在干净数据上运行。
    static let inMemoryStoreLaunchArgument = "-focusory-in-memory-store"

    /// 用给定容器与端口实现装配依赖；全部仓储共享同一个关闭自动保存的上下文。
    init(
        container: ModelContainer,
        focusTimer: any FocusTimerService = PlaceholderFocusTimerService(),
        clock: any Clock = SystemClock(),
        calendar: any CalendarProvider = SystemCalendarProvider(),
        account: any CurrentAccountProvider = LocalWorkspaceAccountProvider()
    ) {
        self.container = container
        self.currentAccountID = account.currentAccountID

        let context = FocusoryLocalStore.makeTransactionContext(in: container)
        self.taskEnvironment = TaskUseCaseEnvironment(
            tasks: SwiftDataTaskRepository(context: context),
            sessions: SwiftDataSessionRepository(context: context),
            dailyProgress: SwiftDataDailyProgressRepository(context: context),
            syncQueue: SwiftDataSyncQueueRepository(context: context),
            transaction: SwiftDataLocalTransaction(context: context),
            account: account,
            calendar: calendar,
            clock: clock,
            focusTimer: focusTimer
        )
    }

    /// 创建使用本机持久化存储的默认依赖。
    /// - 失败：本地容器无法打开时抛出，由界面显示可重试的启动错误，不静默改用空存储。
    static func makeDefault() throws -> AppDependencies {
        AppDependencies(container: try FocusoryLocalStore.makeContainer())
    }

    /// 创建使用内存存储的依赖；供预览与测试使用，不触碰开发者真实数据。
    static func makeInMemory() throws -> AppDependencies {
        AppDependencies(container: try FocusoryLocalStore.makeContainer(isStoredInMemoryOnly: true))
    }
}
