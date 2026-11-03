import Foundation
import SwiftData

/// SwiftData 同步队列实体；只有服务端明确确认后才可删除队列项。
@Model
final class SyncQueueItemRecord {
    /// 保证操作标识唯一，重复入队不得产生第二条待上传操作。
    #Unique<SyncQueueItemRecord>([\.operationID])

    /// 幂等操作标识。
    var operationID: UUID = UUID()
    /// 数据所属的账户，用于限定查询和写入范围。
    var ownerID: UUID = UUID()
    /// 以字符串保存变更对象的类型，供上传时选择对应数据。
    var entityTypeRawValue: String = SyncEntityType.task.rawValue
    /// 发生变更的业务对象标识，供上传时查找数据。
    var entityID: UUID = UUID()
    /// 以字符串保存创建、更新、删除或追加目标等操作类型。
    var operationTypeRawValue: String = SyncOperationType.updated.rawValue
    /// 同步数据的格式版本，供上传时选择对应格式。
    var payloadSchemaVersion: Int = SyncQueueItem.currentPayloadSchemaVersion
    /// 以字符串保存当前上传状态。
    var statusRawValue: String = SyncQueueStatus.pending.rawValue
    /// 已尝试上传的次数，供重试策略使用。
    var attemptCount: Int = 0
    /// 下次允许重试上传的时刻；为空表示未设置。
    var nextAttemptAt: Date?
    /// 最近一次上传失败的错误码；尚未记录失败时为空。
    var lastErrorCode: String?
    /// 加入同步队列的时刻。
    var createdAt: Date = Date()
    /// 最近修改时刻。
    var updatedAt: Date = Date()

    /// 以领域对象创建实体。
    init(item: SyncQueueItem) {
        operationID = item.operationID
        ownerID = item.ownerID.rawValue
        entityTypeRawValue = item.entityType.rawValue
        entityID = item.entityID
        operationTypeRawValue = item.operationType.rawValue
        payloadSchemaVersion = item.payloadSchemaVersion
        statusRawValue = item.status.rawValue
        attemptCount = item.attemptCount
        nextAttemptAt = item.nextAttemptAt
        lastErrorCode = item.lastErrorCode
        createdAt = item.createdAt
        updatedAt = item.updatedAt
    }
}

extension SyncQueueItemRecord {
    /// 供仓储读取的队列项；类型、操作或状态无法识别时返回 nil。
    var domainModel: SyncQueueItem? {
        guard let entityType = SyncEntityType(rawValue: entityTypeRawValue),
              let operationType = SyncOperationType(rawValue: operationTypeRawValue),
              let status = SyncQueueStatus(rawValue: statusRawValue) else {
            return nil
        }
        return SyncQueueItem(
            operationID: operationID,
            ownerID: AccountID(rawValue: ownerID),
            entityType: entityType,
            entityID: entityID,
            operationType: operationType,
            payloadSchemaVersion: payloadSchemaVersion,
            status: status,
            attemptCount: attemptCount,
            nextAttemptAt: nextAttemptAt,
            lastErrorCode: lastErrorCode,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
