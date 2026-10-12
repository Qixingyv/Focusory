import Foundation

/// 三个任务整体状态的数量。
struct TaskStatusCounts: Equatable, Sendable {
    /// 进行中数量。
    let active: Int
    /// 已完成数量。
    let completed: Int
    /// 已放弃数量。
    let abandoned: Int

    /// 全部任务数量。
    var total: Int {
        active + completed + abandoned
    }

    /// 从任务集合统计各状态数量。
    init(tasks: [FocusTask]) {
        var activeCount = 0
        var completedCount = 0
        var abandonedCount = 0
        for task in tasks {
            switch task.status {
            case .active: activeCount += 1
            case .completed: completedCount += 1
            case .abandoned: abandonedCount += 1
            }
        }
        active = activeCount
        completed = completedCount
        abandoned = abandonedCount
    }

    /// 直接给出三个状态的数量。
    init(active: Int, completed: Int, abandoned: Int) {
        self.active = active
        self.completed = completed
        self.abandoned = abandoned
    }

    /// 返回给定状态的数量。
    subscript(status: FocusTaskStatus) -> Int {
        switch status {
        case .active: active
        case .completed: completed
        case .abandoned: abandoned
        }
    }
}
