import Foundation
@testable import Focusory

/// 任务用例测试环境；一次装配内存存储、受控时间与全部端口桩。
@MainActor
final class TaskTestWorld {
    /// 测试基准本机日期。
    static let today = makeLocalDate("2026-10-11")

    /// 当前账户标识。
    let ownerID = AccountID()
    /// 另一个账户标识，用于验证账户隔离。
    let otherOwnerID = AccountID()
    /// 共享内存存储。
    let store = InMemoryLocalStore()
    /// 测试日历。
    let calendar = FixedCalendarProvider()
    /// 可控时钟。
    let clock: FixedClock
    /// 计时桩。
    let timer = StubFocusTimerService()
    /// 任务用例依赖。
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
