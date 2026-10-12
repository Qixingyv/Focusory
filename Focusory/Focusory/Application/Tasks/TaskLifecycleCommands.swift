import Foundation

/// 创建当前账户的任务，并与待同步变更一起原子提交。
struct CreateTaskCommand {
    /// 用例依赖。
    let environment: TaskUseCaseEnvironment

    /// 校验草稿并保存进行中任务。
    /// - 失败：字段非法时抛字段化错误；本地提交失败时抛 `TaskFailure(.persistenceFailed)`。
    func execute(draft: TaskDraft) throws -> FocusTask {
        let ownerID = environment.account.currentAccountID
        let now = environment.clock.now
        let today = environment.calendar.localDate(for: now)
        let task = try FocusTask.create(draft: draft, ownerID: ownerID, today: today, now: now)

        try environment.commit {
            try environment.tasks.upsert(task)
            try environment.enqueueChange(
                entityType: .task,
                entityID: task.id,
                operationType: .created,
                ownerID: ownerID,
                now: now
            )
        }
        return task
    }
}

/// 编辑当前账户任务的允许字段；模式与已产生会话后的配置开关不可改。
struct UpdateTaskCommand {
    /// 用例依赖。
    let environment: TaskUseCaseEnvironment

    /// 校验草稿并保存任务；本地提交失败时任务与队列一起回滚。
    func execute(taskID: UUID, draft: TaskDraft) throws -> FocusTask {
        let ownerID = environment.account.currentAccountID
        let now = environment.clock.now
        let today = environment.calendar.localDate(for: now)

        var task = try environment.requireTask(id: taskID, ownerID: ownerID)
        let hasHistory = try environment.hasHistory(taskID: taskID, ownerID: ownerID)
        try task.apply(draft, today: today, hasHistory: hasHistory, now: now)

        try environment.commit {
            try environment.tasks.upsert(task)
            try environment.enqueueChange(
                entityType: .task,
                entityID: task.id,
                operationType: .updated,
                ownerID: ownerID,
                now: now
            )
        }
        return task
    }
}

/// 手动最终完成当前账户的任务；进入不可恢复的终态。
struct CompleteTaskCommand {
    /// 用例依赖。
    let environment: TaskUseCaseEnvironment

    /// 完成指定任务；正被计时锁定或已是终态时抛出业务错误。
    func execute(taskID: UUID) throws -> FocusTask {
        let ownerID = environment.account.currentAccountID
        let now = environment.clock.now

        var task = try environment.requireTask(id: taskID, ownerID: ownerID)
        try task.complete(now: now, isLockedByTimer: environment.focusTimer.isTaskLocked(taskID: taskID))

        try environment.commit {
            try environment.tasks.upsert(task)
            try environment.enqueueChange(
                entityType: .task,
                entityID: task.id,
                operationType: .updated,
                ownerID: ownerID,
                now: now
            )
        }
        return task
    }
}

/// 放弃当前账户的任务；保留历史会话与统计。
struct AbandonTaskCommand {
    /// 用例依赖。
    let environment: TaskUseCaseEnvironment

    /// 放弃指定任务；正被计时锁定或已是终态时抛出业务错误。
    func execute(taskID: UUID) throws -> FocusTask {
        let ownerID = environment.account.currentAccountID
        let now = environment.clock.now

        var task = try environment.requireTask(id: taskID, ownerID: ownerID)
        try task.abandon(now: now, isLockedByTimer: environment.focusTimer.isTaskLocked(taskID: taskID))

        try environment.commit {
            try environment.tasks.upsert(task)
            try environment.enqueueChange(
                entityType: .task,
                entityID: task.id,
                operationType: .updated,
                ownerID: ownerID,
                now: now
            )
        }
        return task
    }
}

/// 删除没有历史会话的进行中任务，并留下幂等的删除变更。
struct DeleteTaskCommand {
    /// 用例依赖。
    let environment: TaskUseCaseEnvironment

    /// 删除指定任务。
    /// - 失败：已有会话时抛 `TaskFailure(.taskHasHistory)`，正被计时锁定时抛 `TaskFailure(.taskLockedByTimer)`。
    func execute(taskID: UUID) throws {
        let ownerID = environment.account.currentAccountID
        let now = environment.clock.now

        let task = try environment.requireTask(id: taskID, ownerID: ownerID)
        guard task.isActive else {
            throw TaskFailure(.taskNotActive)
        }
        let hasHistory = try environment.hasHistory(taskID: taskID, ownerID: ownerID)
        guard !hasHistory else {
            throw TaskFailure(.taskHasHistory)
        }
        guard !environment.focusTimer.isTaskLocked(taskID: taskID) else {
            throw TaskFailure(.taskLockedByTimer)
        }

        try environment.commit {
            try environment.tasks.delete(id: taskID, ownerID: ownerID)
            try environment.enqueueChange(
                entityType: .task,
                entityID: taskID,
                operationType: .deleted,
                ownerID: ownerID,
                now: now
            )
        }
    }
}
