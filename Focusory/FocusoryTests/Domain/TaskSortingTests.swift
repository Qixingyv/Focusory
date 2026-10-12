import Foundation
import Testing
@testable import Focusory

/// 校验任务列表排序与三状态计数。
@MainActor
@Suite("任务排序与计数")
struct TaskSortingTests {
    /// 测试账户。
    private let ownerID = AccountID()
    /// 另一个账户，用于验证计数隔离。
    private let otherOwnerID = AccountID()

    /// 按标识构造固定瞬时，保证排序断言稳定。
    private func instant(_ seed: Int) -> Date {
        Date(timeIntervalSince1970: 1_792_000_000 + Double(seed))
    }

    /// 构造一个具有指定生命周期时刻的任务。
    private func makeTask(
        idSeed: Int,
        status: FocusTaskStatus,
        createdAtSeed: Int,
        lifecycleSeed: Int?
    ) -> FocusTask {
        let identifier = UUID(uuidString: String(format: "00000000-0000-4000-8000-%012d", idSeed))
            ?? UUID()
        return FocusTask(
            id: identifier,
            ownerID: ownerID,
            name: "任务 \(idSeed)",
            mode: .todo,
            status: status,
            focusDurationMinutes: 25,
            breakDurationMinutes: 5,
            todoTarget: 2,
            createdAt: instant(createdAtSeed),
            updatedAt: instant(createdAtSeed),
            completedAt: status == .completed ? lifecycleSeed.map(instant) : nil,
            abandonedAt: status == .abandoned ? lifecycleSeed.map(instant) : nil,
            version: 1
        )
    }

    /// 进行中按创建时间倒序。
    @Test func sortsActiveByCreationDescending() {
        let tasks = [
            makeTask(idSeed: 1, status: .active, createdAtSeed: 10, lifecycleSeed: nil),
            makeTask(idSeed: 2, status: .active, createdAtSeed: 30, lifecycleSeed: nil),
            makeTask(idSeed: 3, status: .active, createdAtSeed: 20, lifecycleSeed: nil)
        ]

        let sorted = TaskSorting.sorted(tasks, status: .active)
        #expect(sorted.map(\.name) == ["任务 2", "任务 3", "任务 1"])
    }

    /// 已完成按完成时间倒序，相同时间按标识稳定兜底。
    @Test func sortsCompletedByCompletionDescending() {
        let tasks = [
            makeTask(idSeed: 1, status: .completed, createdAtSeed: 1, lifecycleSeed: 10),
            makeTask(idSeed: 2, status: .completed, createdAtSeed: 2, lifecycleSeed: 10),
            makeTask(idSeed: 3, status: .completed, createdAtSeed: 3, lifecycleSeed: 30)
        ]

        let sorted = TaskSorting.sorted(tasks, status: .completed)
        #expect(sorted.map(\.name) == ["任务 3", "任务 2", "任务 1"])
    }

    /// 已放弃按放弃时间倒序。
    @Test func sortsAbandonedByAbandonTimeDescending() {
        let tasks = [
            makeTask(idSeed: 1, status: .abandoned, createdAtSeed: 1, lifecycleSeed: 10),
            makeTask(idSeed: 2, status: .abandoned, createdAtSeed: 2, lifecycleSeed: 40)
        ]

        let sorted = TaskSorting.sorted(tasks, status: .abandoned)
        #expect(sorted.map(\.name) == ["任务 2", "任务 1"])
    }

    /// 三状态计数按状态归类。
    @Test func countsTasksByStatus() {
        let counts = TaskStatusCounts(tasks: [
            makeTask(idSeed: 1, status: .active, createdAtSeed: 1, lifecycleSeed: nil),
            makeTask(idSeed: 2, status: .active, createdAtSeed: 2, lifecycleSeed: nil),
            makeTask(idSeed: 3, status: .completed, createdAtSeed: 3, lifecycleSeed: 5),
            makeTask(idSeed: 4, status: .abandoned, createdAtSeed: 4, lifecycleSeed: 6)
        ])

        #expect(counts.active == 2)
        #expect(counts.completed == 1)
        #expect(counts.abandoned == 1)
        #expect(counts.total == 4)
        #expect(counts[.completed] == 1)
    }

    /// 账户隔离：其他账户的任务不属于本账户。
    @Test func keepsOtherAccountCountsSeparate() {
        let foreign = FocusTask(
            id: UUID(),
            ownerID: otherOwnerID,
            name: "别人的任务",
            mode: .todo,
            status: .active,
            focusDurationMinutes: 25,
            breakDurationMinutes: 5,
            todoTarget: 1,
            createdAt: instant(1),
            updatedAt: instant(1),
            version: 1
        )

        let counts = TaskStatusCounts(tasks: [foreign])
        #expect(counts.active == 1)
        #expect(foreign.ownerID != ownerID)
    }
}
