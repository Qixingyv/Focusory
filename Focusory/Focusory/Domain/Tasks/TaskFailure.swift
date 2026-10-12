import Foundation

/// 任务表单字段；用于把校验错误定位到具体输入项。
enum TaskFormField: String, Equatable, Sendable {
    case name
    case focusDuration
    case breakDuration
    case todoTarget
    case dailyTarget
    case dateRange
}

/// 稳定的任务失败码；界面按它选择文案，不解析错误文本。
enum TaskFailureCode: String, Equatable, Sendable {
    // 表单校验
    case nameRequired
    case focusDurationOutOfRange
    case breakDurationOutOfRange
    case todoTargetOutOfRange
    case dailyTargetOutOfRange
    case startDateBeforeToday
    case endDateBeforeStartDate
    case modeConfigurationMismatch
    case configurationLockedByHistory
    // 命令
    case taskUnavailable
    case taskNotActive
    case taskLockedByTimer
    case taskHasHistory
    case appendQuantityOutOfRange
    case appendNotAllowed
    case localDateChanged
    case persistenceFailed
}

/// 字段化的任务失败结果；调用方按 `code` 分支，按 `field` 定位输入项。
struct TaskFailure: Error, Equatable, Sendable {
    /// 稳定失败码。
    let code: TaskFailureCode
    /// 表单校验失败时对应的字段；命令失败时为 nil。
    let field: TaskFormField?

    /// 创建任务失败结果。
    init(_ code: TaskFailureCode, field: TaskFormField? = nil) {
        self.code = code
        self.field = field
    }
}
