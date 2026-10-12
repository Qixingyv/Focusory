import Foundation

/// 任务列表的排序规则：先按生命周期时刻倒序，再按任务 ID 稳定兜底。
enum TaskSorting {
    /// 返回给定状态下已排序的任务数组。
    static func sorted(_ tasks: [FocusTask], status: FocusTaskStatus) -> [FocusTask] {
        tasks.sorted { lhs, rhs in
            let lhsInstant = lhs.lifecycleInstant(for: status)
            let rhsInstant = rhs.lifecycleInstant(for: status)
            if lhsInstant != rhsInstant {
                return lhsInstant > rhsInstant
            }
            return lhs.id.uuidString > rhs.id.uuidString
        }
    }
}
