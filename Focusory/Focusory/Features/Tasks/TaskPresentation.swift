import Foundation

extension FocusTaskMode {
    /// 任务模式的本地化名称。
    var localizedTitle: LocalizedStringResource {
        switch self {
        case .todo: .tasksModeTodo
        case .ongoing: .tasksModeOngoing
        }
    }
}

extension FocusTaskStatus {
    /// 任务状态的本地化名称。
    var localizedTitle: LocalizedStringResource {
        switch self {
        case .active: .tasksStatusActive
        case .completed: .tasksStatusCompleted
        case .abandoned: .tasksStatusAbandoned
        }
    }
}

extension TaskFormField {
    /// 字段的本地化标签；用于把校验错误放在对应输入项旁。
    var localizedLabel: LocalizedStringResource {
        switch self {
        case .name: .tasksEditorNameLabel
        case .focusDuration: .tasksEditorFocusDurationLabel
        case .breakDuration: .tasksEditorBreakDurationLabel
        case .todoTarget: .tasksEditorTodoTargetLabel
        case .dailyTarget: .tasksEditorDailyTargetLabel
        case .dateRange: .tasksEditorDateRangeToggleTitle
        }
    }
}

extension TaskFailureCode {
    /// 失败码对应的用户可见文案；界面不解析错误文本。
    var localizedMessage: LocalizedStringResource {
        switch self {
        case .nameRequired: .tasksFailureNameRequired
        case .focusDurationOutOfRange: .tasksFailureFocusDurationOutOfRange
        case .breakDurationOutOfRange: .tasksFailureBreakDurationOutOfRange
        case .todoTargetOutOfRange: .tasksFailureTodoTargetOutOfRange
        case .dailyTargetOutOfRange: .tasksFailureDailyTargetOutOfRange
        case .startDateBeforeToday: .tasksFailureStartDateBeforeToday
        case .endDateBeforeStartDate: .tasksFailureEndDateBeforeStartDate
        case .modeConfigurationMismatch: .tasksFailureModeConfigurationMismatch
        case .configurationLockedByHistory: .tasksFailureConfigurationLockedByHistory
        case .taskUnavailable: .tasksFailureTaskUnavailable
        case .taskNotActive: .tasksFailureTaskNotActive
        case .taskLockedByTimer: .tasksFailureTaskLockedByTimer
        case .taskHasHistory: .tasksFailureTaskHasHistory
        case .appendQuantityOutOfRange: .tasksFailureAppendQuantityOutOfRange
        case .appendNotAllowed: .tasksFailureAppendNotAllowed
        case .localDateChanged: .tasksFailureLocalDateChanged
        case .persistenceFailed: .tasksFailurePersistenceFailed
        }
    }
}

extension TaskNotice {
    /// 提示对应的用户可见文案。
    var localizedMessage: LocalizedStringResource {
        switch self {
        case .failure(let failure): failure.code.localizedMessage
        case .notYetStarted(let startDate): .tasksFailureNotYetStarted(startDate.localizedDisplayText)
        }
    }
}

extension LocalDate {
    /// 界面展示用的本地化日期文案；按 UTC 格式化以避免展示时再次偏移一天。
    var localizedDisplayText: String {
        guard let instant = startInstant(in: TimeZone(secondsFromGMT: 0) ?? .gmt) else {
            return key
        }
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: instant)
    }
}
