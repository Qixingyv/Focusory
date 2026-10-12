import Foundation

/// 任务用例共享的依赖集合；由组装根创建，用例不自行实例化技术适配器。
struct TaskUseCaseEnvironment {
    /// 任务仓储。
    let tasks: any TaskRepository
    /// 会话查询。
    let sessions: any SessionRepository
    /// 每日进度仓储。
    let dailyProgress: any DailyProgressRepository
    /// 同步队列仓储。
    let syncQueue: any SyncQueueRepository
    /// 本地原子提交。
    let transaction: any LocalTransaction
    /// 当前账户。
    let account: any CurrentAccountProvider
    /// 本机日历。
    let calendar: any CalendarProvider
    /// 当前瞬时。
    let clock: any Clock
    /// F02 计时能力。
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

    /// 在事务内追加一条待同步变更。
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
