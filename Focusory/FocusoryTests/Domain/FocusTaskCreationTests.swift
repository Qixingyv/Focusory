import Foundation
import Testing
@testable import Focusory

/// 校验任务创建时的模式、时长、目标与日期规则。
@MainActor
@Suite("任务创建校验")
struct FocusTaskCreationTests {
    /// 基准本机日期。
    private let today = TaskTestWorld.today
    /// 测试账户。
    private let ownerID = AccountID()
    /// 测试创建瞬时。
    private let now = Date(timeIntervalSince1970: 1_792_000_000)

    /// 合法待办草稿可以创建为进行中任务。
    @Test func createsTodoTaskAsActive() throws {
        let task = try FocusTask.create(
            draft: TaskDraft(name: "  写 F01 测试  ", mode: .todo, todoTarget: 4),
            ownerID: ownerID,
            today: today,
            now: now
        )

        #expect(task.name == "写 F01 测试")
        #expect(task.mode == .todo)
        #expect(task.status == .active)
        #expect(task.todoTarget == 4)
        #expect(task.hasDateRange == false)
        #expect(task.hasDailyTarget == false)
        #expect(task.version == 1)
        #expect(task.createdAt == now)
        #expect(task.completedAt == nil)
        #expect(task.abandonedAt == nil)
    }

    /// 名称只有空白时按必填校验拒绝，并把错误定位到名称字段。
    @Test func rejectsBlankName() {
        let failure = captureTaskFailure {
            _ = try FocusTask.create(
                draft: TaskDraft(name: "   ", mode: .todo, todoTarget: 1),
                ownerID: ownerID,
                today: today,
                now: now
            )
        }
        #expect(failure.code == .nameRequired)
        #expect(failure.field == .name)
    }

    /// 专注时长必须落在 5 至 120 分钟并以 5 分钟为步长。
    @Test(arguments: [4, 0, 125, 7])
    func rejectsFocusDurationOutOfRange(minutes: Int) {
        let failure = captureTaskFailure {
            _ = try FocusTask.create(
                draft: TaskDraft(name: "专注时长", mode: .todo, focusDurationMinutes: minutes, todoTarget: 1),
                ownerID: ownerID,
                today: today,
                now: now
            )
        }
        #expect(failure.code == .focusDurationOutOfRange)
        #expect(failure.field == .focusDuration)
    }

    /// 休息时长必须落在 1 至 60 分钟。
    @Test(arguments: [0, 61])
    func rejectsBreakDurationOutOfRange(minutes: Int) {
        let failure = captureTaskFailure {
            _ = try FocusTask.create(
                draft: TaskDraft(name: "休息时长", mode: .todo, breakDurationMinutes: minutes, todoTarget: 1),
                ownerID: ownerID,
                today: today,
                now: now
            )
        }
        #expect(failure.code == .breakDurationOutOfRange)
        #expect(failure.field == .breakDuration)
    }

    /// 待办目标必须是正整数。
    @Test(arguments: [0, -3])
    func rejectsNonPositiveTodoTarget(target: Int) {
        let failure = captureTaskFailure {
            _ = try FocusTask.create(
                draft: TaskDraft(name: "目标", mode: .todo, todoTarget: target),
                ownerID: ownerID,
                today: today,
                now: now
            )
        }
        #expect(failure.code == .todoTargetOutOfRange)
        #expect(failure.field == .todoTarget)
    }

    /// 持续任务的两个开关可以组成四种合法配置，且不携带待办字段。
    @Test(arguments: [(false, false), (true, false), (false, true), (true, true)])
    func createsOngoingTaskForAllToggleCombinations(hasDateRange: Bool, hasDailyTarget: Bool) throws {
        let task = try FocusTask.create(
            draft: TaskDraft(
                name: "持续任务",
                mode: .ongoing,
                hasDateRange: hasDateRange,
                startDate: hasDateRange ? today : nil,
                endDate: hasDateRange ? makeLocalDate("2026-10-31") : nil,
                hasDailyTarget: hasDailyTarget,
                dailyTarget: hasDailyTarget ? 2 : nil
            ),
            ownerID: ownerID,
            today: today,
            now: now
        )

        #expect(task.mode == .ongoing)
        #expect(task.todoTarget == nil)
        #expect(task.hasDateRange == hasDateRange)
        #expect(task.hasDailyTarget == hasDailyTarget)
        #expect(task.dailyTarget == (hasDailyTarget ? 2 : nil))
    }

    /// 持续任务的开始日不得早于本机今日。
    @Test func rejectsStartDateBeforeToday() {
        let failure = captureTaskFailure {
            _ = try FocusTask.create(
                draft: TaskDraft(
                    name: "计划周期",
                    mode: .ongoing,
                    hasDateRange: true,
                    startDate: makeLocalDate("2026-10-10"),
                    endDate: makeLocalDate("2026-10-20")
                ),
                ownerID: ownerID,
                today: today,
                now: now
            )
        }
        #expect(failure.code == .startDateBeforeToday)
        #expect(failure.field == .dateRange)
    }

    /// 持续任务的截止日不得早于开始日。
    @Test func rejectsEndDateBeforeStartDate() {
        let failure = captureTaskFailure {
            _ = try FocusTask.create(
                draft: TaskDraft(
                    name: "计划周期",
                    mode: .ongoing,
                    hasDateRange: true,
                    startDate: today,
                    endDate: makeLocalDate("2026-10-01")
                ),
                ownerID: ownerID,
                today: today,
                now: now
            )
        }
        #expect(failure.code == .endDateBeforeStartDate)
        #expect(failure.field == .dateRange)
    }

    /// 开启每日目标时必须给出正整数目标。
    @Test func rejectsNonPositiveDailyTarget() {
        let failure = captureTaskFailure {
            _ = try FocusTask.create(
                draft: TaskDraft(
                    name: "每日目标",
                    mode: .ongoing,
                    hasDailyTarget: true,
                    dailyTarget: 0
                ),
                ownerID: ownerID,
                today: today,
                now: now
            )
        }
        #expect(failure.code == .dailyTargetOutOfRange)
        #expect(failure.field == .dailyTarget)
    }
}
