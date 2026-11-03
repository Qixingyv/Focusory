import Foundation

/// 集中提供任务用例需要的外部能力，由应用入口连接真实或测试实现。
struct TaskUseCaseEnvironment {
    /// 读取、保存和删除任务。
    let tasks: any TaskRepository
    /// 查询已保存的会话，用于判断历史记录和计算累计进度。
    let sessions: any SessionRepository
    /// 读取和保存按任务、本机日期区分的每日进度。
    let dailyProgress: any DailyProgressRepository
    /// 保存待上传变更，并查询操作是否已经生效。
    let syncQueue: any SyncQueueRepository
    /// 让业务数据与待同步变更一起提交，失败时一起回滚。
    let transaction: any LocalTransaction
    /// 提供当前账户，限定本次操作可以访问的数据。
    let account: any CurrentAccountProvider
    /// 将时刻换算为本机日期，用于计划日期和当日目标判断。
    let calendar: any CalendarProvider
    /// 提供业务操作的当前时刻，测试时可替换为固定时钟。
    let clock: any Clock
    /// 查询任务是否被计时锁定，并交接开始专注时的配置。
    let focusTimer: any FocusTimerService
}

extension TaskUseCaseEnvironment {
    /// 读取本地事实；非业务错误统一映射为持久化失败，界面不解析底层文本。
    func read<T>(_ work: () throws -> T) throws -> T {
        do {
            return try work()
        } catch let failure as TaskFailure {
            throw failure
        } catch {
            #if DEBUG
            print("[Focusory][Tasks] read failed: \(error)")
            #endif
            throw TaskFailure(.persistenceFailed)
        }
    }

    /// 在本地事务中提交业务写入与待同步变更；任一步失败时整体回滚。
    func commit<T>(_ work: () throws -> T) throws -> T {
        do {
            return try transaction.perform(work)
        } catch let failure as TaskFailure {
            throw failure
        } catch {
            #if DEBUG
            print("[Focusory][Tasks] commit failed: \(error)")
            #endif
            throw TaskFailure(.persistenceFailed)
        }
    }

    /// 读取账户内的任务；不存在或不属于该账户时抛「任务不可用」。
    func requireTask(id: UUID, ownerID: AccountID) throws -> FocusTask {
        guard let task = try read({ try tasks.task(id: id, ownerID: ownerID) }) else {
            throw TaskFailure(.taskUnavailable)
        }
        return task
    }

    /// 判断任务是否已有历史会话。
    func hasHistory(taskID: UUID, ownerID: AccountID) throws -> Bool {
        try read { try sessions.completedSessionCount(taskID: taskID, ownerID: ownerID) > 0 }
    }

    /// 判断同一操作标识是否已经生效；用于阻止重复提交产生第二次业务结果。
    func isOperationApplied(operationID: UUID, ownerID: AccountID) throws -> Bool {
        try read { try syncQueue.item(operationID: operationID, ownerID: ownerID) != nil }
    }

    /// 追加一条待同步变更；调用方须把它放在本地事务中提交。
    func enqueueChange(
        entityType: SyncEntityType,
        entityID: UUID,
        operationType: SyncOperationType,
        ownerID: AccountID,
        now: Date,
        operationID: UUID = UUID()
    ) throws {
        try syncQueue.enqueue(
            SyncQueueItem(
                operationID: operationID,
                ownerID: ownerID,
                entityType: entityType,
                entityID: entityID,
                operationType: operationType,
                createdAt: now
            )
        )
    }
}
