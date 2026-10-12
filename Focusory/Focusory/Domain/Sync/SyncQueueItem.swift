import Foundation

/// 同步变更指向的实体类型。
enum SyncEntityType: String, Equatable, Sendable {
    case task
    case taskDailyProgress
    case session
}

/// 同步变更的业务操作类型。
enum SyncOperationType: String, Equatable, Sendable {
    case created
    case updated
    case deleted
    case targetAppended
}

/// 同步队列项状态；只有云端明确确认后才可从本地队列移除。
enum SyncQueueStatus: String, Equatable, Sendable {
    case pending
    case syncing
    case failed
}

/// 本地已成功提交、但云端尚未明确确认的幂等操作。
/// 传输负载由 `Data.Remote` 在 P1 按 `payloadSchemaVersion` 从实体生成，领域层不保存 DTO。
struct SyncQueueItem: Identifiable, Equatable, Sendable {
    /// 幂等操作标识；同一标识重复上传不得重复产生业务结果。
    let operationID: UUID
    /// 队列项标识等于操作标识。
    var id: UUID { operationID }
    /// 所属账户。
    let ownerID: AccountID
    /// 指向的实体类型。
    let entityType: SyncEntityType
    /// 指向的实体标识。
    let entityID: UUID
    /// 业务操作类型。
    let operationType: SyncOperationType
    /// 负载 schema 版本。
    let payloadSchemaVersion: Int
    /// 当前同步状态。
    private(set) var status: SyncQueueStatus
    /// 已尝试上传次数。
    private(set) var attemptCount: Int
    /// 下次可尝试时刻。
    private(set) var nextAttemptAt: Date?
    /// 最近一次失败码。
    private(set) var lastErrorCode: String?
    /// 入队瞬时。
    let createdAt: Date
    /// 最近更新瞬时。
    private(set) var updatedAt: Date

    /// 当前客户端支持的负载 schema 版本。
    static let currentPayloadSchemaVersion = 1

    /// 以等待同步状态创建一个队列项。
    init(
        operationID: UUID,
        ownerID: AccountID,
        entityType: SyncEntityType,
        entityID: UUID,
        operationType: SyncOperationType,
        createdAt: Date,
        payloadSchemaVersion: Int = SyncQueueItem.currentPayloadSchemaVersion
    ) {
        self.operationID = operationID
        self.ownerID = ownerID
        self.entityType = entityType
        self.entityID = entityID
        self.operationType = operationType
        self.payloadSchemaVersion = payloadSchemaVersion
        self.status = .pending
        self.attemptCount = 0
        self.nextAttemptAt = nil
        self.lastErrorCode = nil
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }

    /// 从本地存储还原队列项；仅供仓储映射与测试夹具使用。
    init(
        operationID: UUID,
        ownerID: AccountID,
        entityType: SyncEntityType,
        entityID: UUID,
        operationType: SyncOperationType,
        payloadSchemaVersion: Int,
        status: SyncQueueStatus,
        attemptCount: Int,
        nextAttemptAt: Date?,
        lastErrorCode: String?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.operationID = operationID
        self.ownerID = ownerID
        self.entityType = entityType
        self.entityID = entityID
        self.operationType = operationType
        self.payloadSchemaVersion = payloadSchemaVersion
        self.status = status
        self.attemptCount = attemptCount
        self.nextAttemptAt = nextAttemptAt
        self.lastErrorCode = lastErrorCode
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
