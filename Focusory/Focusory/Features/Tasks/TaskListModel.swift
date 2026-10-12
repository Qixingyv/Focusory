import Foundation

/// 任务页一次性提示；界面在页头弱化显示，不使用阻断弹窗。
enum TaskNotice: Equatable, Sendable {
    /// 命令失败原因。
    case failure(TaskFailure)
    /// 持续任务尚未到计划开始日。
    case notYetStarted(LocalDate)
}

/// 任务页面的界面状态：筛选、列表快照、加载结果与最近一次命令结果。
@Observable
final class TaskListModel {
    /// 任务用例依赖。
    private let environment: TaskUseCaseEnvironment
    /// 当前分段筛选。
    var selectedStatus: FocusTaskStatus = .active
    /// 最近一次成功加载的列表快照；为空表示还没有成功加载过。
    private(set) var snapshot: TaskListSnapshot?
    /// 表示列表是否正在加载。
    private(set) var isLoading = false
    /// 列表加载失败原因；非空时界面显示可重试错误而不是空状态。
    private(set) var loadFailure: TaskFailure?
    /// 最近一次命令的一次性提示。
    private(set) var notice: TaskNotice?
    /// 当前被选中作为专注对象的任务标识。
    private(set) var selectedTaskID: UUID?

    /// 用任务用例依赖创建界面状态。
    init(environment: TaskUseCaseEnvironment) {
        self.environment = environment
    }

    /// 当前可见的列表项；尚未加载成功时为空。
    var items: [TaskListItem] {
        snapshot?.items ?? []
    }

    /// 三个整体状态的当前计数；尚未加载成功时全部为 0。
    var counts: TaskStatusCounts {
        snapshot?.counts ?? TaskStatusCounts(active: 0, completed: 0, abandoned: 0)
    }

    /// 本机日历；界面把日期选择器结果换算为本机日期时使用。
    var calendar: any CalendarProvider {
        environment.calendar
    }

    /// 重新查询当前筛选下的任务；失败时保留错误码而不清空已有列表。
    func reload() {
        isLoading = true
        defer { isLoading = false }

        do {
            snapshot = try ListTasksQuery(environment: environment).execute(status: selectedStatus)
            loadFailure = nil
        } catch {
            loadFailure = asTaskFailure(error)
        }
    }

    /// 切换分段筛选并重新查询。
    func select(status: FocusTaskStatus) {
        selectedStatus = status
        reload()
    }

    /// 清除最近一次提示。
    func dismissNotice() {
        notice = nil
    }

    /// 在页头显示一次性提示。
    func showNotice(_ notice: TaskNotice) {
        self.notice = notice
    }

    /// 创建任务；成功返回 nil，失败返回原因供表单就地展示。
    func createTask(draft: TaskDraft) -> TaskFailure? {
        do {
            _ = try CreateTaskCommand(environment: environment).execute(draft: draft)
            selectedStatus = .active
            reload()
            return nil
        } catch {
            return asTaskFailure(error)
        }
    }

    /// 保存编辑后的任务；成功返回 nil，失败返回原因供表单就地展示。
    func updateTask(id: UUID, draft: TaskDraft) -> TaskFailure? {
        do {
            _ = try UpdateTaskCommand(environment: environment).execute(taskID: id, draft: draft)
            reload()
            return nil
        } catch {
            return asTaskFailure(error)
        }
    }

    /// 手动完成指定任务。
    func completeTask(id: UUID) {
        run { _ = try CompleteTaskCommand(environment: environment).execute(taskID: id) }
    }

    /// 删除或放弃指定任务；按是否存在历史会话选择命令。
    func removeTask(id: UUID) {
        guard let item = item(id: id) else { return }
        run {
            if item.hasHistory {
                _ = try AbandonTaskCommand(environment: environment).execute(taskID: id)
            } else {
                try DeleteTaskCommand(environment: environment).execute(taskID: id)
            }
        }
    }

    /// 追加待办总目标；成功返回 nil，失败返回原因供追加入口就地展示。
    func appendTodoTarget(taskID: UUID, quantity: Int) -> TaskFailure? {
        do {
            _ = try AppendTodoTargetCommand(environment: environment)
                .execute(taskID: taskID, quantity: quantity, operationID: UUID())
            reload()
            return nil
        } catch {
            return asTaskFailure(error)
        }
    }

    /// 追加持续任务当日目标；成功返回 nil，失败返回原因供追加入口就地展示。
    func appendDailyTarget(taskID: UUID, quantity: Int) -> TaskFailure? {
        let expectedLocalDate = environment.calendar.localDate(for: environment.clock.now)
        do {
            _ = try AppendDailyTargetCommand(environment: environment).execute(
                taskID: taskID,
                quantity: quantity,
                expectedLocalDate: expectedLocalDate,
                operationID: UUID()
            )
            reload()
            return nil
        } catch {
            return asTaskFailure(error)
        }
    }

    /// 从任务行开始专注；成功时选中该任务并返回 true 表示可以切换到专注页。
    @discardableResult
    func startFocus(taskID: UUID) -> Bool {
        do {
            let outcome = try StartFocusFromTaskCommand(environment: environment).execute(taskID: taskID)
            switch outcome {
            case .started:
                selectedTaskID = taskID
                reload()
                return true
            case .rejected(let failure):
                notice = .failure(failure)
                return false
            case .notYetStarted(let startDate):
                notice = .notYetStarted(startDate)
                return false
            }
        } catch {
            notice = .failure(asTaskFailure(error))
            return false
        }
    }

    /// 返回指定标识对应的列表项。
    func item(id: UUID) -> TaskListItem? {
        items.first { $0.id == id }
    }

    /// 执行一个不返回结果的命令，并在失败时记录提示。
    private func run(_ work: () throws -> Void) {
        do {
            try work()
            reload()
        } catch {
            notice = .failure(asTaskFailure(error))
        }
    }

    /// 把任意错误收敛为稳定任务失败结果。
    private func asTaskFailure(_ error: Error) -> TaskFailure {
        (error as? TaskFailure) ?? TaskFailure(.persistenceFailed)
    }
}
