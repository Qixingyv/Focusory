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
    /// 沿用操作标识，让同一同步操作保持同一个身份。
    var id: UUID { operationID }
    /// 数据所属的账户，用于隔离不同账户的数据。
    let ownerID: AccountID
    /// 变更对应的数据类型，决定上传哪类业务数据。
    let entityType: SyncEntityType
    /// 发生变更的业务对象标识，用于找到待上传数据。
    let entityID: UUID
    /// 本次变更是创建、更新、删除还是追加目标。
    let operationType: SyncOperationType
    /// 同步数据的格式版本，供上传时选择对应格式。
    let payloadSchemaVersion: Int
    /// 当前上传状态，供同步流程判断下一步操作。
    private(set) var status: SyncQueueStatus
    /// 已尝试上传的次数，供重试策略使用。
    private(set) var attemptCount: Int
    /// 下次允许重试上传的时刻；为空表示未设置。
    private(set) var nextAttemptAt: Date?
    /// 最近一次上传失败的错误码；尚未记录失败时为空。
    private(set) var lastErrorCode: String?
    /// 加入同步队列的时刻。
    let createdAt: Date
    /// 最近修改时刻。
    private(set) var updatedAt: Date

    /// 当前创建的队列项使用的同步数据格式版本。
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
