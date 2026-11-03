import Foundation

/// 供任务卡片显示的任务和进度数据；不包含本地化文案。
struct TaskListItem: Identifiable, Equatable, Sendable {
    /// 列表项对应的任务，提供名称、配置和整体状态。
    let task: FocusTask
    /// 累计完成番茄数。
    let completedPomodoroCount: Int
    /// 累计实际专注秒数。
    let totalFocusDurationSeconds: Int
    /// 当前有效目标；待办总目标或持续任务当日有效目标。
    let effectiveTarget: Int?
    /// 今日完成番茄数；持续任务开启每日目标时存在。
    let todayCompletedPomodoroCount: Int?
    /// 当前是否达标，供卡片显示反馈；不改变任务整体状态。
    let goalFeedback: TaskGoalFeedback
    /// 表示任务是否已有历史会话；决定可删除还是只能放弃。
    let hasHistory: Bool
    /// 表示任务当前是否可以开始新一轮专注。
    let isStartable: Bool

    /// 沿用任务标识，让列表在刷新后仍能识别同一个任务。
    var id: UUID { task.id }
}

/// 任务页一次查询的完整结果；可重建，不保存本地化文案。
struct TaskListSnapshot: Equatable, Sendable {
    /// 本次查询使用的任务状态筛选条件。
    let status: FocusTaskStatus
    /// 按创建、完成或放弃时刻倒序排列的任务，供页面直接显示。
    let items: [TaskListItem]
    /// 当前账户在三个任务分类中的数量，供筛选栏显示。
    let counts: TaskStatusCounts
}

/// 任务列表的加载结果；失败时只保留稳定错误码供界面选择文案。
enum TaskListLoadResult: Equatable, Sendable {
    case loaded(TaskListSnapshot)
    case failed(TaskFailure)
}
