import Foundation

/// F02 尚未实现时的计时占位实现：只确认收到本轮配置，不启动真实计时，也不锁定任务。
// TODO(F02): 用 Domain/Timer 与活跃计时快照替换占位实现，并让 isTaskLocked 反映运行或暂停中的当前任务。
struct PlaceholderFocusTimerService: FocusTimerService {
    /// P0 没有活跃计时，任务不会被锁定。
    func isTaskLocked(taskID: UUID) -> Bool {
        false
    }

    /// 确认已接收固化的本轮配置。
    func startFocus(configuration: TaskRunConfiguration) -> StartFocusOutcome {
        .started
    }
}
