import Foundation

/// 待办按计划完成后追加总目标；只修改目标与待同步变更。
struct AppendTodoTargetCommand {
    /// 追加目标所需的仓储、事务、账户和时间等能力。
    let environment: TaskUseCaseEnvironment

    /// 追加待办总目标。
    /// - 失败：数量非正、任务不可用、已终态、非待办或尚未按计划完成时抛业务错误。
    /// - 幂等：同一 `operationID` 已生效时返回 `isReplay` 结果，不再次增加目标。
    func execute(taskID: UUID, quantity: Int, operationID: UUID) throws -> GoalAdjustmentResult {
        let ownerID = environment.account.currentAccountID
        let now = environment.clock.now

        if try environment.isOperationApplied(operationID: operationID, ownerID: ownerID) {
            return try replayResult(taskID: taskID, ownerID: ownerID)
        }

        var task = try environment.requireTask(id: taskID, ownerID: ownerID)
        let completedCount = try environment.read {
            try environment.sessions.completedSessionCount(taskID: taskID, ownerID: ownerID)
        }
        let result = try task.appendTodoTarget(quantity, completedPomodoroCount: completedCount, now: now)

        try environment.commit {
            try environment.tasks.upsert(task)
            try environment.enqueueChange(
                entityType: .task,
                entityID: task.id,
                operationType: .targetAppended,
                ownerID: ownerID,
                now: now,
                operationID: operationID
            )
        }
        return result
    }

    /// 组装同一操作重放时的结果，反映当前数据而不改变目标。
    private func replayResult(taskID: UUID, ownerID: AccountID) throws -> GoalAdjustmentResult {
        try environment.read {
            guard let task = try environment.tasks.task(id: taskID, ownerID: ownerID) else {
                throw TaskFailure(.taskUnavailable)
            }
            let completedCount = try environment.sessions.completedSessionCount(taskID: taskID, ownerID: ownerID)
            let currentTarget = task.todoTarget ?? completedCount
            return GoalAdjustmentResult(
                previousTarget: currentTarget,
                newTarget: currentTarget,
                completedPomodoroCount: completedCount,
                isReplay: true
            )
        }
    }
}

/// 持续任务今日达标后追加当日目标；只修改当前本机日期的当日追加数。
struct AppendDailyTargetCommand {
    /// 追加目标所需的仓储、事务、账户和时间等能力。
    let environment: TaskUseCaseEnvironment

    /// 追加当日目标。
    /// - 失败：本机日期已变化、数量非正、任务不可用、已终态、未开启每日目标或今日尚未达标时抛业务错误。
    /// - 幂等：同一 `operationID` 已生效时返回 `isReplay` 结果，不再次增加当日目标。
    func execute(
        taskID: UUID,
        quantity: Int,
        expectedLocalDate: LocalDate,
        operationID: UUID
    ) throws -> GoalAdjustmentResult {
        let ownerID = environment.account.currentAccountID
        let now = environment.clock.now

        // 跨零点后不得把追加写入上一日：先复核本机日期，再读取当日进度。
        let today = environment.calendar.localDate(for: now)
        guard today == expectedLocalDate else {
            throw TaskFailure(.localDateChanged)
        }

        if try environment.isOperationApplied(operationID: operationID, ownerID: ownerID) {
            return try replayResult(taskID: taskID, ownerID: ownerID, localDate: today)
        }

        let task = try environment.requireTask(id: taskID, ownerID: ownerID)
        guard task.isActive else {
            throw TaskFailure(.taskNotActive)
        }
        guard task.mode == .ongoing, task.hasDailyTarget else {
            throw TaskFailure(.appendNotAllowed)
        }

        guard var progress = try environment.read({
            try environment.dailyProgress.progress(taskID: taskID, ownerID: ownerID, localDate: today)
        }) else {
            throw TaskFailure(.appendNotAllowed)
        }
        let result = try progress.appendTarget(quantity, now: now)

        try environment.commit {
            try environment.dailyProgress.upsert(progress)
            try environment.enqueueChange(
                entityType: .taskDailyProgress,
                entityID: progress.id,
                operationType: .targetAppended,
                ownerID: ownerID,
                now: now,
                operationID: operationID
            )
        }
        return result
    }

    /// 组装同一操作重放时的结果，反映当日进度而不改变追加数。
    private func replayResult(taskID: UUID, ownerID: AccountID, localDate: LocalDate) throws -> GoalAdjustmentResult {
        try environment.read {
            let progress = try environment.dailyProgress.progress(
                taskID: taskID,
                ownerID: ownerID,
                localDate: localDate
            )
            let currentTarget = progress?.effectiveTarget ?? 0
            return GoalAdjustmentResult(
                previousTarget: currentTarget,
                newTarget: currentTarget,
                completedPomodoroCount: progress?.completedPomodoroCount ?? 0,
                isReplay: true
            )
        }
    }
}
