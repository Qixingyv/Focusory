import Foundation

/// 创建或编辑任务时提交的表单数据；由界面提供，不携带账户与生命周期字段。
struct TaskDraft: Equatable, Sendable {
    /// 任务名；校验前允许包含首尾空白。
    var name: String
    /// 待办或持续；编辑时不得改变已有任务的模式。
    var mode: FocusTaskMode
    /// 每轮计划专注时长，单位为分钟。
    var focusDurationMinutes: Int
    /// 每轮计划休息时长，单位为分钟。
    var breakDurationMinutes: Int
    /// 待办总目标；持续任务必须为 nil。
    var todoTarget: Int?
    /// 表示持续任务是否启用计划周期。
    var hasDateRange: Bool
    /// 计划开始日；仅启用计划周期时存在。
    var startDate: LocalDate?
    /// 计划截止日；仅启用计划周期时存在。
    var endDate: LocalDate?
    /// 表示持续任务是否启用每日目标。
    var hasDailyTarget: Bool
    /// 每日基础目标；仅启用每日目标时存在。
    var dailyTarget: Int?

    /// 创建表单草稿；默认使用待办配置，名称等内容仍须通过校验。
    init(
        name: String = "",
        mode: FocusTaskMode = .todo,
        focusDurationMinutes: Int = 25,
        breakDurationMinutes: Int = 5,
        todoTarget: Int? = 1,
        hasDateRange: Bool = false,
        startDate: LocalDate? = nil,
        endDate: LocalDate? = nil,
        hasDailyTarget: Bool = false,
        dailyTarget: Int? = nil
    ) {
        self.name = name
        self.mode = mode
        self.focusDurationMinutes = focusDurationMinutes
        self.breakDurationMinutes = breakDurationMinutes
        self.todoTarget = todoTarget
        self.hasDateRange = hasDateRange
        self.startDate = startDate
        self.endDate = endDate
        self.hasDailyTarget = hasDailyTarget
        self.dailyTarget = dailyTarget
    }

    /// 去除首尾空白和换行后的名称，供必填校验和保存使用。
    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 从已有任务构造一份可编辑草稿。
    init(task: FocusTask) {
        self.init(
            name: task.name,
            mode: task.mode,
            focusDurationMinutes: task.focusDurationMinutes,
            breakDurationMinutes: task.breakDurationMinutes,
            todoTarget: task.todoTarget,
            hasDateRange: task.hasDateRange,
            startDate: task.startDate,
            endDate: task.endDate,
            hasDailyTarget: task.hasDailyTarget,
            dailyTarget: task.dailyTarget
        )
    }
}
