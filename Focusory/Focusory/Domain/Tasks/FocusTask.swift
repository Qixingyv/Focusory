import Foundation

/// 专注任务，承载待办或持续任务的配置、目标与生命周期。
/// 所有可变字段都通过规则方法修改，`mode` 与终态不可恢复。
struct FocusTask: Identifiable, Equatable, Sendable {
    /// 任务标识。
    let id: UUID
    /// 所属账户。
    let ownerID: AccountID
    /// 任务名。
    private(set) var name: String
    /// 待办或持续；创建后不可转换。
    let mode: FocusTaskMode
    /// 整体状态。
    private(set) var status: FocusTaskStatus
    /// 完成来源；`auto` 由待办按计划完成标记，`manual` 与 `completed` 配套。
    private(set) var completionSource: TaskCompletionSource?
    /// 计划专注分钟数。
    private(set) var focusDurationMinutes: Int
    /// 计划休息分钟数。
    private(set) var breakDurationMinutes: Int
    /// 待办总目标；持续任务为 nil。
    private(set) var todoTarget: Int?
    /// 是否启用计划周期。
    private(set) var hasDateRange: Bool
    /// 计划开始日。
    private(set) var startDate: LocalDate?
    /// 计划截止日。
    private(set) var endDate: LocalDate?
    /// 是否启用每日目标。
    private(set) var hasDailyTarget: Bool
    /// 每日基础目标。
    private(set) var dailyTarget: Int?
    /// 创建瞬时。
    let createdAt: Date
    /// 最近更新瞬时。
    private(set) var updatedAt: Date
    /// 手动最终完成瞬时。
    private(set) var completedAt: Date?
    /// 放弃瞬时。
    private(set) var abandonedAt: Date?
    /// 服务端版本号；每次业务修改递增，用于增量同步与冲突检测。
    private(set) var version: Int

    /// 校验草稿并创建进行中任务。
    /// - 失败：字段校验不通过时抛 `TaskFailure`，不产生任何数据。
    static func create(
        draft: TaskDraft,
        ownerID: AccountID,
        today: LocalDate,
        now: Date
    ) throws -> FocusTask {
        let configuration = try TaskConfigurationValidator.validate(
            draft,
            mode: draft.mode,
            today: today,
            previous: nil,
            hasHistory: false
        )
        return FocusTask(configuration: configuration, ownerID: ownerID, now: now)
    }

    /// 从本地存储还原已校验的字段；仅供仓储映射与测试夹具使用，不做规则校验。
    init(
        id: UUID,
        ownerID: AccountID,
        name: String,
        mode: FocusTaskMode,
        status: FocusTaskStatus,
        completionSource: TaskCompletionSource? = nil,
        focusDurationMinutes: Int,
        breakDurationMinutes: Int,
        todoTarget: Int? = nil,
        hasDateRange: Bool = false,
        startDate: LocalDate? = nil,
        endDate: LocalDate? = nil,
        hasDailyTarget: Bool = false,
        dailyTarget: Int? = nil,
        createdAt: Date,
        updatedAt: Date,
        completedAt: Date? = nil,
        abandonedAt: Date? = nil,
        version: Int
    ) {
        self.id = id
        self.ownerID = ownerID
        self.name = name
        self.mode = mode
        self.status = status
        self.completionSource = completionSource
        self.focusDurationMinutes = focusDurationMinutes
        self.breakDurationMinutes = breakDurationMinutes
        self.todoTarget = todoTarget
        self.hasDateRange = hasDateRange
        self.startDate = startDate
        self.endDate = endDate
        self.hasDailyTarget = hasDailyTarget
        self.dailyTarget = dailyTarget
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.abandonedAt = abandonedAt
        self.version = version
    }

    /// 以已校验配置创建新任务。
    private init(configuration: ValidatedTaskConfiguration, ownerID: AccountID, now: Date) {
        self.init(
            id: UUID(),
            ownerID: ownerID,
            name: configuration.name,
            mode: configuration.mode,
            status: .active,
            completionSource: nil,
            focusDurationMinutes: configuration.focusDurationMinutes,
            breakDurationMinutes: configuration.breakDurationMinutes,
            todoTarget: configuration.todoTarget,
            hasDateRange: configuration.hasDateRange,
            startDate: configuration.startDate,
            endDate: configuration.endDate,
            hasDailyTarget: configuration.hasDailyTarget,
            dailyTarget: configuration.dailyTarget,
            createdAt: now,
            updatedAt: now,
            completedAt: nil,
            abandonedAt: nil,
            version: 1
        )
    }

    /// 当前配置的规范化视图，用于编辑时比较开关与开始日是否变化。
    var validatedConfiguration: ValidatedTaskConfiguration {
        ValidatedTaskConfiguration(
            name: name,
            mode: mode,
            focusDurationMinutes: focusDurationMinutes,
            breakDurationMinutes: breakDurationMinutes,
            todoTarget: todoTarget,
            hasDateRange: hasDateRange,
            startDate: startDate,
            endDate: endDate,
            hasDailyTarget: hasDailyTarget,
            dailyTarget: dailyTarget
        )
    }

    /// 是否为可开始会话的进行中任务。
    var isActive: Bool {
        status == .active
    }

    /// 用草稿更新可编辑字段；模式、终态与已产生会话后的配置开关不可改。
    /// - 失败：终态任务、非法字段或非法开关切换时抛 `TaskFailure`。
    mutating func apply(
        _ draft: TaskDraft,
        today: LocalDate,
        hasHistory: Bool,
        now: Date
    ) throws {
        guard isActive else {
            throw TaskFailure(.taskNotActive)
        }

        let configuration = try TaskConfigurationValidator.validate(
            draft,
            mode: mode,
            today: today,
            previous: validatedConfiguration,
            hasHistory: hasHistory
        )

        name = configuration.name
        focusDurationMinutes = configuration.focusDurationMinutes
        breakDurationMinutes = configuration.breakDurationMinutes
        todoTarget = configuration.todoTarget
        hasDateRange = configuration.hasDateRange
        startDate = configuration.startDate
        endDate = configuration.endDate
        hasDailyTarget = configuration.hasDailyTarget
        dailyTarget = configuration.dailyTarget
        updatedAt = now
        version += 1
    }

    /// 取出本轮开始时固化的配置。
    func runConfiguration() -> TaskRunConfiguration {
        TaskRunConfiguration(
            taskID: id,
            taskName: name,
            mode: mode,
            focusDurationMinutes: focusDurationMinutes,
            breakDurationMinutes: breakDurationMinutes
        )
    }

    /// 判断给定本机日期是否可以开始新一轮专注。
    func decideStart(today: LocalDate) -> StartDecision {
        guard isActive else {
            return .rejected(TaskFailure(.taskNotActive))
        }
        if mode == .ongoing, hasDateRange, let startDate, today < startDate {
            return .notYetStarted(startDate)
        }
        return .allowed(runConfiguration())
    }

    /// 追加待办总目标并重新计算目标反馈。
    /// - 失败：数量非正、任务非进行中、不是待办或尚未按计划完成时抛 `TaskFailure`。
    mutating func appendTodoTarget(
        _ quantity: Int,
        completedPomodoroCount: Int,
        now: Date
    ) throws -> GoalAdjustmentResult {
        guard quantity >= 1 else {
            throw TaskFailure(.appendQuantityOutOfRange, field: .todoTarget)
        }
        guard isActive else {
            throw TaskFailure(.taskNotActive)
        }
        guard mode == .todo, let currentTarget = todoTarget else {
            throw TaskFailure(.appendNotAllowed)
        }
        guard completedPomodoroCount >= currentTarget else {
            throw TaskFailure(.appendNotAllowed)
        }

        let newTarget = currentTarget + quantity
        todoTarget = newTarget
        completionSource = completedPomodoroCount >= newTarget ? .auto : nil
        updatedAt = now
        version += 1

        return GoalAdjustmentResult(
            previousTarget: currentTarget,
            newTarget: newTarget,
            completedPomodoroCount: completedPomodoroCount,
            isReplay: false
        )
    }

    /// 按完成数推导目标反馈。
    func goalFeedback(completedPomodoroCount: Int) -> TaskGoalFeedback {
        switch mode {
        case .todo:
            return TaskGoalFeedback.resolve(
                completedPomodoroCount: completedPomodoroCount,
                effectiveTarget: todoTarget
            )
        case .ongoing:
            return .inProgress
        }
    }

    /// 手动最终完成；进入不可恢复的终态。
    /// - 失败：终态、非进行中或正被计时锁定时抛 `TaskFailure`。
    mutating func complete(now: Date, isLockedByTimer: Bool) throws {
        guard isActive else {
            throw TaskFailure(.taskNotActive)
        }
        guard !isLockedByTimer else {
            throw TaskFailure(.taskLockedByTimer)
        }
        status = .completed
        completionSource = .manual
        completedAt = now
        updatedAt = now
        version += 1
    }

    /// 放弃任务并保留历史会话与统计。
    /// - 失败：终态、非进行中或正被计时锁定时抛 `TaskFailure`。
    mutating func abandon(now: Date, isLockedByTimer: Bool) throws {
        guard isActive else {
            throw TaskFailure(.taskNotActive)
        }
        guard !isLockedByTimer else {
            throw TaskFailure(.taskLockedByTimer)
        }
        status = .abandoned
        abandonedAt = now
        updatedAt = now
        version += 1
    }

    /// 该任务在给定状态下的排序时刻；终态缺少时刻时退回更新时刻。
    func lifecycleInstant(for status: FocusTaskStatus) -> Date {
        switch status {
        case .active: createdAt
        case .completed: completedAt ?? updatedAt
        case .abandoned: abandonedAt ?? updatedAt
        }
    }
}
