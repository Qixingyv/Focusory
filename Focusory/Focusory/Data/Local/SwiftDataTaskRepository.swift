import Foundation
import SwiftData

/// SwiftData 任务仓储；所有查询与写入都按 `ownerID` 限定账户范围。
final class SwiftDataTaskRepository: TaskRepository {
    /// 仓储与事务共用的上下文，让相关写入一起提交或回滚。
    private let context: ModelContext

    /// 用指定上下文创建仓储。
    init(context: ModelContext) {
        self.context = context
    }

    /// 返回账户内指定状态的任务。
    /// - 失败：查询错误原样抛出；模式或状态无法识别时抛 `TaskFailure(.persistenceFailed)`。
    func tasks(ownerID: AccountID, status: FocusTaskStatus) throws -> [FocusTask] {
        let owner = ownerID.rawValue
        let rawStatus = status.rawValue
        let descriptor = FetchDescriptor<FocusTaskRecord>(
            predicate: #Predicate { $0.ownerID == owner && $0.statusRawValue == rawStatus }
        )
        let records = try context.fetch(descriptor)
        return try records.map { record in
            guard let task = record.domainModel else {
                throw TaskFailure(.persistenceFailed)
            }
            return task
        }
    }

    /// 返回账户内的单个任务；不存在或不属于该账户时返回 nil。
    func task(id: UUID, ownerID: AccountID) throws -> FocusTask? {
        try record(id: id, ownerID: ownerID)?.domainModel
    }

    /// 统计账户内三个整体状态的任务数量。
    func counts(ownerID: AccountID) throws -> TaskStatusCounts {
        TaskStatusCounts(
            active: try count(ownerID: ownerID, status: .active),
            completed: try count(ownerID: ownerID, status: .completed),
            abandoned: try count(ownerID: ownerID, status: .abandoned)
        )
    }

    /// 暂存任务新增或更新，由事务统一保存到数据库。
    func upsert(_ task: FocusTask) throws {
        if let record = try record(id: task.id, ownerID: task.ownerID) {
            record.apply(task)
        } else {
            context.insert(FocusTaskRecord(task: task))
        }
    }

    /// 暂存指定账户内的任务删除，由事务统一保存。
    func delete(id: UUID, ownerID: AccountID) throws {
        guard let record = try record(id: id, ownerID: ownerID) else { return }
        context.delete(record)
    }

    /// 按标识与账户读取实体。
    private func record(id: UUID, ownerID: AccountID) throws -> FocusTaskRecord? {
        let owner = ownerID.rawValue
        let identifier = id
        var descriptor = FetchDescriptor<FocusTaskRecord>(
            predicate: #Predicate { $0.ownerID == owner && $0.id == identifier }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// 统计账户内指定状态的任务数量。
    private func count(ownerID: AccountID, status: FocusTaskStatus) throws -> Int {
        let owner = ownerID.rawValue
        let rawStatus = status.rawValue
        let descriptor = FetchDescriptor<FocusTaskRecord>(
            predicate: #Predicate { $0.ownerID == owner && $0.statusRawValue == rawStatus }
        )
        return try context.fetchCount(descriptor)
    }
}
