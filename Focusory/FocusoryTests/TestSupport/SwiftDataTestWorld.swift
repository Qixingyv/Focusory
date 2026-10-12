import Foundation
import SwiftData
@testable import Focusory

/// SwiftData 测试环境；使用独立的内存容器，不触碰开发者真实数据。
@MainActor
final class SwiftDataTestWorld {
    /// 内存模型容器。
    let container: ModelContainer
    /// 与仓储共享的关闭自动保存的上下文。
    let context: ModelContext

    /// 创建内存容器与共享上下文。
    init() throws {
        container = try FocusoryLocalStore.makeContainer(isStoredInMemoryOnly: true)
        context = FocusoryLocalStore.makeTransactionContext(in: container)
    }

    /// 实时任务仓储。
    var tasks: SwiftDataTaskRepository { SwiftDataTaskRepository(context: context) }
    /// 会话查询仓储。
    var sessions: SwiftDataSessionRepository { SwiftDataSessionRepository(context: context) }
    /// 每日进度仓储。
    var dailyProgress: SwiftDataDailyProgressRepository { SwiftDataDailyProgressRepository(context: context) }
    /// 同步队列仓储。
    var syncQueue: SwiftDataSyncQueueRepository { SwiftDataSyncQueueRepository(context: context) }
    /// 本地事务执行器。
    var transaction: SwiftDataLocalTransaction { SwiftDataLocalTransaction(context: context) }

    /// 用新的上下文重读，验证写入是否真正提交到存储。
    var committedTasks: SwiftDataTaskRepository {
        SwiftDataTaskRepository(context: FocusoryLocalStore.makeTransactionContext(in: container))
    }

    /// 用新的上下文重读同步队列，验证提交结果。
    var committedSyncQueue: SwiftDataSyncQueueRepository {
        SwiftDataSyncQueueRepository(context: FocusoryLocalStore.makeTransactionContext(in: container))
    }

    /// 用新的上下文重读每日进度，验证提交结果。
    var committedDailyProgress: SwiftDataDailyProgressRepository {
        SwiftDataDailyProgressRepository(context: FocusoryLocalStore.makeTransactionContext(in: container))
    }

    /// 构造一个已通过的待办任务。
    func makeTodoTask(
        ownerID: AccountID,
        name: String = "持久化任务",
        todoTarget: Int = 3
    ) throws -> FocusTask {
        try FocusTask.create(
            draft: TaskDraft(name: name, mode: .todo, todoTarget: todoTarget),
            ownerID: ownerID,
            today: TaskTestWorld.today,
            now: Date(timeIntervalSince1970: 1_792_000_000)
        )
    }

    /// 构造一个开启计划周期与每日目标的持续任务。
    func makeOngoingTask(ownerID: AccountID) throws -> FocusTask {
        try FocusTask.create(
            draft: TaskDraft(
                name: "持续任务",
                mode: .ongoing,
                hasDateRange: true,
                startDate: TaskTestWorld.today,
                endDate: makeLocalDate("2026-12-31"),
                hasDailyTarget: true,
                dailyTarget: 2
            ),
            ownerID: ownerID,
            today: TaskTestWorld.today,
            now: Date(timeIntervalSince1970: 1_792_000_000)
        )
    }
}
