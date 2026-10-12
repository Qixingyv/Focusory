import Foundation

/// F02 计时能力的契约；任务管理通过它交接本轮配置并查询计时锁定。
protocol FocusTimerService {
    /// 给定任务是否正被运行或暂停中的计时锁定。
    func isTaskLocked(taskID: UUID) -> Bool
    /// 按已固化的本轮配置开始专注。
    func startFocus(configuration: TaskRunConfiguration) -> StartFocusOutcome
}
