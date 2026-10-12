import Foundation
import SwiftData

/// SwiftData 同步队列实体；只有服务端明确确认后才可删除队列项。
@Model
final class SyncQueueItemRecord {
    /// 保证操作标识唯一，重复入队不得产生第二条待上传操作。
    #Unique<SyncQueueItemRecord>([\.operationID])

    /// 幂等操作标识。
    var operationID: UUID = UUID()
    /// 所属账户标识。
    var ownerID: UUID = UUID()
    /// 实体类型原始值。
    var entityTypeRawValue: String = SyncEntityType.task.rawValue
    /// 实体标识。
    var entityID: UUID = UUID()
    /// 操作类型原始值。
    var operationTypeRawValue: String = SyncOperationType.updated.rawValue
    /// 负载 schema 版本。
    var payloadSchemaVersion: Int = SyncQueueItem.currentPayloadSchemaVersion
    /// 同步状态原始值。
    var statusRawValue: String = SyncQueueStatus.pending.rawValue
    /// 已尝试上传次数。
    var attemptCount: Int = 0
    /// 下次可尝试瞬时。
    var nextAttemptAt: Date?
    /// 最近失败码。
    var lastErrorCode: String?
    /// 入队瞬时。
    var createdAt: Date = Date()
    /// 最近更新瞬时。
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
    /// 还原为领域对象；原始值非法时返回 nil。
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
