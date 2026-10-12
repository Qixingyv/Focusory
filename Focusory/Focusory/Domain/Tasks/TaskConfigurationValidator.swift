import Foundation

/// 已通过校验的任务配置；只能由 `TaskConfigurationValidator` 产出。
struct ValidatedTaskConfiguration: Equatable, Sendable {
    /// 规范化后的任务名。
    let name: String
    /// 任务模式。
    let mode: FocusTaskMode
    /// 计划专注分钟数。
    let focusDurationMinutes: Int
    /// 计划休息分钟数。
    let breakDurationMinutes: Int
    /// 待办总目标；持续任务为 nil。
    let todoTarget: Int?
    /// 是否启用计划周期。
    let hasDateRange: Bool
    /// 计划开始日。
    let startDate: LocalDate?
    /// 计划截止日。
    let endDate: LocalDate?
    /// 是否启用每日目标。
    let hasDailyTarget: Bool
    /// 每日基础目标。
    let dailyTarget: Int?
}

/// 校验任务草稿并产出规范化配置；失败返回字段化错误。
enum TaskConfigurationValidator {
    /// 校验草稿；`mode` 是既有任务的固定模式，`previous` 为空表示新建。
    /// - 失败：名称为空、时长或目标越界、日期非法、已产生会话后切换配置开关时抛 `TaskFailure`。
    static func validate(
        _ draft: TaskDraft,
        mode: FocusTaskMode,
        today: LocalDate,
        previous: ValidatedTaskConfiguration?,
        hasHistory: Bool
    ) throws -> ValidatedTaskConfiguration {
        guard draft.mode == mode else {
            throw TaskFailure(.modeConfigurationMismatch, field: .dateRange)
        }

        let trimmedName = draft.trimmedName
        guard !trimmedName.isEmpty else {
            throw TaskFailure(.nameRequired, field: .name)
        }
        guard TaskRules.isValidFocusDuration(draft.focusDurationMinutes) else {
            throw TaskFailure(.focusDurationOutOfRange, field: .focusDuration)
        }
        guard TaskRules.isValidBreakDuration(draft.breakDurationMinutes) else {
            throw TaskFailure(.breakDurationOutOfRange, field: .breakDuration)
        }

        switch mode {
        case .todo:
            guard let todoTarget = draft.todoTarget, todoTarget >= 1 else {
                throw TaskFailure(.todoTargetOutOfRange, field: .todoTarget)
            }
            return ValidatedTaskConfiguration(
                name: trimmedName,
                mode: .todo,
                focusDurationMinutes: draft.focusDurationMinutes,
                breakDurationMinutes: draft.breakDurationMinutes,
                todoTarget: todoTarget,
                hasDateRange: false,
                startDate: nil,
                endDate: nil,
                hasDailyTarget: false,
                dailyTarget: nil
            )

        case .ongoing:
            return try validateOngoing(
                draft,
                today: today,
                previous: previous,
                hasHistory: hasHistory,
                trimmedName: trimmedName
            )
        }
    }

    /// 校验持续任务的计划周期与每日目标组合。
    private static func validateOngoing(
        _ draft: TaskDraft,
        today: LocalDate,
        previous: ValidatedTaskConfiguration?,
        hasHistory: Bool,
        trimmedName: String
    ) throws -> ValidatedTaskConfiguration {
        // 产生会话后两个配置开关不得再切换，否则历史快照与未来配置会互相矛盾。
        if let previous, hasHistory,
           previous.hasDateRange != draft.hasDateRange || previous.hasDailyTarget != draft.hasDailyTarget {
            throw TaskFailure(.configurationLockedByHistory, field: .dateRange)
        }

        var resolvedStartDate: LocalDate?
        var resolvedEndDate: LocalDate?
        if draft.hasDateRange {
            guard let startDate = draft.startDate, let endDate = draft.endDate else {
                throw TaskFailure(.modeConfigurationMismatch, field: .dateRange)
            }
            let isStartDateUnchanged = previous?.hasDateRange == true && previous?.startDate == startDate
            // 只有新建或改动开始日时才要求不早于今日，避免历史计划周期被锁死无法编辑其他字段。
            if !isStartDateUnchanged, startDate < today {
                throw TaskFailure(.startDateBeforeToday, field: .dateRange)
            }
            guard endDate >= startDate else {
                throw TaskFailure(.endDateBeforeStartDate, field: .dateRange)
            }
            resolvedStartDate = startDate
            resolvedEndDate = endDate
        }

        var resolvedDailyTarget: Int?
        if draft.hasDailyTarget {
            guard let dailyTarget = draft.dailyTarget, dailyTarget >= 1 else {
                throw TaskFailure(.dailyTargetOutOfRange, field: .dailyTarget)
            }
            resolvedDailyTarget = dailyTarget
        }

        return ValidatedTaskConfiguration(
            name: trimmedName,
            mode: .ongoing,
            focusDurationMinutes: draft.focusDurationMinutes,
            breakDurationMinutes: draft.breakDurationMinutes,
            todoTarget: nil,
            hasDateRange: draft.hasDateRange,
            startDate: resolvedStartDate,
            endDate: resolvedEndDate,
            hasDailyTarget: draft.hasDailyTarget,
            dailyTarget: resolvedDailyTarget
        )
    }
}
