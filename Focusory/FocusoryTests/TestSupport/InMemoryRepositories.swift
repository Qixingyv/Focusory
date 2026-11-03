import Foundation
@testable import Focusory

/// 测试中的会话记录，用于准备任务完成数和累计专注时长。
struct SessionFixture: Equatable {
    /// 会话标识。
    let id: UUID
    /// 数据所属的账户，用于隔离不同账户的数据。
    let ownerID: AccountID
    /// 关联任务。
    let taskID: UUID
    /// 实际专注秒数。
    let focusDurationSeconds: Int
}

/// 每日进度的内存键；对应「任务 + 本机日期」唯一约束。
struct DailyProgressKey: Hashable {
    /// 数据所属的账户，用于隔离不同账户的数据。
    let ownerID: AccountID
    /// 关联任务。
    let taskID: UUID
    /// 归属的本机日期。
    let localDate: LocalDate
}

/// 集中保存测试数据，让各仓储和事务操作同一份数据。
@MainActor
final class InMemoryLocalStore {
    /// 测试中的任务数据，按标识查询和更新。
    var tasks: [UUID: FocusTask] = [:]
    /// 测试准备的会话记录，用于计算完成数和时长。
    var sessions: [SessionFixture] = []
    /// 按账户、任务和日期保存的测试进度。
    var dailyProgress: [DailyProgressKey: TaskDailyProgress] = [:]
    /// 测试中的待上传操作，按操作标识去重。
    var syncQueue: [UUID: SyncQueueItem] = [:]
    /// 模拟提交失败的错误；非空时每次提交都会回滚并抛出该错误。
    var commitFailure: Error?

    /// 记录一条已保存会话事实。
    func recordSession(taskID: UUID, ownerID: AccountID, focusDurationSeconds: Int = 1500) {
        sessions.append(
            SessionFixture(
                id: UUID(),
                ownerID: ownerID,
                taskID: taskID,
                focusDurationSeconds: focusDurationSeconds
            )
        )
    }

    /// 记录指定数量的已保存会话，用于准备达标进度。
    func recordSessions(count: Int, taskID: UUID, ownerID: AccountID, focusDurationSeconds: Int = 1500) {
        for _ in 0..<max(count, 0) {
            recordSession(taskID: taskID, ownerID: ownerID, focusDurationSeconds: focusDurationSeconds)
        }
    }

    /// 直接写入每日进度，用于准备今日达标状态。
    func seedDailyProgress(_ progress: TaskDailyProgress) {
        dailyProgress[DailyProgressKey(ownerID: progress.ownerID, taskID: progress.taskID, localDate: progress.localDate)] = progress
    }

    /// 复制当前测试数据，供事务失败时整体还原。
    func makeSnapshot() -> InMemorySnapshot {
        InMemorySnapshot(
            tasks: tasks,
            sessions: sessions,
            dailyProgress: dailyProgress,
            syncQueue: syncQueue
        )
    }

    /// 用快照覆盖当前内存事实，实现整体回滚。
    func restore(_ snapshot: InMemorySnapshot) {
        tasks = snapshot.tasks
        sessions = snapshot.sessions
        dailyProgress = snapshot.dailyProgress
        syncQueue = snapshot.syncQueue
    }
}

/// 事务开始前的测试数据副本，用于失败后的整体回滚。
struct InMemorySnapshot {
    /// 回滚时要恢复的任务数据。
    let tasks: [UUID: FocusTask]
    /// 回滚时要恢复的会话记录。
    let sessions: [SessionFixture]
    /// 回滚时要恢复的每日进度。
    let dailyProgress: [DailyProgressKey: TaskDailyProgress]
    /// 回滚时要恢复的待上传操作。
    let syncQueue: [UUID: SyncQueueItem]
}

/// 在内存中读写任务，供业务用例测试替代真实数据库。
@MainActor
final class InMemoryTaskRepository: TaskRepository {
    /// 仓储与事务共用的测试数据，供查询、写入和回滚验证。
    private let store: InMemoryLocalStore

    /// 用共享存储创建仓储。
    init(store: InMemoryLocalStore) {
        self.store = store
    }

    /// 返回账户内指定状态的任务。
    func tasks(ownerID: AccountID, status: FocusTaskStatus) throws -> [FocusTask] {
        store.tasks.values.filter { $0.ownerID == ownerID && $0.status == status }
    }

    /// 返回账户内的单个任务。
    func task(id: UUID, ownerID: AccountID) throws -> FocusTask? {
        guard let task = store.tasks[id], task.ownerID == ownerID else { return nil }
        return task
    }

    /// 统计账户内三个状态的任务数量。
    func counts(ownerID: AccountID) throws -> TaskStatusCounts {
        TaskStatusCounts(tasks: store.tasks.values.filter { $0.ownerID == ownerID })
    }

    /// 保存任务。
    func upsert(_ task: FocusTask) throws {
        store.tasks[task.id] = task
    }

    /// 删除任务。
    func delete(id: UUID, ownerID: AccountID) throws {
        guard store.tasks[id]?.ownerID == ownerID else { return }
        store.tasks[id] = nil
    }
}

/// 内存会话查询仓储。
@MainActor
final class InMemorySessionRepository: SessionRepository {
    /// 仓储与事务共用的测试数据，供查询、写入和回滚验证。
    private let store: InMemoryLocalStore

    /// 用共享存储创建仓储。
    init(store: InMemoryLocalStore) {
        self.store = store
    }

    /// 返回任务累计的已保存会话数。
    func completedSessionCount(taskID: UUID, ownerID: AccountID) throws -> Int {
        store.sessions.filter { $0.taskID == taskID && $0.ownerID == ownerID }.count
    }

    /// 返回任务累计的实际专注秒数。
    func totalFocusDurationSeconds(taskID: UUID, ownerID: AccountID) throws -> Int {
        store.sessions
            .filter { $0.taskID == taskID && $0.ownerID == ownerID }
            .reduce(0) { $0 + $1.focusDurationSeconds }
    }
}

/// 内存每日进度仓储。
@MainActor
final class InMemoryDailyProgressRepository: DailyProgressRepository {
    /// 仓储与事务共用的测试数据，供查询、写入和回滚验证。
    private let store: InMemoryLocalStore

    /// 用共享存储创建仓储。
    init(store: InMemoryLocalStore) {
        self.store = store
    }

    /// 读取任务在指定本机日期的唯一进度。
    func progress(taskID: UUID, ownerID: AccountID, localDate: LocalDate) throws -> TaskDailyProgress? {
        store.dailyProgress[DailyProgressKey(ownerID: ownerID, taskID: taskID, localDate: localDate)]
    }

    /// 保存每日进度；同一任务与日期覆盖原记录。
    func upsert(_ progress: TaskDailyProgress) throws {
        store.dailyProgress[
            DailyProgressKey(ownerID: progress.ownerID, taskID: progress.taskID, localDate: progress.localDate)
        ] = progress
    }
}

/// 内存同步队列仓储。
@MainActor
final class InMemorySyncQueueRepository: SyncQueueRepository {
    /// 仓储与事务共用的测试数据，供查询、写入和回滚验证。
    private let store: InMemoryLocalStore

    /// 用共享存储创建仓储。
    init(store: InMemoryLocalStore) {
        self.store = store
    }

    /// 追加待上传操作；同一操作标识不重复入队。
    func enqueue(_ queueItem: SyncQueueItem) throws {
        guard store.syncQueue[queueItem.operationID] == nil else { return }
        store.syncQueue[queueItem.operationID] = queueItem
    }

    /// 按操作标识查找队列项。
    func item(operationID: UUID, ownerID: AccountID) throws -> SyncQueueItem? {
        guard let queueItem = store.syncQueue[operationID], queueItem.ownerID == ownerID else { return nil }
        return queueItem
    }
}

/// 内存原子提交；闭包失败或注入提交失败时把全部写入还原为提交前状态。
@MainActor
final class InMemoryLocalTransaction: LocalTransaction {
    /// 仓储与事务共用的测试数据，供查询、写入和回滚验证。
    private let store: InMemoryLocalStore

    /// 用共享存储创建事务执行器。
    init(store: InMemoryLocalStore) {
        self.store = store
    }

    /// 在同一个内存事务中执行写入并提交。
    func perform<T>(_ work: () throws -> T) throws -> T {
        let snapshot = store.makeSnapshot()
        do {
            let result = try work()
            if let failure = store.commitFailure {
                store.restore(snapshot)
                throw failure
            }
            return result
        } catch {
            store.restore(snapshot)
            throw error
        }
    }
}
