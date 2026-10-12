import Foundation
import Testing
@testable import Focusory

/// 校验创建、编辑、完成、放弃与删除用例的事务边界与账户隔离。
@MainActor
@Suite("任务生命周期用例")
struct TaskLifecycleCommandTests {
    /// 创建任务会与待同步变更一起提交。
    @Test func createsTaskWithSyncChangeInOneCommit() throws {
        let world = TaskTestWorld()
        let task = try CreateTaskCommand(environment: world.environment)
            .execute(draft: TaskDraft(name: "新任务", mode: .todo, todoTarget: 3))

        let saved = try #require(world.savedTask(id: task.id))
        #expect(saved.name == "新任务")
        #expect(saved.ownerID == world.ownerID)

        let change = try #require(world.store.syncQueue.values.first)
        #expect(world.store.syncQueue.count == 1)
        #expect(change.entityType == .task)
        #expect(change.entityID == task.id)
        #expect(change.operationType == .created)
        #expect(change.ownerID == world.ownerID)
    }

    /// 本地提交失败时任务与待同步变更一起回滚。
    @Test func rollsBackTaskAndSyncChangeOnCommitFailure() throws {
        let world = TaskTestWorld()
        world.store.commitFailure = TaskFailure(.persistenceFailed)

        let failure = captureTaskFailure {
            _ = try CreateTaskCommand(environment: world.environment)
                .execute(draft: TaskDraft(name: "写不进去", mode: .todo, todoTarget: 1))
        }

        #expect(failure.code == .persistenceFailed)
        #expect(world.store.tasks.isEmpty)
        #expect(world.store.syncQueue.isEmpty)
    }

    /// 编辑任务会保存新字段并留下更新变更。
    @Test func updatesTaskFieldsAndEnqueuesChange() throws {
        let world = TaskTestWorld()
        let task = try world.seedTask(name: "旧名称", todoTarget: 2)

        let updated = try UpdateTaskCommand(environment: world.environment).execute(
            taskID: task.id,
            draft: TaskDraft(name: "新名称", mode: .todo, todoTarget: 5)
        )

        #expect(updated.name == "新名称")
        #expect(updated.todoTarget == 5)
        #expect(updated.version == 2)
        #expect(world.store.syncQueue.values.map(\.operationType) == [.updated])
    }

    /// 任务不存在或不属于当前账户时统一返回不可用。
    @Test func rejectsUnavailableTasks() throws {
        let world = TaskTestWorld()
        let foreignTask = try world.seedTask(name: "别人的任务", ownerID: world.otherOwnerID)

        let missing = captureTaskFailure {
            _ = try UpdateTaskCommand(environment: world.environment)
                .execute(taskID: UUID(), draft: TaskDraft(name: "任意", mode: .todo, todoTarget: 1))
        }
        #expect(missing.code == .taskUnavailable)

        let foreign = captureTaskFailure {
            _ = try UpdateTaskCommand(environment: world.environment)
                .execute(taskID: foreignTask.id, draft: TaskDraft(name: "任意", mode: .todo, todoTarget: 1))
        }
        #expect(foreign.code == .taskUnavailable)
        #expect(world.savedTask(id: foreignTask.id)?.name == "别人的任务")
    }

    /// 完成与放弃都写入终态并留下更新变更。
    @Test func completesAndAbandonsTasks() throws {
        let world = TaskTestWorld()
        let toComplete = try world.seedTask(name: "要完成")
        let toAbandon = try world.seedTask(name: "要放弃")

        let completed = try CompleteTaskCommand(environment: world.environment).execute(taskID: toComplete.id)
        let abandoned = try AbandonTaskCommand(environment: world.environment).execute(taskID: toAbandon.id)

        #expect(completed.status == .completed)
        #expect(abandoned.status == .abandoned)
        #expect(try world.environment.tasks.counts(ownerID: world.ownerID).completed == 1)
        #expect(try world.environment.tasks.counts(ownerID: world.ownerID).abandoned == 1)
    }

    /// 计时锁定时不能完成或放弃，数据保持原状。
    @Test func rejectsLifecycleChangeWhileTimerLocked() throws {
        let world = TaskTestWorld()
        let task = try world.seedTask(name: "正在专注")
        world.timer.lockedTaskIDs = [task.id]

        let failure = captureTaskFailure {
            _ = try CompleteTaskCommand(environment: world.environment).execute(taskID: task.id)
        }

        #expect(failure.code == .taskLockedByTimer)
        #expect(world.savedTask(id: task.id)?.status == .active)
        #expect(world.store.syncQueue.isEmpty)
    }

    /// 无历史任务可以删除并留下删除变更。
    @Test func deletesTaskWithoutHistory() throws {
        let world = TaskTestWorld()
        let task = try world.seedTask(name: "没有记录")

        try DeleteTaskCommand(environment: world.environment).execute(taskID: task.id)

        #expect(world.savedTask(id: task.id) == nil)
        let change = try #require(world.store.syncQueue.values.first)
        #expect(change.operationType == .deleted)
        #expect(change.entityID == task.id)
    }

    /// 有历史任务只能放弃，删除被拒绝且数据不变。
    @Test func rejectsDeletingTaskWithHistory() throws {
        let world = TaskTestWorld()
        let task = try world.seedTask(name: "有记录")
        world.seedSessions(count: 1, taskID: task.id)

        let failure = captureTaskFailure {
            try DeleteTaskCommand(environment: world.environment).execute(taskID: task.id)
        }

        #expect(failure.code == .taskHasHistory)
        #expect(world.savedTask(id: task.id) != nil)
        #expect(world.store.syncQueue.isEmpty)
    }

    /// 计时锁定时不能删除。
    @Test func rejectsDeletingTaskWhileTimerLocked() throws {
        let world = TaskTestWorld()
        let task = try world.seedTask(name: "正在专注")
        world.timer.lockedTaskIDs = [task.id]

        let failure = captureTaskFailure {
            try DeleteTaskCommand(environment: world.environment).execute(taskID: task.id)
        }

        #expect(failure.code == .taskLockedByTimer)
        #expect(world.savedTask(id: task.id) != nil)
    }

    /// 编辑终态任务被拒绝。
    @Test func rejectsEditingTerminalTask() throws {
        let world = TaskTestWorld()
        let task = try world.seedTask(name: "已完成任务")
        _ = try CompleteTaskCommand(environment: world.environment).execute(taskID: task.id)

        let failure = captureTaskFailure {
            _ = try UpdateTaskCommand(environment: world.environment).execute(
                taskID: task.id,
                draft: TaskDraft(name: "改个名", mode: .todo, todoTarget: 3)
            )
        }

        #expect(failure.code == .taskNotActive)
        #expect(world.savedTask(id: task.id)?.name == "已完成任务")
    }
}
