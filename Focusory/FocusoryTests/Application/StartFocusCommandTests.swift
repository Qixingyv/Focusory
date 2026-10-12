import Foundation
import Testing
@testable import Focusory

/// 校验任务管理向 F02 交接本轮配置的判定与结果。
@MainActor
@Suite("开始专注用例")
struct StartFocusCommandTests {
    /// 进行中任务会把手交接给计时端口并固化本轮配置。
    @Test func handsOffFrozenRunConfiguration() throws {
        let world = TaskTestWorld()
        let task = try world.seedTask(
            name: "待办",
            focusDurationMinutes: 45,
            breakDurationMinutes: 10
        )
        world.timer.startOutcome = .started

        let outcome = try StartFocusFromTaskCommand(environment: world.environment).execute(taskID: task.id)

        #expect(outcome == .started)
        let configuration = try #require(world.timer.handedOffConfigurations.first)
        #expect(configuration.taskID == task.id)
        #expect(configuration.taskName == "待办")
        #expect(configuration.focusDurationMinutes == 45)
        #expect(configuration.breakDurationMinutes == 10)
    }

    /// 未到计划开始日时不启动计时，并返回开始日。
    @Test func returnsStartDateBeforeOngoingStartDate() throws {
        let world = TaskTestWorld()
        let task = try world.seedTask(
            name: "未来计划",
            mode: .ongoing,
            hasDateRange: true,
            startDate: makeLocalDate("2026-11-01"),
            endDate: makeLocalDate("2026-11-30")
        )

        let outcome = try StartFocusFromTaskCommand(environment: world.environment).execute(taskID: task.id)

        #expect(outcome == .notYetStarted(makeLocalDate("2026-11-01")))
        #expect(world.timer.handedOffConfigurations.isEmpty)
    }

    /// 终态任务拒绝开始并返回稳定原因。
    @Test func rejectsTerminalTask() throws {
        let world = TaskTestWorld()
        let task = try world.seedTask(name: "待办")
        _ = try CompleteTaskCommand(environment: world.environment).execute(taskID: task.id)

        let outcome = try StartFocusFromTaskCommand(environment: world.environment).execute(taskID: task.id)

        #expect(outcome == .rejected(TaskFailure(.taskNotActive)))
        #expect(world.timer.handedOffConfigurations.isEmpty)
    }

    /// 任务不可用时抛出不可用错误。
    @Test func rejectsUnavailableTask() throws {
        let world = TaskTestWorld()
        let foreignTask = try world.seedTask(name: "别人的任务", ownerID: world.otherOwnerID)

        let failure = captureTaskFailure {
            _ = try StartFocusFromTaskCommand(environment: world.environment).execute(taskID: foreignTask.id)
        }

        #expect(failure.code == .taskUnavailable)
        #expect(world.timer.handedOffConfigurations.isEmpty)
    }
}
