import Foundation
import Testing
@testable import Focusory

/// 校验待办总目标追加与持续任务当日目标追加的规则。
@MainActor
@Suite("目标追加规则")
struct TaskTargetAppendTests {
    /// 基准本机日期。
    private let today = TaskTestWorld.today
    /// 测试账户。
    private let ownerID = AccountID()
    /// 测试创建瞬时。
    private let now = Date(timeIntervalSince1970: 1_792_000_000)
    /// 追加瞬时。
    private let later = Date(timeIntervalSince1970: 1_792_003_600)

    /// 创建一份指定目标的待办任务。
    private func makeTodoTask(target: Int) throws -> FocusTask {
        try FocusTask.create(
            draft: TaskDraft(name: "待办", mode: .todo, todoTarget: target),
            ownerID: ownerID,
            today: today,
            now: now
        )
    }

    /// 创建一份开启每日目标的持续任务。
    private func makeOngoingTask(dailyTarget: Int = 2) throws -> FocusTask {
        try FocusTask.create(
            draft: TaskDraft(name: "持续", mode: .ongoing, hasDailyTarget: true, dailyTarget: dailyTarget),
            ownerID: ownerID,
            today: today,
            now: now
        )
    }

    /// 创建一条为今日建立快照的每日进度。
    private func makeTodayProgress(
        task: FocusTask,
        snapshot: Int,
        added: Int = 0,
        completed: Int = 0
    ) -> TaskDailyProgress {
        TaskDailyProgress(
            id: UUID(),
            ownerID: task.ownerID,
            taskID: task.id,
            localDate: today,
            timeZoneID: TimeZoneID("Asia/Shanghai") ?? TimeZoneID(TimeZone(secondsFromGMT: 0) ?? .gmt),
            targetSnapshot: snapshot,
            addedTargetCount: added,
            completedPomodoroCount: completed,
            focusDurationSeconds: completed * 1500,
            createdAt: now,
            updatedAt: now,
            version: 1
        )
    }

    /// 达标后追加 1 个目标会恢复进行中反馈。
    @Test func appendsTodoTargetToRestoreInProgress() throws {
        var task = try makeTodoTask(target: 2)
        let result = try task.appendTodoTarget(1, completedPomodoroCount: 2, now: later)

        #expect(result.previousTarget == 2)
        #expect(result.newTarget == 3)
        #expect(result.isReplay == false)
        #expect(result.feedback == .inProgress)
        #expect(task.todoTarget == 3)
        #expect(task.completionSource == nil)
        #expect(task.version == 2)
    }

    /// 追加后仍不超过完成数时保持按计划完成反馈。
    @Test func keepsGoalMetWhenNewTargetStillReached() throws {
        var task = try makeTodoTask(target: 2)
        let result = try task.appendTodoTarget(1, completedPomodoroCount: 3, now: later)

        #expect(result.newTarget == 3)
        #expect(result.feedback == .goalMet)
        #expect(task.completionSource == .auto)
    }

    /// 多追加两个目标后重新回到进行中。
    @Test func appendsMultipleToRestoreInProgress() throws {
        var task = try makeTodoTask(target: 2)
        let result = try task.appendTodoTarget(2, completedPomodoroCount: 3, now: later)

        #expect(result.newTarget == 4)
        #expect(result.feedback == .inProgress)
        #expect(task.todoTarget == 4)
    }

    /// 追加数量必须是正整数。
    @Test(arguments: [0, -1])
    func rejectsNonPositiveAppendQuantity(quantity: Int) throws {
        var task = try makeTodoTask(target: 2)
        let failure = captureTaskFailure {
            _ = try task.appendTodoTarget(quantity, completedPomodoroCount: 2, now: later)
        }
        #expect(failure.code == .appendQuantityOutOfRange)
        #expect(task.todoTarget == 2)
    }

    /// 尚未按计划完成时不可追加。
    @Test func rejectsAppendBeforeGoalMet() throws {
        var task = try makeTodoTask(target: 3)
        let failure = captureTaskFailure {
            _ = try task.appendTodoTarget(1, completedPomodoroCount: 2, now: later)
        }
        #expect(failure.code == .appendNotAllowed)
        #expect(task.todoTarget == 3)
    }

    /// 持续任务不能追加待办总目标。
    @Test func rejectsTodoAppendOnOngoingTask() throws {
        var task = try makeOngoingTask()
        let failure = captureTaskFailure {
            _ = try task.appendTodoTarget(1, completedPomodoroCount: 5, now: later)
        }
        #expect(failure.code == .appendNotAllowed)
    }

    /// 终态任务不可追加。
    @Test func rejectsAppendOnTerminalTask() throws {
        var task = try makeTodoTask(target: 1)
        try task.complete(now: later, isLockedByTimer: false)

        let failure = captureTaskFailure {
            _ = try task.appendTodoTarget(1, completedPomodoroCount: 1, now: later)
        }
        #expect(failure.code == .taskNotActive)
    }

    /// 记录会话会累计当日完成数与专注时长。
    @Test func recordsCompletedSessionIntoDailyProgress() throws {
        let task = try makeOngoingTask()
        var progress = makeTodayProgress(task: task, snapshot: 2)

        #expect(progress.effectiveTarget == 2)
        #expect(progress.isMet == false)

        progress.recordCompletedSession(focusDurationSeconds: 1500, now: later)
        progress.recordCompletedSession(focusDurationSeconds: 1500, now: later)

        #expect(progress.completedPomodoroCount == 2)
        #expect(progress.focusDurationSeconds == 3000)
        #expect(progress.isMet)
    }

    /// 非正时长不会改变每日进度。
    @Test func ignoresNonPositiveSessionDuration() throws {
        let task = try makeOngoingTask()
        var progress = makeTodayProgress(task: task, snapshot: 2)

        progress.recordCompletedSession(focusDurationSeconds: 0, now: later)

        #expect(progress.completedPomodoroCount == 0)
        #expect(progress.focusDurationSeconds == 0)
        #expect(progress.version == 1)
    }

    /// 今日达标后追加只改变当日追加数，不影响目标快照。
    @Test func appendsDailyTargetWithoutChangingSnapshot() throws {
        let task = try makeOngoingTask(dailyTarget: 2)
        var progress = makeTodayProgress(task: task, snapshot: 2, completed: 2)

        let result = try progress.appendTarget(1, now: later)

        #expect(result.previousTarget == 2)
        #expect(result.newTarget == 3)
        #expect(result.feedback == .inProgress)
        #expect(progress.targetSnapshot == 2)
        #expect(progress.addedTargetCount == 1)
        #expect(progress.effectiveTarget == 3)
    }

    /// 追加后仍未超过完成数时保持今日已达标。
    @Test func keepsDailyMetWhenNewTargetStillReached() throws {
        let task = try makeOngoingTask(dailyTarget: 2)
        var progress = makeTodayProgress(task: task, snapshot: 2, completed: 3)

        let result = try progress.appendTarget(1, now: later)

        #expect(result.newTarget == 3)
        #expect(result.feedback == .goalMet)
        #expect(progress.isMet)
    }

    /// 今日未达标时不可追加当日目标。
    @Test func rejectsDailyAppendBeforeGoalMet() throws {
        let task = try makeOngoingTask(dailyTarget: 3)
        var progress = makeTodayProgress(task: task, snapshot: 3, completed: 1)

        let failure = captureTaskFailure {
            _ = try progress.appendTarget(1, now: later)
        }
        #expect(failure.code == .appendNotAllowed)
        #expect(progress.addedTargetCount == 0)
    }

    /// 当日追加数量必须是正整数。
    @Test func rejectsNonPositiveDailyAppendQuantity() throws {
        let task = try makeOngoingTask()
        var progress = makeTodayProgress(task: task, snapshot: 2, completed: 2)

        let failure = captureTaskFailure {
            _ = try progress.appendTarget(0, now: later)
        }
        #expect(failure.code == .appendQuantityOutOfRange)
        #expect(progress.addedTargetCount == 0)
    }

    /// 建立每日进度快照时目标必须是正整数。
    @Test func rejectsNonPositiveSnapshot() {
        let failure = captureTaskFailure {
            _ = try TaskDailyProgress.create(
                ownerID: self.ownerID,
                taskID: UUID(),
                localDate: self.today,
                timeZoneID: TimeZoneID("Asia/Shanghai") ?? TimeZoneID(TimeZone(secondsFromGMT: 0) ?? .gmt),
                targetSnapshot: 0,
                now: self.now
            )
        }
        #expect(failure.code == .dailyTargetOutOfRange)
    }
}
