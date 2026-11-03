import Foundation

/// 从任务列表开始专注：先判定任务可用性，再把固化的本轮配置交给 F02。
struct StartFocusFromTaskCommand {
    /// 读取当前账户任务、判断日期并交接计时所需的能力。
    let environment: TaskUseCaseEnvironment

    /// 判定并启动一轮专注。
    /// - 失败：任务不可用或读取失败时抛错；终态任务返回拒绝结果，未到开始日时返回该日期。
    func execute(taskID: UUID) throws -> StartFocusOutcome {
        let ownerID = environment.account.currentAccountID
        let today = environment.calendar.localDate(for: environment.clock.now)
        let task = try environment.requireTask(id: taskID, ownerID: ownerID)

        switch task.decideStart(today: today) {
        case .allowed(let configuration):
            return environment.focusTimer.startFocus(configuration: configuration)
        case .rejected(let failure):
            return .rejected(failure)
        case .notYetStarted(let startDate):
            return .notYetStarted(startDate)
        }
    }
}
