import Foundation
import SwiftData

/// 创建本地存储，并将仓储、事务和系统能力连接到业务用例。
@MainActor
final class AppDependencies {
    /// 本地数据库容器，仓储和事务共用的上下文由它创建。
    let container: ModelContainer
    /// 任务操作共用的仓储、事务、账户和时间等能力。
    let taskEnvironment: TaskUseCaseEnvironment
    /// 当前本机账户标识；任务环境使用同一个账户。
    let currentAccountID: AccountID
    /// 启动参数：改用内存存储，供 UI 测试在干净数据上运行。
    static let inMemoryStoreLaunchArgument = "-focusory-in-memory-store"

    /// 连接存储与业务能力；仓储和事务共用一个关闭自动保存的上下文。
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
