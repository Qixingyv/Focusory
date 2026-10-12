import Foundation
@testable import Focusory

/// 测试用的已保存会话事实；F01 只按任务推导会话数与累计时长。
struct SessionFixture: Equatable {
    /// 会话标识。
    let id: UUID
    /// 所属账户。
    let ownerID: AccountID
    /// 关联任务。
    let taskID: UUID
    /// 实际专注秒数。
    let focusDurationSeconds: Int
}

/// 每日进度的内存键；对应「任务 + 本机日期」唯一约束。
struct DailyProgressKey: Hashable {
    /// 所属账户。
    let ownerID: AccountID
    /// 关联任务。
    let taskID: UUID
    /// 归属的本机日期。
    let localDate: LocalDate
}

/// 内存本地事实集合；供内存仓储读写，并被事务实现整体快照与回滚。
@MainActor
final class InMemoryLocalStore {
    /// 按标识保存任务。
    var tasks: [UUID: FocusTask] = [:]
    /// 已保存会话事实。
    var sessions: [SessionFixture] = []
    /// 按「任务 + 日期」保存每日进度。
    var dailyProgress: [DailyProgressKey: TaskDailyProgress] = [:]
    /// 按操作标识保存同步队列项。
    var syncQueue: [UUID: SyncQueueItem] = [:]
    /// 注入的提交失败；非空时下一次提交整体回滚并抛出它。
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

    /// 当前全部内存事实的完整快照。
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

/// 内存事实的不可变快照。
struct InMemorySnapshot {
    /// 任务快照。
    let tasks: [UUID: FocusTask]
    /// 会话快照。
    let sessions: [SessionFixture]
    /// 每日进度快照。
    let dailyProgress: [DailyProgressKey: TaskDailyProgress]
    /// 同步队列快照。
    let syncQueue: [UUID: SyncQueueItem]
}

/// 内存实时任务仓储。
@MainActor
final class InMemoryTaskRepository: TaskRepository {
    /// 共享内存存储。
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
    /// 共享内存存储。
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
    /// 共享内存存储。
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
    /// 共享内存存储。
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
    /// 共享内存存储。
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
