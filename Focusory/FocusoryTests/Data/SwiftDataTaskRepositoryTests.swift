import Foundation
import SwiftData
import Testing
@testable import Focusory

/// 校验 SwiftData 任务仓储的字段往返、账户隔离、计数与删除。
@MainActor
@Suite("SwiftData 任务仓储")
struct SwiftDataTaskRepositoryTests {
    /// 保存后可用新上下文完整读回任务字段。
    @Test func roundTripsTaskFields() throws {
        let world = try SwiftDataTestWorld()
        let ownerID = AccountID()
        let task = try world.makeOngoingTask(ownerID: ownerID)

        try world.transaction.perform { try world.tasks.upsert(task) }

        let reloaded = try #require(try world.committedTasks.task(id: task.id, ownerID: ownerID))
        #expect(reloaded == task)
        #expect(reloaded.startDate == TaskTestWorld.today)
        #expect(reloaded.endDate == makeLocalDate("2026-12-31"))
        #expect(reloaded.dailyTarget == 2)
        #expect(reloaded.version == 1)
    }

    /// 同一标识重复保存只保留一条记录并更新字段。
    @Test func upsertOverwritesExistingRecord() throws {
        let world = try SwiftDataTestWorld()
        let ownerID = AccountID()
        var task = try world.makeTodoTask(ownerID: ownerID, todoTarget: 2)

        try world.transaction.perform { try world.tasks.upsert(task) }

        try task.apply(
            TaskDraft(name: "改名后", mode: .todo, todoTarget: 5),
            today: TaskTestWorld.today,
            hasHistory: false,
            now: Date(timeIntervalSince1970: 1_792_003_600)
        )
        try world.transaction.perform { try world.tasks.upsert(task) }

        let all = try world.committedTasks.tasks(ownerID: ownerID, status: .active)
        #expect(all.count == 1)
        #expect(all.first?.name == "改名后")
        #expect(all.first?.todoTarget == 5)
        #expect(all.first?.version == 2)
    }

    /// 查询、计数与读取都按账户隔离。
    @Test func isolatesTasksByOwner() throws {
        let world = try SwiftDataTestWorld()
        let ownerID = AccountID()
        let otherOwnerID = AccountID()
        let mine = try world.makeTodoTask(ownerID: ownerID, name: "我的任务")
        let foreign = try world.makeTodoTask(ownerID: otherOwnerID, name: "别人的任务")

        try world.transaction.perform {
            try world.tasks.upsert(mine)
            try world.tasks.upsert(foreign)
        }

        let mineList = try world.committedTasks.tasks(ownerID: ownerID, status: .active)
        #expect(mineList.map(\.name) == ["我的任务"])
        #expect(try world.committedTasks.task(id: foreign.id, ownerID: ownerID) == nil)

        let counts = try world.committedTasks.counts(ownerID: ownerID)
        #expect(counts.active == 1)
        #expect(counts.total == 1)
    }

    /// 计数按三个整体状态分别统计。
    @Test func countsTasksByStatus() throws {
        let world = try SwiftDataTestWorld()
        let ownerID = AccountID()
        let active = try world.makeTodoTask(ownerID: ownerID, name: "进行中")
        var completed = try world.makeTodoTask(ownerID: ownerID, name: "已完成")
        var abandoned = try world.makeTodoTask(ownerID: ownerID, name: "已放弃")
        let instant = Date(timeIntervalSince1970: 1_792_003_600)

        try completed.complete(now: instant, isLockedByTimer: false)
        try abandoned.abandon(now: instant, isLockedByTimer: false)

        try world.transaction.perform {
            try world.tasks.upsert(active)
            try world.tasks.upsert(completed)
            try world.tasks.upsert(abandoned)
        }

        let counts = try world.committedTasks.counts(ownerID: ownerID)
        #expect(counts.active == 1)
        #expect(counts.completed == 1)
        #expect(counts.abandoned == 1)
        #expect(counts.total == 3)
    }

    /// 其他账户不能删除该任务，所属账户删除后任务不再存在。
    @Test func deletesTaskForOwningAccountOnly() throws {
        let world = try SwiftDataTestWorld()
        let ownerID = AccountID()
        let task = try world.makeTodoTask(ownerID: ownerID)

        try world.transaction.perform { try world.tasks.upsert(task) }
        try world.transaction.perform { try world.tasks.delete(id: task.id, ownerID: AccountID()) }
        #expect(try world.committedTasks.task(id: task.id, ownerID: ownerID) != nil)

        try world.transaction.perform { try world.tasks.delete(id: task.id, ownerID: ownerID) }
        #expect(try world.committedTasks.task(id: task.id, ownerID: ownerID) == nil)
    }
}

/// 校验 SwiftData 会话查询仓储按任务与账户推导计数与累计时长。
@MainActor
@Suite("SwiftData 会话查询")
struct SwiftDataSessionRepositoryTests {
    /// 记录两条会话后按任务推导计数与累计时长。
    @Test func derivesCountAndDurationByTask() throws {
        let world = try SwiftDataTestWorld()
        let ownerID = AccountID()
        let task = try world.makeTodoTask(ownerID: ownerID)

        try world.context.insert(
            FocusSessionRecord(
                ownerID: ownerID.rawValue,
                taskID: task.id,
                taskNameSnapshot: task.name,
                startedAt: Date(timeIntervalSince1970: 1_792_000_000),
                endedAt: Date(timeIntervalSince1970: 1_792_001_500),
                plannedDurationSeconds: 1500,
                focusDurationSeconds: 1500,
                localDateKey: TaskTestWorld.today.key,
                timeZoneIdentifier: "Asia/Shanghai",
                createdAt: Date(timeIntervalSince1970: 1_792_001_500)
            )
        )
        try world.context.insert(
            FocusSessionRecord(
                ownerID: ownerID.rawValue,
                taskID: task.id,
                taskNameSnapshot: task.name,
                startedAt: Date(timeIntervalSince1970: 1_792_010_000),
                endedAt: Date(timeIntervalSince1970: 1_792_010_600),
                plannedDurationSeconds: 1500,
                focusDurationSeconds: 600,
                localDateKey: TaskTestWorld.today.key,
                timeZoneIdentifier: "Asia/Shanghai",
                createdAt: Date(timeIntervalSince1970: 1_792_010_600)
            )
        )
        try world.transaction.perform {}

        #expect(try world.sessions.completedSessionCount(taskID: task.id, ownerID: ownerID) == 2)
        #expect(try world.sessions.totalFocusDurationSeconds(taskID: task.id, ownerID: ownerID) == 2100)
        #expect(try world.sessions.completedSessionCount(taskID: task.id, ownerID: AccountID()) == 0)
    }
}
