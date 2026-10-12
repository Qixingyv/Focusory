import Foundation

/// 任务模式；创建后不可转换。
enum FocusTaskMode: String, CaseIterable, Identifiable, Sendable {
    case todo
    case ongoing

    /// 枚举标识。
    var id: Self { self }
}

/// 任务整体状态；`completed` 与 `abandoned` 为不可恢复的终态。
enum FocusTaskStatus: String, CaseIterable, Identifiable, Sendable {
    case active
    case completed
    case abandoned

    /// 枚举标识。
    var id: Self { self }
}

/// 任务完成来源；`auto` 只表示待办按计划完成，此时整体状态仍为 `active`。
enum TaskCompletionSource: String, Equatable, Sendable {
    case auto
    case manual
}
