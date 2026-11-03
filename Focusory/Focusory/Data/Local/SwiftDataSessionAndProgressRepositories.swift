import Foundation
import SwiftData

/// SwiftData 会话查询仓储；只读取已保存会话，不创建会话。
final class SwiftDataSessionRepository: SessionRepository {
    /// 与任务仓储共用的上下文，读取同一次业务操作中的会话数据。
    private let context: ModelContext

    /// 用指定上下文创建仓储。
    init(context: ModelContext) {
        self.context = context
    }

    /// 返回任务累计的已保存会话数。
    func completedSessionCount(taskID: UUID, ownerID: AccountID) throws -> Int {
        try context.fetchCount(descriptor(taskID: taskID, ownerID: ownerID))
    }

    /// 返回任务累计的实际专注秒数。
    func totalFocusDurationSeconds(taskID: UUID, ownerID: AccountID) throws -> Int {
        try context.fetch(descriptor(taskID: taskID, ownerID: ownerID))
            .reduce(0) { $0 + $1.focusDurationSeconds }
    }

    /// 构造按账户与任务过滤的查询描述。
    private func descriptor(taskID: UUID, ownerID: AccountID) -> FetchDescriptor<FocusSessionRecord> {
        let owner = ownerID.rawValue
        let identifier = taskID
        return FetchDescriptor<FocusSessionRecord>(
            predicate: #Predicate { $0.ownerID == owner && $0.taskID == identifier }
        )
    }
}

/// SwiftData 每日进度仓储；同一任务与本机日期唯一。
final class SwiftDataDailyProgressRepository: DailyProgressRepository {
    /// 仓储与事务共用的上下文，让相关写入一起提交或回滚。
    private let context: ModelContext

    /// 用指定上下文创建仓储。
    init(context: ModelContext) {
        self.context = context
    }

    /// 读取任务在指定本机日期的唯一进度。
    func progress(taskID: UUID, ownerID: AccountID, localDate: LocalDate) throws -> TaskDailyProgress? {
        try record(taskID: taskID, ownerID: ownerID, localDate: localDate)?.domainModel
    }

    /// 暂存每日进度，同一任务与日期已存在时更新；由事务统一保存。
    func upsert(_ progress: TaskDailyProgress) throws {
        if let record = try record(
            taskID: progress.taskID,
            ownerID: progress.ownerID,
            localDate: progress.localDate
        ) {
            record.apply(progress)
        } else {
            context.insert(TaskDailyProgressRecord(progress: progress))
        }
    }

    /// 按任务、账户与本机日期读取实体。
    private func record(
        taskID: UUID,
        ownerID: AccountID,
        localDate: LocalDate
    ) throws -> TaskDailyProgressRecord? {
        let owner = ownerID.rawValue
        let identifier = taskID
        let key = localDate.key
        var descriptor = FetchDescriptor<TaskDailyProgressRecord>(
            predicate: #Predicate { $0.ownerID == owner && $0.taskID == identifier && $0.localDateKey == key }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}

/// SwiftData 同步队列仓储；入队不覆盖已有操作标识。
final class SwiftDataSyncQueueRepository: SyncQueueRepository {
    /// 仓储与事务共用的上下文，让相关写入一起提交或回滚。
    private let context: ModelContext

    /// 用指定上下文创建仓储。
    init(context: ModelContext) {
        self.context = context
    }

    /// 追加一个待上传的幂等操作；同一操作标识已存在时不重复入队。
    func enqueue(_ queueItem: SyncQueueItem) throws {
        guard try item(operationID: queueItem.operationID, ownerID: queueItem.ownerID) == nil else { return }
        context.insert(SyncQueueItemRecord(item: queueItem))
    }

    /// 按操作标识查找队列项。
    func item(operationID: UUID, ownerID: AccountID) throws -> SyncQueueItem? {
        let owner = ownerID.rawValue
        let identifier = operationID
        var descriptor = FetchDescriptor<SyncQueueItemRecord>(
            predicate: #Predicate { $0.ownerID == owner && $0.operationID == identifier }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first?.domainModel
    }
}
