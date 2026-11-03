import Foundation

/// 任务创建与编辑允许的取值边界。
enum TaskRules {
    /// 专注时长下限（分钟）。
    static let minimumFocusDurationMinutes = 5
    /// 专注时长上限（分钟）。
    static let maximumFocusDurationMinutes = 120
    /// 专注时长步长（分钟）。
    static let focusDurationStepMinutes = 5
    /// 休息时长下限（分钟）。
    static let minimumBreakDurationMinutes = 1
    /// 休息时长上限（分钟）。
    static let maximumBreakDurationMinutes = 60

    /// 判断专注时长是否满足范围与步长要求。
    static func isValidFocusDuration(_ minutes: Int) -> Bool {
        guard (minimumFocusDurationMinutes...maximumFocusDurationMinutes).contains(minutes) else {
            return false
        }
        return minutes % focusDurationStepMinutes == 0
    }

    /// 判断休息时长是否满足范围要求。
    static func isValidBreakDuration(_ minutes: Int) -> Bool {
        (minimumBreakDurationMinutes...maximumBreakDurationMinutes).contains(minutes)
    }
}

/// 目标反馈子状态；不是任务整体状态，也不构成继续专注的门禁。
enum TaskGoalFeedback: Equatable, Sendable {
    case inProgress
    case goalMet

    /// 根据完成数与有效目标推导反馈。
    static func resolve(completedPomodoroCount: Int, effectiveTarget: Int?) -> TaskGoalFeedback {
        guard let effectiveTarget else { return .inProgress }
        return completedPomodoroCount >= effectiveTarget ? .goalMet : .inProgress
    }
}

/// 一次目标追加的业务结果；不修改会话、完成数或统计。
struct GoalAdjustmentResult: Equatable, Sendable {
    /// 追加前的有效目标。
    let previousTarget: Int
    /// 追加后的有效目标。
    let newTarget: Int
    /// 当前完成番茄数。
    let completedPomodoroCount: Int
    /// 表示本次提交是同一操作标识的重放，未再次修改目标。
    let isReplay: Bool

    /// 按新目标判断是否仍然达标，供界面更新反馈。
    var feedback: TaskGoalFeedback {
        TaskGoalFeedback.resolve(completedPomodoroCount: completedPomodoroCount, effectiveTarget: newTarget)
    }
}

/// 一轮专注开始时固化的配置；本轮内不被任务编辑改写。
struct TaskRunConfiguration: Equatable, Sendable {
    /// 本轮专注关联的任务标识，供计时服务识别任务。
    let taskID: UUID
    /// 开始时的任务名。
    let taskName: String
    /// 任务模式。
    let mode: FocusTaskMode
    /// 本轮计划专注分钟数。
    let focusDurationMinutes: Int
    /// 本轮计划休息分钟数。
    let breakDurationMinutes: Int
}

/// 开始专注前的业务判定，说明允许开始、拒绝原因或尚未到开始日。
enum StartDecision: Equatable, Sendable {
    /// 可以开始，并携带固化的本轮配置。
    case allowed(TaskRunConfiguration)
    /// 不可开始及原因。
    case rejected(TaskFailure)
    /// 持续任务尚未到计划开始日。
    case notYetStarted(LocalDate)
}

/// 开始专注命令的结果。
enum StartFocusOutcome: Equatable, Sendable {
    /// 计时已启动。
    case started
    /// 未启动及原因。
    case rejected(TaskFailure)
    /// 尚未到计划开始日。
    case notYetStarted(LocalDate)
}
