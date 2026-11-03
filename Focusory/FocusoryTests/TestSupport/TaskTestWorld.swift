import Foundation
@testable import Focusory

/// 为任务用例测试统一提供内存数据、可控时间和模拟计时服务。
@MainActor
final class TaskTestWorld {
    /// 测试基准本机日期。
    static let today = makeLocalDate("2026-10-11")

    /// 测试用例执行操作的账户。
    let ownerID = AccountID()
    /// 另一个账户标识，用于验证账户隔离。
    let otherOwnerID = AccountID()
    /// 仓储与事务共用的测试数据，供查询、写入和回滚验证。
    let store = InMemoryLocalStore()
    /// 固定时区的日历，让日期归属不受测试机器设置影响。
    let calendar = FixedCalendarProvider()
    /// 测试可调整的当前时刻，用于模拟跨日等情况。
    let clock: FixedClock
    /// 模拟计时服务，供设置任务锁定状态并检查收到的专注配置。
    let timer = StubFocusTimerService()
    /// 已连接测试实现的用例依赖，供测试直接执行任务操作。
    let environment: TaskUseCaseEnvironment

    /// 以基准日期零点装配测试环境。
    init(today: LocalDate = TaskTestWorld.today) {
        let instant = makeInstant(of: today, in: calendar.timeZoneID)
        clock = FixedClock(now: instant)
        environment = TaskUseCaseEnvironment(
            tasks: InMemoryTaskRepository(store: store),
            sessions: InMemorySessionRepository(store: store),
            dailyProgress: InMemoryDailyProgressRepository(store: store),
            syncQueue: InMemorySyncQueueRepository(store: store),
            transaction: InMemoryLocalTransaction(store: store),
            account: FixedAccountProvider(currentAccountID: ownerID),
            calendar: calendar,
            clock: clock,
            focusTimer: timer
        )
    }

    /// 创建任务并写入内存存储；测试准备数据时使用。
    @discardableResult
    func seedTask(
        name: String = "写测试",
        mode: FocusTaskMode = .todo,
        todoTarget: Int = 2,
        focusDurationMinutes: Int = 25,
        breakDurationMinutes: Int = 5,
        hasDateRange: Bool = false,
        startDate: LocalDate? = nil,
        endDate: LocalDate? = nil,
        hasDailyTarget: Bool = false,
        dailyTarget: Int? = nil,
        ownerID: AccountID? = nil
    ) throws -> FocusTask {
        let draft = TaskDraft(
            name: name,
            mode: mode,
            focusDurationMinutes: focusDurationMinutes,
            breakDurationMinutes: breakDurationMinutes,
            todoTarget: mode == .todo ? todoTarget : nil,
            hasDateRange: hasDateRange,
            startDate: startDate,
            endDate: endDate,
            hasDailyTarget: hasDailyTarget,
            dailyTarget: dailyTarget
        )
        let task = try FocusTask.create(
            draft: draft,
            ownerID: ownerID ?? self.ownerID,
            today: Self.today,
            now: clock.now
        )
        save(task)
        return task
    }

    /// 把任务写入内存存储。
    func save(_ task: FocusTask) {
        store.tasks[task.id] = task
    }

    /// 读取内存存储中的任务。
    func savedTask(id: UUID) -> FocusTask? {
        store.tasks[id]
    }

    /// 为任务准备指定数量的已保存会话。
    func seedSessions(count: Int, taskID: UUID, ownerID: AccountID? = nil) {
        store.recordSessions(count: count, taskID: taskID, ownerID: ownerID ?? self.ownerID)
    }

    /// 为持续任务准备今日进度快照。
    @discardableResult
    func seedTodayProgress(
        task: FocusTask,
        targetSnapshot: Int,
        addedTargetCount: Int = 0,
        completedPomodoroCount: Int = 0
    ) throws -> TaskDailyProgress {
        let progress = TaskDailyProgress(
            id: UUID(),
            ownerID: task.ownerID,
            taskID: task.id,
            localDate: Self.today,
            timeZoneID: calendar.timeZoneID,
            targetSnapshot: targetSnapshot,
            addedTargetCount: addedTargetCount,
            completedPomodoroCount: completedPomodoroCount,
            focusDurationSeconds: completedPomodoroCount * 1500,
            createdAt: clock.now,
            updatedAt: clock.now,
            version: 1
        )
        store.seedDailyProgress(progress)
        return progress
    }
}
