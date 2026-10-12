import Foundation
import SwiftUI

/// 展示单个任务的进度、达标反馈与可用操作的列表卡片。
struct TaskCard: View {
    /// 卡片要展示的列表项。
    let item: TaskListItem
    /// 表示该任务是否被选中作为当前专注对象。
    let isSelected: Bool
    /// 在用户选择从该任务开始专注时执行的回调。
    let onStart: () -> Void
    /// 在用户确认完成该任务时执行的回调。
    let onComplete: () -> Void
    /// 在用户请求编辑该任务时执行的回调。
    let onEdit: () -> Void
    /// 在用户确认删除或放弃该任务时执行的回调。
    let onRemove: () -> Void
    /// 在用户提交追加数量时执行的回调。
    let onAppendTarget: (Int) -> Void

    /// 记录指针当前是否位于卡片交互区域内。
    @State private var isHovering = false
    /// 保存正在等待用户确认的卡片内联操作。
    @State private var pendingTaskAction: InlineTaskAction?
    /// 表示自定义追加数量的输入区是否正在显示。
    @State private var isAppendEditorPresented = false
    /// 保存自定义追加数量。
    @State private var appendQuantity = 1

    /// 任务本体。
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
    /// 操作不依赖悬停，键盘和旁白可以直接到达，符合「危险与禁用状态不用颜色或悬停单独表达」的要求。
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

                FocusoryNumberStepper(currentValue: $appendQuantity, allowedRange: 1...999)
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

    /// 返回可视化任务选中状态的卡片背景色。
    private var cardBackground: Color {
        isSelected ? .focusoryAccentSurface : .focusorySurface
    }

    /// 返回与选中或悬停状态匹配的卡片边框色。
    private var cardBorder: Color {
        if isSelected { return .focusoryAccentBorder }
        return isHovering ? .focusoryBorderMedium : .focusoryBorder
    }

    /// 返回表达当前任务模式的主色。
    private var modeColor: Color {
        task.mode == .todo ? .focusoryAccent : .focusorySuccess
    }

    /// 返回当前任务模式标签使用的浅色背景。
    private var modeSurface: Color {
        task.mode == .todo ? .focusoryAccentSurface : .focusorySuccessSurface
    }

    /// 返回当前任务模式标签使用的边框色。
    private var modeBorder: Color {
        task.mode == .todo ? .focusoryAccentBorder : .focusorySuccessBorder
    }

    /// 返回与当前任务模式匹配的达标反馈文案。
    private var goalMetBadgeTitle: LocalizedStringResource {
        task.mode == .todo ? .tasksBadgePlannedCompletion : .tasksBadgeDailyGoalMet
    }

    /// 返回将待办总目标或当日有效目标归一化后的完成比例。
    private var progressFraction: CGFloat {
        guard let effectiveTarget = item.effectiveTarget, effectiveTarget > 0 else {
            return completedCount > 0 ? 1 : 0
        }
        return CGFloat(min(Double(completedCount) / Double(effectiveTarget), 1))
    }

    /// 返回当前进度文案使用的完成数；持续任务开启每日目标时取今日完成数。
    private var completedCount: Int {
        item.todayCompletedPomodoroCount ?? item.completedPomodoroCount
    }

    /// 返回与任务模式和目标配置匹配的本地化进度文案。
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

    /// 在任务已配置日期范围时返回本地化日程文案。
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

/// 卡片内联确认操作类型。
private enum InlineTaskAction: Equatable {
    case complete
    case remove
}
