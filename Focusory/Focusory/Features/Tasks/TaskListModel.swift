import Foundation

/// 任务页一次性提示；界面在页面顶部弱化显示，不使用阻断弹窗。
enum TaskNotice: Equatable, Sendable {
    /// 命令失败原因。
    case failure(TaskFailure)
    /// 持续任务尚未到计划开始日。
    case notYetStarted(LocalDate)
}

/// 保存任务列表状态，处理页面操作并调用业务用例。
@Observable
final class TaskListModel {
    /// 执行任务查询和修改所需的业务能力，由上层传入。
    private let environment: TaskUseCaseEnvironment
    /// 当前显示哪类任务，决定列表查询和筛选项的选中状态。
    var selectedStatus: FocusTaskStatus = .active
    /// 最近一次查询成功的任务和计数；查询失败时保留，首次成功前为空。
    private(set) var snapshot: TaskListSnapshot?
    /// 记录任务查询是否正在执行。
    private(set) var isLoading = false
    /// 列表查询的失败原因；非空时显示重试界面，避免误显示为没有任务。
    private(set) var loadFailure: TaskFailure?
    /// 页面顶部要显示的操作提示；为空时隐藏提示条。
    private(set) var notice: TaskNotice?
    /// 当前选中用于专注的任务，供列表突出显示。
    private(set) var selectedTaskID: UUID?

    /// 接收任务用例依赖，供后续查询和操作使用。
    init(environment: TaskUseCaseEnvironment) {
        self.environment = environment
    }

    /// 最近一次成功查询的列表项，供页面显示；尚未查询成功时为空。
    var items: [TaskListItem] {
        snapshot?.items ?? []
    }

    /// 进行中、已完成和已放弃的任务数，供筛选栏显示；首次查询成功前为 0。
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

    /// 设置要在页面顶部显示的一次性提示。
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

    /// 执行操作后刷新列表；操作失败时在页面顶部显示原因。
    private func run(_ work: () throws -> Void) {
        do {
            try work()
            reload()
        } catch {
            notice = .failure(asTaskFailure(error))
        }
    }

    /// 保留业务错误，将其他错误统一转为持久化失败。
    private func asTaskFailure(_ error: Error) -> TaskFailure {
        (error as? TaskFailure) ?? TaskFailure(.persistenceFailed)
    }
}
