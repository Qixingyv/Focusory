import Foundation
import Testing
@testable import Focusory

/// 校验本地事务的提交与整体回滚语义。
@MainActor
@Suite("SwiftData 本地事务")
struct SwiftDataLocalTransactionTests {
    /// 事务内的写入会在结束时一次提交。
    @Test func commitsTaskAndSyncChangeTogether() throws {
        let world = try SwiftDataTestWorld()
        let ownerID = AccountID()
        let task = try world.makeTodoTask(ownerID: ownerID)
        let change = SyncQueueItem(
            operationID: UUID(),
            ownerID: ownerID,
            entityType: .task,
            entityID: task.id,
            operationType: .created,
            createdAt: Date(timeIntervalSince1970: 1_792_000_000)
        )

        try world.transaction.perform {
            try world.tasks.upsert(task)
            try world.syncQueue.enqueue(change)
        }

        #expect(try world.committedTasks.task(id: task.id, ownerID: ownerID) != nil)
        #expect(try world.committedSyncQueue.item(operationID: change.operationID, ownerID: ownerID) != nil)
    }

    /// 事务内抛错时任务与同步变更一起回滚，不留下部分结果。
    @Test func rollsBackAllWritesWhenWorkThrows() throws {
        let world = try SwiftDataTestWorld()
        let ownerID = AccountID()
        let task = try world.makeTodoTask(ownerID: ownerID)
        let change = SyncQueueItem(
            operationID: UUID(),
            ownerID: ownerID,
            entityType: .task,
            entityID: task.id,
            operationType: .created,
            createdAt: Date(timeIntervalSince1970: 1_792_000_000)
        )

        let failure = captureTaskFailure {
            try world.transaction.perform {
                try world.tasks.upsert(task)
                try world.syncQueue.enqueue(change)
                throw TaskFailure(.persistenceFailed)
            }
        }

        #expect(failure.code == .persistenceFailed)
        #expect(try world.committedTasks.task(id: task.id, ownerID: ownerID) == nil)
        #expect(try world.committedSyncQueue.item(operationID: change.operationID, ownerID: ownerID) == nil)
    }

    /// 事务在仓储只写入一条记录时也能正确提交。
    @Test func commitsSingleWrite() throws {
        let world = try SwiftDataTestWorld()
        let ownerID = AccountID()
        let task = try world.makeTodoTask(ownerID: ownerID)

        try world.transaction.perform { try world.tasks.upsert(task) }

        let counts = try world.committedTasks.counts(ownerID: ownerID)
        #expect(counts.active == 1)
    }
}

/// 校验每日进度仓储的「任务 + 本机日期」唯一性与读写往返。
@MainActor
@Suite("SwiftData 每日进度仓储")
struct SwiftDataDailyProgressRepositoryTests {
    /// 同一任务与日期重复保存只保留一条记录。
    @Test func keepsSingleRecordPerTaskAndLocalDate() throws {
        let world = try SwiftDataTestWorld()
        let ownerID = AccountID()
        let task = try world.makeOngoingTask(ownerID: ownerID)
        var progress = try TaskDailyProgress.create(
            ownerID: ownerID,
            taskID: task.id,
            localDate: TaskTestWorld.today,
            timeZoneID: FixedCalendarProvider().timeZoneID,
            targetSnapshot: 2,
            now: Date(timeIntervalSince1970: 1_792_000_000)
        )

        try world.transaction.perform { try world.dailyProgress.upsert(progress) }

        progress.recordCompletedSession(focusDurationSeconds: 1500, now: Date(timeIntervalSince1970: 1_792_001_500))
        try world.transaction.perform { try world.dailyProgress.upsert(progress) }

        let reloaded = try #require(
            try world.committedDailyProgress.progress(
                taskID: task.id,
                ownerID: ownerID,
                localDate: TaskTestWorld.today
            )
        )
        #expect(reloaded.completedPomodoroCount == 1)
        #expect(reloaded.focusDurationSeconds == 1500)
        #expect(reloaded.targetSnapshot == 2)

        #expect(
            try world.committedDailyProgress.progress(
                taskID: task.id,
                ownerID: ownerID,
                localDate: makeLocalDate("2026-10-12")
            ) == nil
        )
    }
}

/// 校验同步队列仓储的幂等入队与按操作标识查询。
@MainActor
@Suite("SwiftData 同步队列仓储")
struct SwiftDataSyncQueueRepositoryTests {
    /// 同一操作标识重复入队不会产生第二条待上传操作。
    @Test func enqueuesOperationIdentifierOnce() throws {
        let world = try SwiftDataTestWorld()
        let ownerID = AccountID()
        let operationID = UUID()
        let change = SyncQueueItem(
            operationID: operationID,
            ownerID: ownerID,
            entityType: .task,
            entityID: UUID(),
            operationType: .targetAppended,
            createdAt: Date(timeIntervalSince1970: 1_792_000_000)
        )

        try world.transaction.perform {
            try world.syncQueue.enqueue(change)
            try world.syncQueue.enqueue(change)
        }

        let stored = try #require(try world.committedSyncQueue.item(operationID: operationID, ownerID: ownerID))
        #expect(stored.operationType == .targetAppended)
        #expect(stored.status == .pending)
        #expect(stored.payloadSchemaVersion == SyncQueueItem.currentPayloadSchemaVersion)
    }

    /// 队列项按账户隔离，其他账户查不到。
    @Test func isolatesQueueItemsByOwner() throws {
        let world = try SwiftDataTestWorld()
        let ownerID = AccountID()
        let operationID = UUID()
        let change = SyncQueueItem(
            operationID: operationID,
            ownerID: ownerID,
            entityType: .task,
            entityID: UUID(),
            operationType: .deleted,
            createdAt: Date(timeIntervalSince1970: 1_792_000_000)
        )

        try world.transaction.perform { try world.syncQueue.enqueue(change) }

        #expect(try world.committedSyncQueue.item(operationID: operationID, ownerID: ownerID) != nil)
        #expect(try world.committedSyncQueue.item(operationID: operationID, ownerID: AccountID()) == nil)
    }
}
