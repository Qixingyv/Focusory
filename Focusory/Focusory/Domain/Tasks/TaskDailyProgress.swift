import Foundation

/// 开启每日目标的持续任务在某个本机日期的目标快照与真实投入。
/// 同一任务与本机日期最多一条；有效目标等于目标快照加当日追加数。
struct TaskDailyProgress: Identifiable, Equatable, Sendable {
    /// 每日进度标识。
    let id: UUID
    /// 数据所属的账户，用于隔离不同账户的数据。
    let ownerID: AccountID
    /// 关联的持续任务。
    let taskID: UUID
    /// 这条进度归属的本机日期，用于区分同一任务不同天的投入。
    let localDate: LocalDate
    /// 建立快照时的 IANA 时区。
    let timeZoneID: TimeZoneID
    /// 当日目标快照；后续修改每日基础目标不覆盖它。
    let targetSnapshot: Int
    /// 当日追加数量。
    private(set) var addedTargetCount: Int
    /// 当日已完成番茄数。
    private(set) var completedPomodoroCount: Int
    /// 当日实际专注秒数。
    private(set) var focusDurationSeconds: Int
    /// 创建时刻。
    let createdAt: Date
    /// 最近修改时刻。
    private(set) var updatedAt: Date
    /// 每次进度修改递增的版本，用于识别数据变化。
    private(set) var version: Int

    /// 当日基础目标快照加追加数量，用于判断是否达标。
    var effectiveTarget: Int {
        targetSnapshot + addedTargetCount
    }

    /// 今日是否达标；超过目标仍为达标，不产生独立状态。
    var isMet: Bool {
        completedPomodoroCount >= effectiveTarget
    }

    /// 为某个本机日期建立目标快照。
    /// - 失败：快照目标不是正整数时抛 `TaskFailure`。
    static func create(
        ownerID: AccountID,
        taskID: UUID,
        localDate: LocalDate,
        timeZoneID: TimeZoneID,
        targetSnapshot: Int,
        now: Date
    ) throws -> TaskDailyProgress {
        guard targetSnapshot >= 1 else {
            throw TaskFailure(.dailyTargetOutOfRange, field: .dailyTarget)
        }
        return TaskDailyProgress(
            id: UUID(),
            ownerID: ownerID,
            taskID: taskID,
            localDate: localDate,
            timeZoneID: timeZoneID,
            targetSnapshot: targetSnapshot,
            addedTargetCount: 0,
            completedPomodoroCount: 0,
            focusDurationSeconds: 0,
            createdAt: now,
            updatedAt: now,
            version: 1
        )
    }

    /// 从本地存储还原已校验的每日进度；仅供仓储映射与测试夹具使用。
    init(
        id: UUID,
        ownerID: AccountID,
        taskID: UUID,
        localDate: LocalDate,
        timeZoneID: TimeZoneID,
        targetSnapshot: Int,
        addedTargetCount: Int,
        completedPomodoroCount: Int,
        focusDurationSeconds: Int,
        createdAt: Date,
        updatedAt: Date,
        version: Int
    ) {
        self.id = id
        self.ownerID = ownerID
        self.taskID = taskID
        self.localDate = localDate
        self.timeZoneID = timeZoneID
        self.targetSnapshot = targetSnapshot
        self.addedTargetCount = addedTargetCount
        self.completedPomodoroCount = completedPomodoroCount
        self.focusDurationSeconds = focusDurationSeconds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.version = version
    }

    /// 追加当日目标并重新计算达标反馈。
    /// - 失败：数量非正或今日尚未达标时抛 `TaskFailure`。
    mutating func appendTarget(_ quantity: Int, now: Date) throws -> GoalAdjustmentResult {
        guard quantity >= 1 else {
            throw TaskFailure(.appendQuantityOutOfRange, field: .dailyTarget)
        }
        guard isMet else {
            throw TaskFailure(.appendNotAllowed)
        }

        let previousEffectiveTarget = effectiveTarget
        addedTargetCount += quantity
        updatedAt = now
        version += 1

        return GoalAdjustmentResult(
            previousTarget: previousEffectiveTarget,
            newTarget: effectiveTarget,
            completedPomodoroCount: completedPomodoroCount,
            isReplay: false
        )
    }

    /// 记入一条已保存会话的完成数与实际专注时长；非正时长不改变数据。
    mutating func recordCompletedSession(focusDurationSeconds: Int, now: Date) {
        guard focusDurationSeconds > 0 else { return }
        completedPomodoroCount += 1
        self.focusDurationSeconds += focusDurationSeconds
        updatedAt = now
        version += 1
    }
}
