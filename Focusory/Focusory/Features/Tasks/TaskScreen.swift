import Foundation
import SwiftUI

/// 显示按状态筛选的任务列表，并承载任务创建、编辑与目标追加入口的页面。
struct TaskScreen: View {
    /// 任务页界面状态。
    let model: TaskListModel
    /// 在用户从任务行开始专注后请求上层切换到专注页。
    let onStartFocus: () -> Void

    /// 保存当前交给编辑弹窗的列表项，空值表示未编辑现有任务。
    @State private var taskBeingEdited: TaskListItem?
    /// 表示新建任务编辑弹窗是否正在显示。
    @State private var isNewTaskEditorPresented = false

    /// 根据筛选结果显示工具栏、提示、加载错误、空状态或任务列表。
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            taskToolbar

            if let notice = model.notice {
                noticeBanner(notice)
            }

            content
        }
        .frame(maxWidth: FocusoryMetrics.mainContentWidth, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, FocusoryMetrics.pageHorizontalPadding)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .task {
            model.reload()
        }
        .sheet(isPresented: $isNewTaskEditorPresented) {
            TaskEditorSheet(
                hasHistory: false,
                calendar: model.calendar,
                onSave: { draft in model.createTask(draft: draft) }
            )
        }
        .sheet(item: $taskBeingEdited) { item in
            TaskEditorSheet(
                task: item.task,
                hasHistory: item.hasHistory,
                calendar: model.calendar,
                onSave: { draft in model.updateTask(id: item.id, draft: draft) }
            )
        }
    }

    /// 显示任务状态筛选器和新建任务入口的页面工具栏。
    private var taskToolbar: some View {
        HStack(spacing: 16) {
            FocusorySegmentedControl(
                selectedValue: Binding(
                    get: { model.selectedStatus },
                    set: { model.select(status: $0) }
                ),
                items: FocusTaskStatus.allCases.map { status in
                    FocusorySegmentedItem(
                        value: status,
                        title: .tasksStatusFilterCount(
                            String(localized: status.localizedTitle),
                            model.counts[status]
                        ),
                        accessibilityIdentifier: "task-status-\(status.rawValue)"
                    )
                }
            )

            Spacer(minLength: 12)

            Button {
                isNewTaskEditorPresented = true
            } label: {
                Label(.tasksActionCreate, systemImage: "plus")
            }
            .focusoryPrimaryButton(
                horizontalPadding: 18,
                minHeight: 34,
                cornerRadius: 10,
                font: FocusoryTypography.supportingEmphasized
            )
            .accessibilityIdentifier("task-create-button")
        }
    }

    /// 在页头弱化显示一次性提示，不打断列表交互。
    private func noticeBanner(_ notice: TaskNotice) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(FocusoryTypography.icon)
                .foregroundStyle(Color.focusoryWarning)

            Text(notice.localizedMessage)
                .font(FocusoryTypography.supporting)
                .foregroundStyle(Color.focusoryTextSecondary)
                .accessibilityIdentifier("task-notice-message")

            Spacer(minLength: 8)

            Button(.commonActionConfirm) {
                model.dismissNotice()
            }
            .buttonStyle(.plain)
            .font(FocusoryTypography.supportingEmphasized)
            .foregroundStyle(Color.focusoryTextTertiary)
            .accessibilityIdentifier("task-notice-dismiss")
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 32)
        .background(Color.focusorySurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.focusoryBorder, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("task-notice")
    }

    /// 按加载状态在错误、空状态和任务列表之间选择。
    @ViewBuilder
    private var content: some View {
        if let loadFailure = model.loadFailure {
            loadFailureState(loadFailure)
        } else if model.items.isEmpty {
            emptyState
        } else {
            taskList
        }
    }

    /// 显示读取本地数据失败的可重试状态；不显示成空列表，避免被误认为任务丢失。
    private func loadFailureState(_ failure: TaskFailure) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle")
                .font(FocusoryTypography.pageIcon)
                .foregroundStyle(Color.focusoryWarning)

            Text(failure.code.localizedMessage)
                .font(FocusoryTypography.supporting)
                .foregroundStyle(Color.focusoryTextSecondary)

            Button(.tasksErrorRetry) {
                model.reload()
            }
            .focusoryPrimaryButton(
                horizontalPadding: 16,
                minHeight: 30,
                cornerRadius: 9,
                font: FocusoryTypography.supportingEmphasized
            )
            .accessibilityIdentifier("task-error-retry-button")
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .background(Color.focusorySurface)
        .clipShape(RoundedRectangle(cornerRadius: FocusoryMetrics.cardRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: FocusoryMetrics.cardRadius, style: .continuous)
                .stroke(Color.focusoryBorder, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("task-error-state")
    }

    /// 在当前筛选条件没有任务时提供对应说明与可用操作。
    private var emptyState: some View {
        VStack(spacing: 18) {
            Circle()
                .fill(emptyStateIconBackground)
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: emptyStateSymbol)
                        .font(FocusoryTypography.pageIcon)
                        .foregroundStyle(emptyStateIconColor)
                }

            VStack(spacing: 6) {
                Text(emptyStateTitle)
                    .font(FocusoryTypography.sectionTitle)
                    .foregroundStyle(Color.focusoryTextPrimary)

                Text(emptyStateDescription)
                    .font(FocusoryTypography.supporting)
                    .foregroundStyle(Color.focusoryTextTertiary)
            }

            if model.selectedStatus == .active {
                Button {
                    isNewTaskEditorPresented = true
                } label: {
                    Label(.tasksActionCreateFirst, systemImage: "plus")
                }
                .focusoryPrimaryButton(
                    horizontalPadding: 16,
                    minHeight: 32,
                    cornerRadius: 9,
                    font: FocusoryTypography.supportingEmphasized
                )
                .accessibilityIdentifier("task-create-first-button")
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .background(Color.focusorySurface)
        .clipShape(RoundedRectangle(cornerRadius: FocusoryMetrics.cardRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: FocusoryMetrics.cardRadius, style: .continuous)
                .stroke(Color.focusoryBorder, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("task-empty-state")
    }

    /// 按查询顺序显示当前可见任务及其交互回调。
    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: model.selectedStatus == .active ? 10 : 8) {
                ForEach(model.items) { item in
                    TaskCard(
                        item: item,
                        isSelected: model.selectedTaskID == item.id,
                        onStart: {
                            if model.startFocus(taskID: item.id) {
                                onStartFocus()
                            }
                        },
                        onComplete: { model.completeTask(id: item.id) },
                        onEdit: { taskBeingEdited = item },
                        onRemove: { model.removeTask(id: item.id) },
                        onAppendTarget: { quantity in
                            appendTarget(for: item, quantity: quantity)
                        }
                    )
                }
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    /// 按任务模式把追加数量交给对应命令，并在页头提示失败原因。
    private func appendTarget(for item: TaskListItem, quantity: Int) {
        let failure: TaskFailure?
        switch item.task.mode {
        case .todo:
            failure = model.appendTodoTarget(taskID: item.id, quantity: quantity)
        case .ongoing:
            failure = model.appendDailyTarget(taskID: item.id, quantity: quantity)
        }
        if let failure {
            model.showNotice(.failure(failure))
        }
    }

    /// 返回与当前任务状态匹配的空状态图标。
    private var emptyStateSymbol: String {
        switch model.selectedStatus {
        case .active: "checklist"
        case .completed: "checkmark.circle"
        case .abandoned: "archivebox"
        }
    }

    /// 返回与当前任务状态匹配的空状态标题。
    private var emptyStateTitle: LocalizedStringResource {
        switch model.selectedStatus {
        case .active: .tasksEmptyActiveTitle
        case .completed: .tasksEmptyCompletedTitle
        case .abandoned: .tasksEmptyAbandonedTitle
        }
    }

    /// 返回与当前任务状态匹配的空状态说明。
    private var emptyStateDescription: LocalizedStringResource {
        switch model.selectedStatus {
        case .active: .tasksEmptyActiveDescription
        case .completed: .tasksEmptyCompletedDescription
        case .abandoned: .tasksEmptyAbandonedDescription
        }
    }

    /// 返回空状态图标用于区分活动与历史分类的颜色。
    private var emptyStateIconColor: Color {
        model.selectedStatus == .active ? .focusoryAccent : .focusoryTextQuaternary
    }

    /// 返回空状态图标容器的背景色。
    private var emptyStateIconBackground: Color {
        model.selectedStatus == .active ? .focusoryAccentSurface : .focusoryPageBackground
    }
}

#Preview("任务列表") {
    TaskScreenPreview()
}

/// 使用内存存储渲染任务页预览的包装视图。
private struct TaskScreenPreview: View {
    /// 内存依赖；创建失败时只显示占位文本。
    private let environment: TaskUseCaseEnvironment?

    /// 创建预览并尝试装配内存依赖。
    init() {
        environment = try? AppDependencies.makeInMemory().taskEnvironment
    }

    /// 渲染任务页或占位文本。
    var body: some View {
        if let environment {
            TaskScreen(model: TaskListModel(environment: environment), onStartFocus: {})
                .frame(width: 900, height: 680)
                .background(Color.focusoryPageBackground)
        } else {
            Text(verbatim: "preview unavailable")
        }
    }
}
