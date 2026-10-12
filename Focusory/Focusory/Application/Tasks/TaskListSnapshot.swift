import Foundation

/// 任务列表项；任务本体加从会话与每日进度推导的进度事实，不含本地化文案。
struct TaskListItem: Identifiable, Equatable, Sendable {
    /// 任务本体。
    let task: FocusTask
    /// 累计完成番茄数。
    let completedPomodoroCount: Int
    /// 累计实际专注秒数。
    let totalFocusDurationSeconds: Int
    /// 当前有效目标；待办总目标或持续任务当日有效目标。
    let effectiveTarget: Int?
    /// 今日完成番茄数；持续任务开启每日目标时存在。
    let todayCompletedPomodoroCount: Int?
    /// 目标反馈子状态。
    let goalFeedback: TaskGoalFeedback
    /// 表示任务是否已有历史会话；决定可删除还是只能放弃。
    let hasHistory: Bool
    /// 表示任务当前是否可以开始新一轮专注。
    let isStartable: Bool

    /// 列表项标识等于任务标识。
    var id: UUID { task.id }
}

/// 任务页一次查询的完整结果；可重建，不保存本地化文案。
struct TaskListSnapshot: Equatable, Sendable {
    /// 本次查询的状态。
    let status: FocusTaskStatus
    /// 已按生命周期时刻排序的列表项。
    let items: [TaskListItem]
    /// 三个整体状态的数量。
    let counts: TaskStatusCounts
}

/// 任务列表的加载结果；失败时只保留稳定错误码供界面选择文案。
enum TaskListLoadResult: Equatable, Sendable {
    case loaded(TaskListSnapshot)
    case failed(TaskFailure)
}
