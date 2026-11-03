import Foundation
import SwiftUI

/// 显示整数，并通过加减按钮按指定步长调整。
struct FocusoryNumberStepper<Value: FixedWidthInteger & SignedInteger>: View {
    /// 调用方提供的数值绑定，加减操作直接更新该值。
    @Binding var currentValue: Value
    /// 允许的数值范围，约束加减结果和按钮可用状态。
    let allowedRange: ClosedRange<Value>
    /// 每次点击加减按钮时调整的数量。
    let step: Value
    /// 数值和加减按钮的测试标识前缀，用于区分多个步进器。
    let accessibilityIdentifierPrefix: String

    /// 接收数值绑定，并配置允许范围、步长和测试标识。
    init(
        currentValue: Binding<Value>,
        allowedRange: ClosedRange<Value>,
        step: Value = 1,
        accessibilityIdentifierPrefix: String
    ) {
        self._currentValue = currentValue
        self.allowedRange = allowedRange
        self.step = step
        self.accessibilityIdentifierPrefix = accessibilityIdentifierPrefix
    }

    /// 显示当前数值和加减按钮。
    var body: some View {
        HStack(spacing: 0) {
            Button {
                adjustValue(by: -step)
            } label: {
                Image(systemName: "minus")
            }
            .buttonStyle(FocusoryStepperButtonStyle())
            .disabled(!canDecrement)
            .accessibilityLabel(Text(.commonStepperDecrease))
            .accessibilityIdentifier("\(accessibilityIdentifierPrefix)-decrement")

            Text(String(currentValue))
                .font(FocusoryTypography.body)
                .monospacedDigit()
                .foregroundStyle(Color.focusoryTextPrimary)
                .frame(width: FocusoryNumberStepperMetrics.valueWidth,
                       height: FocusoryNumberStepperMetrics.fieldHeight)
                .fixedSize()
                .accessibilityIdentifier("\(accessibilityIdentifierPrefix)-value")

            Button {
                adjustValue(by: step)
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(FocusoryStepperButtonStyle())
            .disabled(!canIncrement)
            .accessibilityLabel(Text(.commonStepperIncrease))
            .accessibilityIdentifier("\(accessibilityIdentifierPrefix)-increment")
        }
        .background(Color.focusorySurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.focusoryBorderMedium, lineWidth: 1)
        }
    }

    /// 当前值是否高于下限，决定减号按钮是否启用。
    private var canDecrement: Bool {
        currentValue > allowedRange.lowerBound
    }

    /// 当前值是否低于上限，决定加号按钮是否启用。
    private var canIncrement: Bool {
        currentValue < allowedRange.upperBound
    }

    /// 根据步进方向调整数值。
    private func adjustValue(by adjustment: Value) {
        let newValue = currentValue + adjustment
        if allowedRange.contains(newValue) {
            currentValue = newValue
        }
    }
}

/// 定义数字步进器的固定尺寸。
private enum FocusoryNumberStepperMetrics {
    /// 加减按钮的点击区域宽度。
    static let buttonWidth: CGFloat = 34
    /// 控件高度，与其他表单输入框对齐。
    static let fieldHeight: CGFloat = 34
    /// 数值显示的固定宽度。
    static let valueWidth: CGFloat = 40
}

/// 呈现步进按钮在默认、悬停、按压和禁用状态下的外观。
private struct FocusoryStepperButtonStyle: ButtonStyle {
    /// 根据按压状态构建步进按钮。
    func makeBody(configuration: Configuration) -> some View {
        FocusoryStepperButtonBody(label: configuration.label, isPressed: configuration.isPressed)
    }
}

/// 呈现步进按钮完整点击区域和交互状态的内部视图。
private struct FocusoryStepperButtonBody<Label: View>: View {
    /// 调用方提供的按钮图标。
    let label: Label
    /// 按钮是否正在按下，决定按压外观。
    let isPressed: Bool

    /// 系统传入的启用状态，决定按钮的禁用外观。
    @Environment(\.isEnabled) private var isEnabled
    /// 指针是否停留在按钮内，决定悬停外观。
    @State private var isHovering = false

    /// 根据启用、悬停和按压状态渲染步进按钮。
    var body: some View {
        label
            .font(FocusoryTypography.emphasizedIcon)
            .foregroundStyle(foregroundColor)
            .frame(width: FocusoryNumberStepperMetrics.buttonWidth,
                   height: FocusoryNumberStepperMetrics.fieldHeight)
            .background(backgroundColor)
            .contentShape(Rectangle())
            .onHover { isHovering = $0 }
            .animation(.easeOut(duration: 0.15), value: isHovering)
    }

    /// 返回与启用和交互状态匹配的图标颜色。
    private var foregroundColor: Color {
        guard isEnabled else { return .focusoryTextTertiary }
        return isHovering || isPressed ? .focusoryTextPrimary : .focusoryTextSecondary
    }

    /// 返回与启用和交互状态匹配的背景色。
    private var backgroundColor: Color {
        guard isEnabled else { return .clear }
        if isPressed { return .focusoryBorder }
        if isHovering { return .focusoryPageBackground }
        return .clear
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        FocusoryNumberStepper(
            currentValue: .constant(5),
            allowedRange: 1...20,
            accessibilityIdentifierPrefix: "preview-minimum"
        )

        HStack {
            Text("Value:")
            FocusoryNumberStepper(
                currentValue: .constant(15),
                allowedRange: 1...20,
                accessibilityIdentifierPrefix: "preview-middle"
            )
        }

        FocusoryNumberStepper(
            currentValue: .constant(120),
            allowedRange: 5...120,
            step: 5,
            accessibilityIdentifierPrefix: "preview-maximum"
        )
    }
    .padding()
}
