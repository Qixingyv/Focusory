import Foundation
import Testing
@testable import Focusory

/// 校验任务列表查询的账户隔离、计数、进度推导与排序。
@MainActor
@Suite("任务列表查询")
struct ListTasksQueryTests {
    /// 查询当前账户的进行中任务并统计三状态数量。
    @Test func loadsActiveTasksWithAllStatusCounts() throws {
        let world = TaskTestWorld()
        try world.seedTask(name: "待办一", todoTarget: 2)
        try world.seedTask(name: "待办二", todoTarget: 3)
        let completed = try world.seedTask(name: "已完成")
        let abandoned = try world.seedTask(name: "已放弃")
        world.save(try complete(completed, at: world.clock.now.addingTimeInterval(60)))
        world.save(try abandon(abandoned, at: world.clock.now.addingTimeInterval(120)))

        let snapshot = try ListTasksQuery(environment: world.environment).execute(status: .active)

        #expect(snapshot.status == .active)
        #expect(snapshot.items.count == 2)
        #expect(snapshot.counts.active == 2)
        #expect(snapshot.counts.completed == 1)
        #expect(snapshot.counts.abandoned == 1)
        #expect(snapshot.counts.total == 4)
    }

    /// 列表只包含当前账户的任务。
    @Test func excludesOtherAccountTasks() throws {
        let world = TaskTestWorld()
        try world.seedTask(name: "我的任务")
        try world.seedTask(name: "别人的任务", ownerID: world.otherOwnerID)

        let snapshot = try ListTasksQuery(environment: world.environment).execute(status: .active)

        #expect(snapshot.items.map(\.task.name) == ["我的任务"])
        #expect(snapshot.counts.active == 1)
    }

    /// 待办列表项从会话推导完成数、历史存在性与达标反馈。
    @Test func derivesTodoProgressFromSessions() throws {
        let world = TaskTestWorld()
        let task = try world.seedTask(name: "待办", todoTarget: 2)
        world.seedSessions(count: 2, taskID: task.id)

        let snapshot = try ListTasksQuery(environment: world.environment).execute(status: .active)
        let item = try #require(snapshot.items.first)

        #expect(item.completedPomodoroCount == 2)
        #expect(item.totalFocusDurationSeconds == 3000)
        #expect(item.effectiveTarget == 2)
        #expect(item.todayCompletedPomodoroCount == nil)
        #expect(item.goalFeedback == .goalMet)
        #expect(item.hasHistory)
        #expect(item.isStartable)
    }

    /// 持续任务今日未建立快照时按每日基础目标展示预计目标。
    @Test func usesConfiguredDailyTargetBeforeFirstSession() throws {
        let world = TaskTestWorld()
        try world.seedTask(name: "持续", mode: .ongoing, hasDailyTarget: true, dailyTarget: 3)

        let snapshot = try ListTasksQuery(environment: world.environment).execute(status: .active)
        let item = try #require(snapshot.items.first)

        #expect(item.effectiveTarget == 3)
        #expect(item.todayCompletedPomodoroCount == 0)
        #expect(item.goalFeedback == .inProgress)
        #expect(item.hasHistory == false)
    }

    /// 持续任务今日已建立快照时按「目标快照 + 当日追加数」展示。
    @Test func usesTodayEffectiveTargetAfterSnapshot() throws {
        let world = TaskTestWorld()
        let task = try world.seedTask(name: "持续", mode: .ongoing, hasDailyTarget: true, dailyTarget: 2)
        try world.seedTodayProgress(task: task, targetSnapshot: 2, addedTargetCount: 1, completedPomodoroCount: 3)

        let snapshot = try ListTasksQuery(environment: world.environment).execute(status: .active)
        let item = try #require(snapshot.items.first)

        #expect(item.effectiveTarget == 3)
        #expect(item.todayCompletedPomodoroCount == 3)
        #expect(item.goalFeedback == .goalMet)
    }

    /// 持续任务未开启每日目标时只展示累计投入。
    @Test func showsOnlyAccumulatedProgressWithoutDailyTarget() throws {
        let world = TaskTestWorld()
        let task = try world.seedTask(name: "持续", mode: .ongoing)
        world.seedSessions(count: 4, taskID: task.id)

        let snapshot = try ListTasksQuery(environment: world.environment).execute(status: .active)
        let item = try #require(snapshot.items.first)

        #expect(item.effectiveTarget == nil)
        #expect(item.todayCompletedPomodoroCount == nil)
        #expect(item.goalFeedback == .inProgress)
        #expect(item.completedPomodoroCount == 4)
    }

    /// 未到计划开始日的持续任务不能开始专注。
    @Test func marksFutureOngoingTaskAsNotStartable() throws {
        let world = TaskTestWorld()
        try world.seedTask(
            name: "未来计划",
            mode: .ongoing,
            hasDateRange: true,
            startDate: makeLocalDate("2026-11-01"),
            endDate: makeLocalDate("2026-11-30")
        )

        let snapshot = try ListTasksQuery(environment: world.environment).execute(status: .active)
        let item = try #require(snapshot.items.first)

        #expect(item.isStartable == false)
    }

    /// 已完成任务不可开始专注，也不提供追加。
    @Test func terminalTasksAreNotStartable() throws {
        let world = TaskTestWorld()
        let task = try world.seedTask(name: "已放弃", todoTarget: 1)
        world.save(try abandon(task, at: world.clock.now))

        let snapshot = try ListTasksQuery(environment: world.environment).execute(status: .abandoned)
        let item = try #require(snapshot.items.first)

        #expect(item.isStartable == false)
        #expect(item.task.status == .abandoned)
    }

    /// 把任务推入已完成终态。
    private func complete(_ task: FocusTask, at instant: Date) throws -> FocusTask {
        var task = task
        try task.complete(now: instant, isLockedByTimer: false)
        return task
    }

    /// 把任务推入已放弃终态。
    private func abandon(_ task: FocusTask, at instant: Date) throws -> FocusTask {
        var task = task
        try task.abandon(now: instant, isLockedByTimer: false)
        return task
    }
}
