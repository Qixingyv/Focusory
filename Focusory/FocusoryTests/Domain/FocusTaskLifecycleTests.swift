import Foundation
import Testing
@testable import Focusory

/// 校验任务编辑、生命周期与开始可用性规则。
@MainActor
@Suite("任务编辑与生命周期")
struct FocusTaskLifecycleTests {
    /// 基准本机日期。
    private let today = TaskTestWorld.today
    /// 测试账户。
    private let ownerID = AccountID()
    /// 测试创建瞬时。
    private let now = Date(timeIntervalSince1970: 1_792_000_000)
    /// 编辑瞬时，晚于创建瞬时。
    private let later = Date(timeIntervalSince1970: 1_792_003_600)

    /// 创建一份可编辑的待办任务。
    private func makeTodoTask(target: Int = 2) throws -> FocusTask {
        try FocusTask.create(
            draft: TaskDraft(name: "原始名称", mode: .todo, todoTarget: target),
            ownerID: ownerID,
            today: today,
            now: now
        )
    }

    /// 编辑允许的字段会保留模式并递增版本号。
    @Test func appliesEditableFieldsAndBumpsVersion() throws {
        var task = try makeTodoTask()
        try task.apply(
            TaskDraft(name: "新名称", mode: .todo, focusDurationMinutes: 50, breakDurationMinutes: 10, todoTarget: 6),
            today: today,
            hasHistory: false,
            now: later
        )

        #expect(task.name == "新名称")
        #expect(task.mode == .todo)
        #expect(task.focusDurationMinutes == 50)
        #expect(task.breakDurationMinutes == 10)
        #expect(task.todoTarget == 6)
        #expect(task.version == 2)
        #expect(task.updatedAt == later)
    }

    /// 终态任务不可编辑。
    @Test func rejectsEditingTerminalTask() throws {
        var task = try makeTodoTask()
        try task.complete(now: later, isLockedByTimer: false)

        let failure = captureTaskFailure {
            try task.apply(TaskDraft(name: "改名", mode: .todo, todoTarget: 3), today: today, hasHistory: true, now: later)
        }
        #expect(failure.code == .taskNotActive)
    }

    /// 草稿模式与既有任务模式不一致时拒绝编辑。
    @Test func rejectsModeChange() throws {
        var task = try makeTodoTask()
        let failure = captureTaskFailure {
            try task.apply(
                TaskDraft(name: "改名", mode: .ongoing, hasDailyTarget: false),
                today: today,
                hasHistory: false,
                now: later
            )
        }
        #expect(failure.code == .modeConfigurationMismatch)
    }

    /// 产生会话后不能切换持续任务的两个配置开关。
    @Test(arguments: [(true, false), (false, true)])
    func rejectsToggleSwitchAfterHistory(hasDateRange: Bool, hasDailyTarget: Bool) throws {
        var task = try FocusTask.create(
            draft: TaskDraft(name: "持续任务", mode: .ongoing),
            ownerID: ownerID,
            today: today,
            now: now
        )

        let failure = captureTaskFailure {
            try task.apply(
                TaskDraft(
                    name: "持续任务",
                    mode: .ongoing,
                    hasDateRange: hasDateRange,
                    startDate: hasDateRange ? today : nil,
                    endDate: hasDateRange ? makeLocalDate("2026-10-31") : nil,
                    hasDailyTarget: hasDailyTarget,
                    dailyTarget: hasDailyTarget ? 3 : nil
                ),
                today: today,
                hasHistory: true,
                now: later
            )
        }
        #expect(failure.code == .configurationLockedByHistory)
    }

    /// 开始日未改动时，历史计划周期不会被本机今日锁死，其他字段仍可编辑。
    @Test func allowsEditingTaskWithPastStartDateWhenRangeUnchanged() throws {
        var task = try FocusTask.create(
            draft: TaskDraft(
                name: "长期计划",
                mode: .ongoing,
                hasDateRange: true,
                startDate: today,
                endDate: makeLocalDate("2026-12-31")
            ),
            ownerID: ownerID,
            today: today,
            now: now
        )

        let futureToday = makeLocalDate("2026-10-20")
        try task.apply(
            TaskDraft(
                name: "长期计划改名",
                mode: .ongoing,
                hasDateRange: true,
                startDate: today,
                endDate: makeLocalDate("2026-12-31")
            ),
            today: futureToday,
            hasHistory: true,
            now: later
        )

        #expect(task.name == "长期计划改名")
        #expect(task.startDate == today)
    }

    /// 开始日被改到过去时仍然拒绝。
    @Test func rejectsNewStartDateInPast() throws {
        var task = try FocusTask.create(
            draft: TaskDraft(
                name: "长期计划",
                mode: .ongoing,
                hasDateRange: true,
                startDate: today,
                endDate: makeLocalDate("2026-12-31")
            ),
            ownerID: ownerID,
            today: today,
            now: now
        )

        let failure = captureTaskFailure {
            try task.apply(
                TaskDraft(
                    name: "长期计划",
                    mode: .ongoing,
                    hasDateRange: true,
                    startDate: makeLocalDate("2026-10-01"),
                    endDate: makeLocalDate("2026-12-31")
                ),
                today: today,
                hasHistory: false,
                now: later
            )
        }
        #expect(failure.code == .startDateBeforeToday)
    }

    /// 手动完成进入不可恢复的终态并记录完成来源。
    @Test func completesTaskIntoTerminalState() throws {
        var task = try makeTodoTask()
        try task.complete(now: later, isLockedByTimer: false)

        #expect(task.status == .completed)
        #expect(task.completionSource == .manual)
        #expect(task.completedAt == later)
        #expect(task.version == 2)
    }

    /// 计时锁定时不能完成或放弃。
    @Test func rejectsLockedLifecycleChanges() throws {
        var task = try makeTodoTask()

        let completeFailure = captureTaskFailure {
            try task.complete(now: later, isLockedByTimer: true)
        }
        #expect(completeFailure.code == .taskLockedByTimer)

        let abandonFailure = captureTaskFailure {
            try task.abandon(now: later, isLockedByTimer: true)
        }
        #expect(abandonFailure.code == .taskLockedByTimer)

        #expect(task.status == .active)
    }

    /// 放弃保留任务并记录放弃时刻。
    @Test func abandonsTask() throws {
        var task = try makeTodoTask()
        try task.abandon(now: later, isLockedByTimer: false)

        #expect(task.status == .abandoned)
        #expect(task.abandonedAt == later)
        #expect(task.completionSource == nil)
    }

    /// 终态任务不可再次进入终态。
    @Test func rejectsRepeatedCompletion() throws {
        var task = try makeTodoTask()
        try task.abandon(now: later, isLockedByTimer: false)

        let failure = captureTaskFailure {
            try task.complete(now: later, isLockedByTimer: false)
        }
        #expect(failure.code == .taskNotActive)
    }

    /// 进行中待办可以开始，并固化本轮计时配置。
    @Test func allowsStartingActiveTodo() throws {
        let task = try makeTodoTask()
        let decision = task.decideStart(today: today)

        guard case .allowed(let configuration) = decision else {
            Issue.record("预期可以开始，实际为 \(decision)")
            return
        }
        #expect(configuration.taskID == task.id)
        #expect(configuration.focusDurationMinutes == 25)
        #expect(configuration.breakDurationMinutes == 5)
    }

    /// 持续任务未到计划开始日时给出开始日而不是通用拒绝。
    @Test func rejectsStartingBeforeOngoingStartDate() throws {
        let task = try FocusTask.create(
            draft: TaskDraft(
                name: "未来计划",
                mode: .ongoing,
                hasDateRange: true,
                startDate: makeLocalDate("2026-11-01"),
                endDate: makeLocalDate("2026-11-30")
            ),
            ownerID: ownerID,
            today: today,
            now: now
        )

        #expect(task.decideStart(today: today) == .notYetStarted(makeLocalDate("2026-11-01")))

        guard case .allowed = task.decideStart(today: makeLocalDate("2026-11-02")) else {
            Issue.record("到开始日后应当允许开始专注")
            return
        }
    }

    /// 终态任务不可开始。
    @Test func rejectsStartingTerminalTask() throws {
        var task = try makeTodoTask()
        try task.complete(now: later, isLockedByTimer: false)

        #expect(task.decideStart(today: today) == .rejected(TaskFailure(.taskNotActive)))
    }
}
