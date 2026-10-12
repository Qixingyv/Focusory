import Foundation
import Testing
@testable import Focusory

/// 校验待办总目标与持续任务当日目标追加用例的幂等、跨日与事务边界。
@MainActor
@Suite("目标追加用例")
struct AppendTargetCommandTests {
    /// 待办达标后追加会更新目标并留下同一个操作标识的变更。
    @Test func appendsTodoTargetWithOperationIdentifier() throws {
        let world = TaskTestWorld()
        let task = try world.seedTask(name: "待办", todoTarget: 2)
        world.seedSessions(count: 2, taskID: task.id)
        let operationID = UUID()

        let result = try AppendTodoTargetCommand(environment: world.environment)
            .execute(taskID: task.id, quantity: 1, operationID: operationID)

        #expect(result.previousTarget == 2)
        #expect(result.newTarget == 3)
        #expect(result.isReplay == false)
        #expect(world.savedTask(id: task.id)?.todoTarget == 3)

        let change = try #require(world.store.syncQueue[operationID])
        #expect(change.operationType == .targetAppended)
        #expect(change.entityType == .task)
        #expect(change.entityID == task.id)
    }

    /// 同一操作标识重复提交只生效一次，并返回重放结果。
    @Test func doesNotAppendTwiceForSameOperationIdentifier() throws {
        let world = TaskTestWorld()
        let task = try world.seedTask(name: "待办", todoTarget: 2)
        world.seedSessions(count: 2, taskID: task.id)
        let operationID = UUID()
        let command = AppendTodoTargetCommand(environment: world.environment)

        _ = try command.execute(taskID: task.id, quantity: 1, operationID: operationID)
        let replay = try command.execute(taskID: task.id, quantity: 1, operationID: operationID)

        #expect(replay.isReplay)
        #expect(replay.previousTarget == 3)
        #expect(replay.newTarget == 3)
        #expect(world.savedTask(id: task.id)?.todoTarget == 3)
        #expect(world.store.syncQueue.count == 1)
    }

    /// 尚未按计划完成时拒绝追加。
    @Test func rejectsTodoAppendBeforeGoalMet() throws {
        let world = TaskTestWorld()
        let task = try world.seedTask(name: "待办", todoTarget: 3)
        world.seedSessions(count: 2, taskID: task.id)

        let failure = captureTaskFailure {
            _ = try AppendTodoTargetCommand(environment: world.environment)
                .execute(taskID: task.id, quantity: 1, operationID: UUID())
        }

        #expect(failure.code == .appendNotAllowed)
        #expect(world.savedTask(id: task.id)?.todoTarget == 3)
        #expect(world.store.syncQueue.isEmpty)
    }

    /// 本地提交失败时目标与同步变更一起回滚。
    @Test func rollsBackTodoAppendOnCommitFailure() throws {
        let world = TaskTestWorld()
        let task = try world.seedTask(name: "待办", todoTarget: 2)
        world.seedSessions(count: 2, taskID: task.id)
        world.store.commitFailure = TaskFailure(.persistenceFailed)

        let failure = captureTaskFailure {
            _ = try AppendTodoTargetCommand(environment: world.environment)
                .execute(taskID: task.id, quantity: 1, operationID: UUID())
        }

        #expect(failure.code == .persistenceFailed)
        #expect(world.savedTask(id: task.id)?.todoTarget == 2)
        #expect(world.store.syncQueue.isEmpty)
    }

    /// 当日追加在日期一致且达标时生效。
    @Test func appendsDailyTargetForMatchingLocalDate() throws {
        let world = TaskTestWorld()
        let task = try world.seedTask(name: "持续", mode: .ongoing, hasDailyTarget: true, dailyTarget: 2)
        try world.seedTodayProgress(task: task, targetSnapshot: 2, completedPomodoroCount: 2)
        let operationID = UUID()

        let result = try AppendDailyTargetCommand(environment: world.environment).execute(
            taskID: task.id,
            quantity: 1,
            expectedLocalDate: TaskTestWorld.today,
            operationID: operationID
        )

        #expect(result.previousTarget == 2)
        #expect(result.newTarget == 3)
        #expect(result.feedback == .inProgress)

        let progress = try #require(
            try world.environment.dailyProgress.progress(
                taskID: task.id,
                ownerID: world.ownerID,
                localDate: TaskTestWorld.today
            )
        )
        #expect(progress.addedTargetCount == 1)
        #expect(progress.targetSnapshot == 2)

        let change = try #require(world.store.syncQueue[operationID])
        #expect(change.entityType == .taskDailyProgress)
        #expect(change.entityID == progress.id)
    }

    /// 跨零点提交不得写入上一日。
    @Test func rejectsDailyAppendAfterLocalDateChanged() throws {
        let world = TaskTestWorld()
        let task = try world.seedTask(name: "持续", mode: .ongoing, hasDailyTarget: true, dailyTarget: 2)
        try world.seedTodayProgress(task: task, targetSnapshot: 2, completedPomodoroCount: 2)

        let failure = captureTaskFailure {
            _ = try AppendDailyTargetCommand(environment: world.environment).execute(
                taskID: task.id,
                quantity: 1,
                expectedLocalDate: makeLocalDate("2026-10-10"),
                operationID: UUID()
            )
        }

        #expect(failure.code == .localDateChanged)
        #expect(world.store.syncQueue.isEmpty)
    }

    /// 今日没有进度快照时不可追加。
    @Test func rejectsDailyAppendWithoutTodayProgress() throws {
        let world = TaskTestWorld()
        let task = try world.seedTask(name: "持续", mode: .ongoing, hasDailyTarget: true, dailyTarget: 2)

        let failure = captureTaskFailure {
            _ = try AppendDailyTargetCommand(environment: world.environment).execute(
                taskID: task.id,
                quantity: 1,
                expectedLocalDate: TaskTestWorld.today,
                operationID: UUID()
            )
        }

        #expect(failure.code == .appendNotAllowed)
    }

    /// 未开启每日目标的持续任务不可追加当日目标。
    @Test func rejectsDailyAppendWithoutDailyTarget() throws {
        let world = TaskTestWorld()
        let task = try world.seedTask(name: "持续", mode: .ongoing)
        try world.seedTodayProgress(task: task, targetSnapshot: 2, completedPomodoroCount: 2)

        let failure = captureTaskFailure {
            _ = try AppendDailyTargetCommand(environment: world.environment).execute(
                taskID: task.id,
                quantity: 1,
                expectedLocalDate: TaskTestWorld.today,
                operationID: UUID()
            )
        }

        #expect(failure.code == .appendNotAllowed)
    }

    /// 终态任务不可追加当日目标。
    @Test func rejectsDailyAppendOnTerminalTask() throws {
        let world = TaskTestWorld()
        let task = try world.seedTask(name: "持续", mode: .ongoing, hasDailyTarget: true, dailyTarget: 2)
        try world.seedTodayProgress(task: task, targetSnapshot: 2, completedPomodoroCount: 2)
        world.save(try {
            var task = task
            try task.abandon(now: world.clock.now, isLockedByTimer: false)
            return task
        }())

        let failure = captureTaskFailure {
            _ = try AppendDailyTargetCommand(environment: world.environment).execute(
                taskID: task.id,
                quantity: 1,
                expectedLocalDate: TaskTestWorld.today,
                operationID: UUID()
            )
        }

        #expect(failure.code == .taskNotActive)
    }

    /// 同一操作标识重复提交当日追加只生效一次。
    @Test func doesNotAppendDailyTargetTwice() throws {
        let world = TaskTestWorld()
        let task = try world.seedTask(name: "持续", mode: .ongoing, hasDailyTarget: true, dailyTarget: 2)
        try world.seedTodayProgress(task: task, targetSnapshot: 2, completedPomodoroCount: 2)
        let operationID = UUID()
        let command = AppendDailyTargetCommand(environment: world.environment)

        _ = try command.execute(
            taskID: task.id,
            quantity: 1,
            expectedLocalDate: TaskTestWorld.today,
            operationID: operationID
        )
        let replay = try command.execute(
            taskID: task.id,
            quantity: 1,
            expectedLocalDate: TaskTestWorld.today,
            operationID: operationID
        )

        #expect(replay.isReplay)
        let progress = try #require(
            try world.environment.dailyProgress.progress(
                taskID: task.id,
                ownerID: world.ownerID,
                localDate: TaskTestWorld.today
            )
        )
        #expect(progress.addedTargetCount == 1)
        #expect(world.store.syncQueue.count == 1)
    }
}
