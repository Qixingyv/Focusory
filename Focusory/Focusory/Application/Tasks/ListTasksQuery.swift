import Foundation

/// 查询当前账户的任务列表与三状态计数。
struct ListTasksQuery {
    /// 用例依赖。
    let environment: TaskUseCaseEnvironment

    /// 生成指定状态的任务列表快照；失败时抛 `TaskFailure(.persistenceFailed)`。
    func execute(status: FocusTaskStatus) throws -> TaskListSnapshot {
        let ownerID = environment.account.currentAccountID
        let today = environment.calendar.localDate(for: environment.clock.now)

        return try environment.read {
            let counts = try environment.tasks.counts(ownerID: ownerID)
            let tasks = try environment.tasks.tasks(ownerID: ownerID, status: status)
            let items = try TaskSorting.sorted(tasks, status: status).map { task in
                try makeItem(task: task, ownerID: ownerID, today: today)
            }
            return TaskListSnapshot(status: status, items: items, counts: counts)
        }
    }

    /// 组装单个列表项，推导完成数、有效目标、达标反馈与开始可用性。
    private func makeItem(task: FocusTask, ownerID: AccountID, today: LocalDate) throws -> TaskListItem {
        let completedCount = try environment.sessions.completedSessionCount(taskID: task.id, ownerID: ownerID)
        let totalFocusDuration = try environment.sessions.totalFocusDurationSeconds(taskID: task.id, ownerID: ownerID)

        var effectiveTarget: Int?
        var todayCompletedCount: Int?
        switch task.mode {
        case .todo:
            effectiveTarget = task.todoTarget
        case .ongoing:
            guard task.hasDailyTarget else { break }
            let progress = try environment.dailyProgress.progress(
                taskID: task.id,
                ownerID: ownerID,
                localDate: today
            )
            // 今日还没有会话时不存在快照，界面按每日基础目标展示预计目标。
            effectiveTarget = progress?.effectiveTarget ?? task.dailyTarget
            todayCompletedCount = progress?.completedPomodoroCount ?? 0
        }

        let feedback = TaskGoalFeedback.resolve(
            completedPomodoroCount: todayCompletedCount ?? completedCount,
            effectiveTarget: effectiveTarget
        )
        let isStartable: Bool
        if case .allowed = task.decideStart(today: today) {
            isStartable = true
        } else {
            isStartable = false
        }

        return TaskListItem(
            task: task,
            completedPomodoroCount: completedCount,
            totalFocusDurationSeconds: totalFocusDuration,
            effectiveTarget: effectiveTarget,
            todayCompletedPomodoroCount: todayCompletedCount,
            goalFeedback: feedback,
            hasHistory: completedCount > 0,
            isStartable: isStartable
        )
    }
}
