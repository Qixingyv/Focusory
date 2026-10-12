import Foundation

/// 任务仓储契约；所有查询与写入都必须带 `ownerID` 以强制账户隔离。
protocol TaskRepository {
    /// 返回账户内指定状态的任务。
    func tasks(ownerID: AccountID, status: FocusTaskStatus) throws -> [FocusTask]
    /// 返回账户内的单个任务；不存在或不属于该账户时返回 nil。
    func task(id: UUID, ownerID: AccountID) throws -> FocusTask?
    /// 统计账户内三个整体状态的任务数量。
    func counts(ownerID: AccountID) throws -> TaskStatusCounts
    /// 保存任务；同一标识已存在时覆盖。
    func upsert(_ task: FocusTask) throws
    /// 删除任务；无历史任务的删除由调用方保证。
    func delete(id: UUID, ownerID: AccountID) throws
}

/// 专注会话查询契约；任务进度与历史存在性都从已保存会话推导。
protocol SessionRepository {
    /// 返回任务累计的已保存会话数。
    func completedSessionCount(taskID: UUID, ownerID: AccountID) throws -> Int
    /// 返回任务累计的实际专注秒数。
    func totalFocusDurationSeconds(taskID: UUID, ownerID: AccountID) throws -> Int
}

/// 每日进度仓储契约；同一任务与本机日期最多一条记录。
protocol DailyProgressRepository {
    /// 读取任务在指定本机日期的唯一进度。
    func progress(taskID: UUID, ownerID: AccountID, localDate: LocalDate) throws -> TaskDailyProgress?
    /// 保存每日进度；同一任务与日期已存在时覆盖。
    func upsert(_ progress: TaskDailyProgress) throws
}

/// 同步队列仓储契约；队列项必须与业务写入在同一个本地事务中落盘。
protocol SyncQueueRepository {
    /// 追加一个待上传的幂等操作。
    func enqueue(_ item: SyncQueueItem) throws
    /// 按操作标识查找队列项，用于识别同一操作的重复提交。
    func item(operationID: UUID, ownerID: AccountID) throws -> SyncQueueItem?
}
