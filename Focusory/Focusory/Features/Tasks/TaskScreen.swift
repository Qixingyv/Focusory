import Foundation
import SwiftUI

/// 显示按状态筛选的任务列表，并承载任务创建、编辑与目标追加入口的页面。
struct TaskScreen: View {
    /// 上层保存的任务列表模型，提供页面数据和任务操作。
    let model: TaskListModel
    /// 开始专注成功后通知上层切换页面，任务页不直接控制根导航。
    let onStartFocus: () -> Void

    /// 当前交给编辑弹窗的任务；为空时关闭该弹窗。
    @State private var taskBeingEdited: TaskListItem?
    /// 控制新建任务弹窗的显示与关闭。
    @State private var isNewTaskEditorPresented = false

    /// 显示任务列表与操作入口，并响应新建和编辑弹窗状态。
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

    /// 在页面顶部弱化显示一次性提示，不打断列表交互。
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

    /// 列表主体：查询失败时显示重试，没有结果时显示空状态，否则显示任务。
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

    /// 任务卡片列表，将卡片操作交给模型或编辑弹窗处理。
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

    /// 按任务模式把追加数量交给对应命令，并在页面顶部提示失败原因。
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

    /// 当前筛选分类没有任务时显示的图标。
    private var emptyStateSymbol: String {
        switch model.selectedStatus {
        case .active: "checklist"
        case .completed: "checkmark.circle"
        case .abandoned: "archivebox"
        }
    }

    /// 当前筛选分类没有任务时显示的标题。
    private var emptyStateTitle: LocalizedStringResource {
        switch model.selectedStatus {
        case .active: .tasksEmptyActiveTitle
        case .completed: .tasksEmptyCompletedTitle
        case .abandoned: .tasksEmptyAbandonedTitle
        }
    }

    /// 当前筛选分类没有任务时显示的说明。
    private var emptyStateDescription: LocalizedStringResource {
        switch model.selectedStatus {
        case .active: .tasksEmptyActiveDescription
        case .completed: .tasksEmptyCompletedDescription
        case .abandoned: .tasksEmptyAbandonedDescription
        }
    }

    /// 空状态图标颜色，用于区分进行中与历史任务分类。
    private var emptyStateIconColor: Color {
        model.selectedStatus == .active ? .focusoryAccent : .focusoryTextQuaternary
    }

    /// 空状态图标的背景色。
    private var emptyStateIconBackground: Color {
        model.selectedStatus == .active ? .focusoryAccentSurface : .focusoryPageBackground
    }
}

#Preview("任务列表") {
    TaskScreenPreview()
}

/// 为任务页预览创建内存存储，避免使用真实数据。
private struct TaskScreenPreview: View {
    /// 预览专用的任务用例依赖；创建失败时为空，显示占位文本。
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
