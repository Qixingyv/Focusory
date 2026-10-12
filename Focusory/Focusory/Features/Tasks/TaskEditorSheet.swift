import Foundation
import SwiftUI

/// 提供创建或编辑待办与持续任务的模态表单，并就地展示字段化错误。
struct TaskEditorSheet: View {
    /// 关闭当前任务编辑弹窗的系统动作。
    @Environment(\.dismiss) private var dismiss

    /// 保存正在编辑的原任务；空值表示正在创建任务。
    private let originalTask: FocusTask?
    /// 表示原任务是否已有历史会话；决定持续任务配置开关是否锁定。
    private let hasHistory: Bool
    /// 本机日历；在日期选择器结果与本机日期之间换算。
    private let calendar: any CalendarProvider
    /// 提交草稿；返回非空表示保存失败并就地展示。
    private let onSubmit: (TaskDraft) -> TaskFailure?

    /// 保存用户当前输入的任务名称。
    @State private var taskName: String
    /// 保存新任务选择的模式，编辑现有任务时不可更改。
    @State private var selectedMode: FocusTaskMode
    /// 保存待办任务计划完成的番茄总数。
    @State private var todoTarget: Int
    /// 保存每轮专注计时的分钟数。
    @State private var focusDurationMinutes: Int
    /// 保存每轮休息计时的分钟数。
    @State private var breakDurationMinutes: Int
    /// 表示持续任务是否设置计划日期范围。
    @State private var hasDateRange: Bool
    /// 保存持续任务计划开始的本机日期。
    @State private var startDate: Date
    /// 保存持续任务计划结束的本机日期。
    @State private var endDate: Date
    /// 表示持续任务是否设置每日番茄目标。
    @State private var hasDailyTarget: Bool
    /// 保存持续任务每天计划完成的番茄数。
    @State private var dailyTarget: Int
    /// 保存最近一次保存失败的字段化原因。
    @State private var failure: TaskFailure?

    /// 创建任务编辑器，并从可选原任务与历史状态初始化表单。
    init(
        task: FocusTask? = nil,
        hasHistory: Bool = false,
        calendar: any CalendarProvider,
        onSave: @escaping (TaskDraft) -> TaskFailure?
    ) {
        originalTask = task
        self.hasHistory = hasHistory
        self.calendar = calendar
        self.onSubmit = onSave

        let timeZone = calendar.timeZoneID.timeZone
        let todayInstant = calendar.localDate(for: Date()).startInstant(in: timeZone) ?? Date()
        let defaultEndInstant = LocalDate.containing(
            todayInstant.addingTimeInterval(7 * 24 * 60 * 60),
            in: timeZone
        ).startInstant(in: timeZone) ?? todayInstant

        _taskName = State(initialValue: task?.name ?? "")
        _selectedMode = State(initialValue: task?.mode ?? .todo)
        _todoTarget = State(initialValue: task?.todoTarget ?? 1)
        _focusDurationMinutes = State(initialValue: task?.focusDurationMinutes ?? 25)
        _breakDurationMinutes = State(initialValue: task?.breakDurationMinutes ?? 5)
        _hasDateRange = State(initialValue: task?.hasDateRange ?? false)
        _startDate = State(initialValue: task?.startDate?.startInstant(in: timeZone) ?? todayInstant)
        _endDate = State(initialValue: task?.endDate?.startInstant(in: timeZone) ?? defaultEndInstant)
        _hasDailyTarget = State(initialValue: task?.hasDailyTarget ?? false)
        _dailyTarget = State(initialValue: task?.dailyTarget ?? 1)
    }

    /// 组合标题、任务字段和底部操作区。
    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    modeField
                    nameField
                    modeSpecificFields
                    durationFields

                    if isGeneralFailure {
                        generalFailureMessage
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }

            footer
        }
        .frame(width: 440)
        .frame(maxHeight: 620)
        .background(Color.focusorySurface)
    }

    /// 显示与创建或编辑状态匹配的弹窗标题。
    private var header: some View {
        HStack {
            Text(originalTask == nil ? .tasksEditorCreateTitle : .tasksEditorEditTitle)
                .font(FocusoryTypography.heading)
                .foregroundStyle(Color.focusoryTextPrimary)
                .accessibilityIdentifier("task-editor-title")

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.focusoryBorder)
                .frame(height: 1)
        }
    }

    /// 显示任务模式标签和待办、持续两种模式选项。
    private var modeField: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel(.tasksEditorModeLabel)

            FocusorySegmentedControl(
                selectedValue: $selectedMode,
                items: FocusTaskMode.allCases.map { mode in
                    FocusorySegmentedItem(
                        value: mode,
                        title: mode.localizedTitle,
                        accessibilityIdentifier: "task-mode-\(mode.rawValue)"
                    )
                },
                isEnabled: originalTask == nil
            )
        }
    }

    /// 显示任务名称输入框。
    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel(.tasksEditorNameLabel)

            TextField(.tasksEditorNamePlaceholder, text: $taskName)
                .textFieldStyle(.plain)
                .font(FocusoryTypography.body)
                .foregroundStyle(Color.focusoryTextPrimary)
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background(Color.focusorySurface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.focusoryBorderMedium, lineWidth: 1)
                }
                .accessibilityIdentifier("task-name-field")

            fieldFailure(.name)
        }
    }

    /// 根据所选任务模式显示目标或持续计划字段。
    @ViewBuilder
    private var modeSpecificFields: some View {
        if selectedMode == .todo {
            VStack(alignment: .leading, spacing: 6) {
                numberField(
                    title: .tasksEditorTodoTargetLabel,
                    currentValue: $todoTarget,
                    allowedRange: 1...999
                )
                fieldFailure(.todoTarget)
            }
        } else {
            ongoingFields
        }
    }

    /// 显示持续任务的日期范围和每日目标配置。
    private var ongoingFields: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle(isOn: $hasDateRange) {
                toggleLabel(
                    title: .tasksEditorDateRangeToggleTitle,
                    description: .tasksEditorDateRangeToggleDescription
                )
            }
            .toggleStyle(FocusorySwitchToggleStyle())
            .disabled(hasHistory)
            .accessibilityIdentifier("task-date-range-toggle")

            if hasDateRange {
                HStack(alignment: .top, spacing: 12) {
                    dateField(title: .tasksEditorStartDateLabel, date: $startDate)
                    dateField(title: .tasksEditorEndDateLabel, date: $endDate)
                }
                fieldFailure(.dateRange)
            }

            Toggle(isOn: $hasDailyTarget) {
                toggleLabel(
                    title: .tasksEditorDailyTargetToggleTitle,
                    description: .tasksEditorDailyTargetToggleDescription
                )
            }
            .toggleStyle(FocusorySwitchToggleStyle())
            .disabled(hasHistory)
            .accessibilityIdentifier("task-daily-target-toggle")

            if hasDailyTarget {
                VStack(alignment: .leading, spacing: 6) {
                    numberField(
                        title: .tasksEditorDailyTargetLabel,
                        currentValue: $dailyTarget,
                        allowedRange: 1...999
                    )
                    fieldFailure(.dailyTarget)
                }
            }
        }
    }

    /// 显示专注和休息时长步进字段。
    private var durationFields: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                numberField(
                    title: .tasksEditorFocusDurationLabel,
                    currentValue: $focusDurationMinutes,
                    allowedRange: TaskRules.minimumFocusDurationMinutes...TaskRules.maximumFocusDurationMinutes,
                    step: TaskRules.focusDurationStepMinutes
                )
                fieldFailure(.focusDuration)
            }
            VStack(alignment: .leading, spacing: 6) {
                numberField(
                    title: .tasksEditorBreakDurationLabel,
                    currentValue: $breakDurationMinutes,
                    allowedRange: TaskRules.minimumBreakDurationMinutes...TaskRules.maximumBreakDurationMinutes
                )
                fieldFailure(.breakDuration)
            }
        }
    }

    /// 显示取消与保存操作；名称未填写时禁用保存。
    private var footer: some View {
        HStack(spacing: 12) {
            Spacer()

            Button(.commonActionCancel) {
                dismiss()
            }
            .buttonStyle(.plain)
            .font(FocusoryTypography.bodyEmphasized)
            .foregroundStyle(Color.focusoryTextSecondary)
            .padding(.horizontal, 12)
            .frame(minHeight: 34)
            .accessibilityIdentifier("task-editor-cancel-button")

            Button(.tasksActionSave) {
                saveTask()
            }
            .focusoryPrimaryButton(
                horizontalPadding: 20,
                minHeight: 34,
                cornerRadius: 10,
                font: FocusoryTypography.bodyEmphasized
            )
            .disabled(trimmedTaskName.isEmpty)
            .keyboardShortcut(.defaultAction)
            .accessibilityIdentifier("task-editor-save-button")
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 20)
    }

    /// 在出现无法定位到字段的失败时显示整体提示。
    private var isGeneralFailure: Bool {
        guard let failure else { return false }
        return failure.field == nil
    }

    /// 显示无法定位到具体字段的失败原因。
    private var generalFailureMessage: some View {
        Text(failure?.code.localizedMessage ?? .tasksFailurePersistenceFailed)
            .font(FocusoryTypography.supporting)
            .foregroundStyle(Color.focusoryDanger)
            .accessibilityIdentifier("task-editor-error-message")
    }

    /// 在指定字段校验失败时显示就地错误。
    @ViewBuilder
    private func fieldFailure(_ field: TaskFormField) -> some View {
        if let failure, failure.field == field {
            Text(failure.code.localizedMessage)
                .font(FocusoryTypography.caption)
                .foregroundStyle(Color.focusoryDanger)
                .accessibilityIdentifier("task-field-error-\(field.rawValue)")
        }
    }

    /// 返回移除首尾空白和换行后的任务名称。
    private var trimmedTaskName: String {
        taskName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 构建一致的表单字段标签。
    private func fieldLabel(_ title: LocalizedStringResource) -> some View {
        Text(title)
            .font(FocusoryTypography.label)
            .foregroundStyle(Color.focusoryTextSecondary)
    }

    /// 构建带说明文字的持续任务开关标签。
    private func toggleLabel(
        title: LocalizedStringResource,
        description: LocalizedStringResource
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(FocusoryTypography.bodyEmphasized)
                .foregroundStyle(Color.focusoryTextPrimary)
            Text(description)
                .font(FocusoryTypography.metadata)
                .foregroundStyle(Color.focusoryTextTertiary)
        }
    }

    /// 构建一个带标签的整数步进字段。
    private func numberField(
        title: LocalizedStringResource,
        currentValue: Binding<Int>,
        allowedRange: ClosedRange<Int>,
        step: Int = 1
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel(title)
            FocusoryNumberStepper(
                currentValue: currentValue,
                allowedRange: allowedRange,
                step: step
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 构建一个带标签的紧凑日期选择字段。
    private func dateField(
        title: LocalizedStringResource,
        date: Binding<Date>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel(title)
            DatePicker("", selection: date, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 把当前表单状态转换为草稿并提交；失败时保留输入并显示原因。
    private func saveTask() {
        failure = nil

        guard let result = onSubmit(makeDraft()) else {
            dismiss()
            return
        }
        failure = result
    }

    /// 按当前模式与开关组合生成提交草稿。
    private func makeDraft() -> TaskDraft {
        let mode = originalTask?.mode ?? selectedMode
        let usesDateRange = mode == .ongoing && hasDateRange
        let usesDailyTarget = mode == .ongoing && hasDailyTarget

        return TaskDraft(
            name: taskName,
            mode: mode,
            focusDurationMinutes: focusDurationMinutes,
            breakDurationMinutes: breakDurationMinutes,
            todoTarget: mode == .todo ? todoTarget : nil,
            hasDateRange: usesDateRange,
            startDate: usesDateRange ? calendar.localDate(for: startDate) : nil,
            endDate: usesDateRange ? calendar.localDate(for: endDate) : nil,
            hasDailyTarget: usesDailyTarget,
            dailyTarget: usesDailyTarget ? dailyTarget : nil
        )
    }
}

#Preview("新建待办") {
    TaskEditorSheet(calendar: SystemCalendarProvider()) { _ in nil }
}
