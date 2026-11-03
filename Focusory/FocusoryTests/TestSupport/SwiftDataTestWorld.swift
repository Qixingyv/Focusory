import Foundation
import SwiftData
@testable import Focusory

/// SwiftData 测试环境；使用独立的内存容器，不触碰开发者真实数据。
@MainActor
final class SwiftDataTestWorld {
    /// 当前测试独立使用的内存数据库，避免测试间共享数据。
    let container: ModelContainer
    /// 仓储和事务共用的上下文，关闭自动保存以验证实际提交行为。
    let context: ModelContext

    /// 创建内存容器与共享上下文。
    init() throws {
        container = try FocusoryLocalStore.makeContainer(isStoredInMemoryOnly: true)
        context = FocusoryLocalStore.makeTransactionContext(in: container)
    }

    /// 使用当前上下文读写任务，供准备数据和执行断言。
    var tasks: SwiftDataTaskRepository { SwiftDataTaskRepository(context: context) }
    /// 读取当前上下文中的会话，供验证完成数和时长。
    var sessions: SwiftDataSessionRepository { SwiftDataSessionRepository(context: context) }
    /// 使用当前上下文读写每日进度。
    var dailyProgress: SwiftDataDailyProgressRepository { SwiftDataDailyProgressRepository(context: context) }
    /// 使用当前上下文读写待上传操作。
    var syncQueue: SwiftDataSyncQueueRepository { SwiftDataSyncQueueRepository(context: context) }
    /// 提交或回滚当前上下文中的写入。
    var transaction: SwiftDataLocalTransaction { SwiftDataLocalTransaction(context: context) }

    /// 从新上下文读取任务，避免把尚未提交的数据误认为保存成功。
    var committedTasks: SwiftDataTaskRepository {
        SwiftDataTaskRepository(context: FocusoryLocalStore.makeTransactionContext(in: container))
    }

    /// 从新上下文读取同步队列，验证操作是否真正保存。
    var committedSyncQueue: SwiftDataSyncQueueRepository {
        SwiftDataSyncQueueRepository(context: FocusoryLocalStore.makeTransactionContext(in: container))
    }

    /// 从新上下文读取每日进度，验证进度是否真正保存。
    var committedDailyProgress: SwiftDataDailyProgressRepository {
        SwiftDataDailyProgressRepository(context: FocusoryLocalStore.makeTransactionContext(in: container))
    }

    /// 创建通过规则校验的待办任务，供持久化测试准备数据。
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
