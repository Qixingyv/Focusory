import Foundation
import SwiftUI

/// 展示单个任务的进度、达标反馈与可用操作的列表卡片。
struct TaskCard: View {
    /// 当前卡片的任务和进度数据。
    let item: TaskListItem
    /// 是否为当前专注选中的任务，决定卡片突出显示的外观。
    let isSelected: Bool
    /// 将开始专注操作交给任务页处理。
    let onStart: () -> Void
    /// 用户确认完成后，通知任务页执行完成操作。
    let onComplete: () -> Void
    /// 通知任务页打开当前任务的编辑弹窗。
    let onEdit: () -> Void
    /// 用户确认移除后，由任务页决定删除还是放弃。
    let onRemove: () -> Void
    /// 将追加数量交给任务页，由任务模式决定追加哪种目标。
    let onAppendTarget: (Int) -> Void

    /// 指针是否停留在卡片内，影响边框；移出时取消待确认操作。
    @State private var isHovering = false
    /// 等待确认的完成或移除操作；非空时用确认区替换操作按钮。
    @State private var pendingTaskAction: InlineTaskAction?
    /// 控制自定义追加数量弹出框的显示与关闭。
    @State private var isAppendEditorPresented = false
    /// 自定义追加框中待提交的番茄数量。
    @State private var appendQuantity = 1

    /// 当前卡片对应的任务，供标题、模式和状态展示使用。
    private var task: FocusTask { item.task }

    /// 展示任务信息、进度、达标反馈与上下文操作。
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    Text(task.name)
                        .font(FocusoryTypography.bodyEmphasized)
                        .foregroundStyle(isSelected ? Color.focusoryAccent : Color.focusoryTextPrimary)
                        .lineLimit(1)

                    modeTag
                }

                HStack(spacing: 6) {
                    progressBar
                    Text(progressText)
                        .font(FocusoryTypography.metadata)
                        .foregroundStyle(Color.focusoryTextTertiary)

                    if task.status == .active, item.goalFeedback == .goalMet {
                        statusBadge(title: goalMetBadgeTitle, color: .focusorySuccess, background: .focusorySuccessSurface, border: .focusorySuccessBorder)
                    }
                }

                if let scheduleText {
                    Text(scheduleText)
                        .font(FocusoryTypography.metadata)
                        .foregroundStyle(Color.focusoryTextQuaternary)
                }
            }

            Spacer(minLength: 12)

            accessory
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: FocusoryMetrics.cardRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: FocusoryMetrics.cardRadius, style: .continuous)
                .stroke(cardBorder, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("task-card")
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovering = hovering
                if !hovering {
                    pendingTaskAction = nil
                }
            }
        }
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }

    /// 使用对应色彩显示任务模式的紧凑标签。
    private var modeTag: some View {
        Text(task.mode.localizedTitle)
            .font(FocusoryTypography.captionEmphasized)
            .foregroundStyle(modeColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(modeSurface)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(modeBorder, lineWidth: 1)
            }
    }

    /// 以横向进度条呈现任务当前的目标完成比例。
    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.focusoryBorder)
                Capsule()
                    .fill(modeColor)
                    .frame(width: proxy.size.width * progressFraction)
            }
        }
        .frame(width: 64, height: 4)
        .animation(.easeOut(duration: 0.15), value: progressFraction)
    }

    /// 根据任务状态显示操作区、确认区或状态标签。
    /// 进行中任务的操作入口不依赖悬停，让键盘和旁白用户也能直接访问。
    @ViewBuilder
    private var accessory: some View {
        if task.status == .active {
            if let pendingTaskAction {
                inlineConfirmation(for: pendingTaskAction)
            } else {
                activeActions
            }
        } else if task.status == .completed {
            statusBadge(title: .tasksStatusCompleted, color: .focusorySuccess, background: .focusorySuccessSurface, border: .focusorySuccessBorder)
        } else {
            statusBadge(title: .tasksStatusAbandoned, color: .focusoryTextQuaternary, background: .clear, border: .focusoryBorder)
        }
    }

    /// 显示自定义追加数量的输入区。
    private var appendEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(.tasksAppendTitle)
                .font(FocusoryTypography.heading)
                .foregroundStyle(Color.focusoryTextPrimary)

            VStack(alignment: .leading, spacing: 6) {
                Text(.tasksAppendQuantityLabel)
                    .font(FocusoryTypography.label)
                    .foregroundStyle(Color.focusoryTextSecondary)

                FocusoryNumberStepper(
                    currentValue: $appendQuantity,
                    allowedRange: 1...999,
                    accessibilityIdentifierPrefix: "task-append-quantity-stepper"
                )
            }

            HStack(spacing: 10) {
                Spacer()

                Button(.commonActionCancel) {
                    isAppendEditorPresented = false
                }
                .buttonStyle(.plain)
                .font(FocusoryTypography.supporting)
                .foregroundStyle(Color.focusoryTextTertiary)

                Button(.commonActionConfirm) {
                    isAppendEditorPresented = false
                    onAppendTarget(appendQuantity)
                }
                .focusoryPrimaryButton(
                    horizontalPadding: 14,
                    minHeight: 28,
                    cornerRadius: 8,
                    font: FocusoryTypography.supportingEmphasized
                )
                .accessibilityIdentifier("task-append-confirm-button")
            }
        }
        .padding(16)
        .frame(width: 220)
    }

    /// 提供启动专注、完成、追加目标、编辑和移除任务的卡片操作组。
    private var activeActions: some View {
        HStack(spacing: 4) {
            Button(.tasksActionStartFocus, action: onStart)
                .focusoryPrimaryButton(
                    horizontalPadding: 8,
                    minHeight: 28,
                    cornerRadius: 8,
                    font: FocusoryTypography.label
                )
                .disabled(!item.isStartable)
                .accessibilityIdentifier("task-start-focus-button")
                .accessibilityHint(item.isStartable ? Text(.tasksStartAvailableHint) : Text(.tasksStartUnavailableHint))

            Button(.tasksActionComplete) {
                pendingTaskAction = .complete
            }
            .buttonStyle(FocusoryOutlineButtonStyle(color: .focusorySuccess, hoverBackground: .focusorySuccessSurface))
            .accessibilityIdentifier("task-complete-button")

            if item.goalFeedback == .goalMet {
                Button(.tasksActionAppendOne) {
                    onAppendTarget(1)
                }
                .buttonStyle(FocusoryOutlineButtonStyle(color: .focusorySuccess, hoverBackground: .focusorySuccessSurface))
                .accessibilityIdentifier("task-append-one-button")

                Button(.tasksActionAppendCustom) {
                    appendQuantity = 1
                    isAppendEditorPresented = true
                }
                .buttonStyle(FocusoryOutlineButtonStyle(color: .focusoryTextSecondary, hoverBackground: .focusoryPageBackground))
                .accessibilityIdentifier("task-append-custom-button")
                .popover(isPresented: $isAppendEditorPresented, arrowEdge: .bottom) {
                    appendEditor
                }
            }

            Button(action: onEdit) {
                Image(systemName: "pencil")
            }
            .buttonStyle(FocusoryIconButtonStyle(role: nil))
            .help(Text(.tasksActionEdit))
            .accessibilityLabel(Text(.tasksActionEdit))
            .accessibilityIdentifier("task-edit-button")

            Button {
                pendingTaskAction = .remove
            } label: {
                Image(systemName: item.hasHistory ? "archivebox" : "trash")
            }
            .buttonStyle(FocusoryIconButtonStyle(role: .destructive))
            .help(Text(item.hasHistory ? .tasksActionAbandon : .tasksActionDelete))
            .accessibilityLabel(Text(item.hasHistory ? .tasksActionAbandon : .tasksActionDelete))
            .accessibilityIdentifier("task-remove-button")
        }
    }

    /// 构建卡片内嵌的任务操作确认区，并在确认后触发对应回调。
    private func inlineConfirmation(for action: InlineTaskAction) -> some View {
        HStack(spacing: 8) {
            Text(confirmationTitle(for: action))
                .font(FocusoryTypography.supporting)
                .foregroundStyle(Color.focusoryTextSecondary)

            Button(.commonActionCancel) {
                pendingTaskAction = nil
            }
            .buttonStyle(.plain)
            .font(FocusoryTypography.supporting)
            .foregroundStyle(Color.focusoryTextTertiary)
            .accessibilityIdentifier("task-inline-cancel-button")

            Button(.commonActionConfirm) {
                if action == .complete {
                    onComplete()
                } else {
                    onRemove()
                }
                pendingTaskAction = nil
            }
            .buttonStyle(
                FocusoryFilledButtonStyle(
                    color: action == .complete ? .focusorySuccess : .focusoryDanger,
                    hoverColor: action == .complete ? .focusorySuccessHover : .focusoryDanger,
                    pressedColor: action == .complete ? .focusorySuccessHover : .focusoryDanger,
                    horizontalPadding: 12,
                    minHeight: 24,
                    cornerRadius: 8,
                    font: FocusoryTypography.supportingEmphasized
                )
            )
            .accessibilityIdentifier("task-inline-confirm-button")
        }
    }

    /// 使用给定的文案和色彩构建任务状态标签。
    private func statusBadge(
        title: LocalizedStringResource,
        color: Color,
        background: Color,
        border: Color
    ) -> some View {
        Text(title)
            .font(FocusoryTypography.captionEmphasized)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(border, lineWidth: 1)
            }
    }

    /// 卡片背景色，突出当前选中的专注任务。
    private var cardBackground: Color {
        isSelected ? .focusoryAccentSurface : .focusorySurface
    }

    /// 卡片边框色，优先表达选中状态，其次表达悬停状态。
    private var cardBorder: Color {
        if isSelected { return .focusoryAccentBorder }
        return isHovering ? .focusoryBorderMedium : .focusoryBorder
    }

    /// 任务模式对应的标签文字和进度条颜色。
    private var modeColor: Color {
        task.mode == .todo ? .focusoryAccent : .focusorySuccess
    }

    /// 任务模式标签的浅色背景。
    private var modeSurface: Color {
        task.mode == .todo ? .focusoryAccentSurface : .focusorySuccessSurface
    }

    /// 任务模式标签的边框色。
    private var modeBorder: Color {
        task.mode == .todo ? .focusoryAccentBorder : .focusorySuccessBorder
    }

    /// 达标标签文案，区分待办按计划完成与持续任务今日达标。
    private var goalMetBadgeTitle: LocalizedStringResource {
        task.mode == .todo ? .tasksBadgePlannedCompletion : .tasksBadgeDailyGoalMet
    }

    /// 进度条填充比例，最高为 1；未设目标时，有完成记录即填满。
    private var progressFraction: CGFloat {
        guard let effectiveTarget = item.effectiveTarget, effectiveTarget > 0 else {
            return completedCount > 0 ? 1 : 0
        }
        return CGFloat(min(Double(completedCount) / Double(effectiveTarget), 1))
    }

    /// 进度条使用的完成数；持续任务开启每日目标时取今日完成数。
    private var completedCount: Int {
        item.todayCompletedPomodoroCount ?? item.completedPomodoroCount
    }

    /// 卡片进度文案，按配置显示总目标、今日目标或累计投入。
    private var progressText: LocalizedStringResource {
        switch task.mode {
        case .todo:
            .tasksProgressTodo(item.completedPomodoroCount, item.effectiveTarget ?? 1)
        case .ongoing:
            if let effectiveTarget = item.effectiveTarget {
                .tasksProgressDaily(item.todayCompletedPomodoroCount ?? 0, effectiveTarget)
            } else {
                .tasksProgressTotal(item.completedPomodoroCount)
            }
        }
    }

    /// 任务计划日期文案；未配置完整日期范围时不显示。
    private var scheduleText: LocalizedStringResource? {
        guard task.hasDateRange, let startDate = task.startDate, let endDate = task.endDate else {
            return nil
        }
        return .tasksScheduleRange(startDate.localizedDisplayText, endDate.localizedDisplayText)
    }

    /// 返回与待确认操作和任务历史匹配的本地化提示。
    private func confirmationTitle(for action: InlineTaskAction) -> LocalizedStringResource {
        if action == .complete {
            return .tasksConfirmComplete
        }
        return item.hasHistory ? .tasksConfirmAbandon : .tasksConfirmDelete
    }
}

/// 需要在卡片内先确认、再执行的操作。
private enum InlineTaskAction: Equatable {
    case complete
    case remove
}
