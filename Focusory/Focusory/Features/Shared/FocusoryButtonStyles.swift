import Foundation
import SwiftUI

/// 用于主操作的可配置填充按钮样式。
struct FocusoryFilledButtonStyle: ButtonStyle {
    /// 定义按钮默认状态的填充颜色。
    let color: Color
    /// 定义指针悬停时的按钮填充颜色。
    let hoverColor: Color
    /// 定义按钮按下时的填充颜色。
    let pressedColor: Color
    /// 控制按钮文案两侧的水平留白。
    var horizontalPadding: CGFloat = 32
    /// 限制按钮可点击区域的最小高度。
    var minHeight: CGFloat = 36
    /// 定义按钮背景边界的圆角半径。
    var cornerRadius: CGFloat = 12
    /// 定义按钮标签使用的语义字体。
    var font: Font = FocusoryTypography.bodyEmphasized

    /// 根据按压状态构建填充按钮的可视内容。
    func makeBody(configuration: Configuration) -> some View {
        FocusoryFilledButtonBody(
            label: configuration.label,
            isPressed: configuration.isPressed,
            color: color,
            hoverColor: hoverColor,
            pressedColor: pressedColor,
            horizontalPadding: horizontalPadding,
            minHeight: minHeight,
            cornerRadius: cornerRadius,
            font: font
        )
    }
}

/// 呈现填充按钮在默认、悬停、按压和禁用状态下外观的内部视图。
private struct FocusoryFilledButtonBody<Label: View>: View {
    /// 保存由按钮调用方提供的标签内容。
    let label: Label
    /// 表示按钮当前是否正处于按压状态。
    let isPressed: Bool
    /// 保存按钮默认状态的填充颜色。
    let color: Color
    /// 保存指针悬停时的按钮填充颜色。
    let hoverColor: Color
    /// 保存按钮按下时的填充颜色。
    let pressedColor: Color
    /// 保存按钮标签两侧的水平留白。
    let horizontalPadding: CGFloat
    /// 保存按钮可点击区域的最小高度。
    let minHeight: CGFloat
    /// 保存按钮背景边界的圆角半径。
    let cornerRadius: CGFloat
    /// 保存按钮标签使用的语义字体。
    let font: Font

    /// 反映 SwiftUI 环境中该按钮是否允许交互。
    @Environment(\.isEnabled) private var isEnabled
    /// 记录指针当前是否位于按钮交互区域内。
    @State private var isHovering = false

    /// 根据启用、悬停和按压状态渲染填充按钮。
    var body: some View {
        label
            .font(font)
            .foregroundStyle(Color.white)
            .padding(.horizontal, horizontalPadding)
            .frame(minHeight: minHeight)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .opacity(isEnabled ? 1 : 0.4)
            .shadow(color: Color.black.opacity(isEnabled ? 0.08 : 0), radius: 2, y: 1)
            .onHover { isHovering = $0 }
            .animation(.easeOut(duration: 0.15), value: isHovering)
    }

    /// 返回与当前按压和悬停状态匹配的按钮背景色。
    private var backgroundColor: Color {
        if isPressed { return pressedColor }
        if isHovering { return hoverColor }
        return color
    }
}

/// 用于次要操作的描边按钮样式。
struct FocusoryOutlineButtonStyle: ButtonStyle {
    /// 定义按钮文案与边框共用的主色。
    let color: Color
    /// 定义按钮悬停或按压时的背景色。
    let hoverBackground: Color

    /// 根据按压状态构建描边按钮的可视内容。
    func makeBody(configuration: Configuration) -> some View {
        FocusoryOutlineButtonBody(
            label: configuration.label,
            isPressed: configuration.isPressed,
            color: color,
            hoverBackground: hoverBackground
        )
    }
}

/// 呈现描边按钮在默认、悬停和按压状态下外观的内部视图。
private struct FocusoryOutlineButtonBody<Label: View>: View {
    /// 保存由按钮调用方提供的标签内容。
    let label: Label
    /// 表示按钮当前是否正处于按压状态。
    let isPressed: Bool
    /// 保存按钮文案与边框共用的主色。
    let color: Color
    /// 保存按钮悬停或按压时的背景色。
    let hoverBackground: Color

    /// 记录指针当前是否位于按钮交互区域内。
    @State private var isHovering = false

    /// 根据悬停和按压状态渲染描边按钮。
    var body: some View {
        label
            .font(FocusoryTypography.label)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .frame(minHeight: 28)
            .background(isHovering || isPressed ? hoverBackground : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(color, lineWidth: 1)
            }
            .onHover { isHovering = $0 }
            .animation(.easeOut(duration: 0.15), value: isHovering)
    }
}

/// 用于编辑、删除等紧凑卡片操作的图标按钮样式。
struct FocusoryIconButtonStyle: ButtonStyle {
    /// 标识按钮是普通操作还是破坏性操作。
    let role: ButtonRole?

    /// 根据按钮角色和按压状态构建图标按钮。
    func makeBody(configuration: Configuration) -> some View {
        FocusoryIconButtonBody(label: configuration.label, isPressed: configuration.isPressed, role: role)
    }
}

/// 呈现图标按钮的普通与破坏性交互状态的内部视图。
private struct FocusoryIconButtonBody<Label: View>: View {
    /// 保存由按钮调用方提供的图标标签。
    let label: Label
    /// 表示按钮当前是否正处于按压状态。
    let isPressed: Bool
    /// 标识按钮是普通操作还是破坏性操作。
    let role: ButtonRole?

    /// 记录指针当前是否位于按钮交互区域内。
    @State private var isHovering = false

    /// 根据按钮角色、悬停和按压状态渲染图标按钮。
    var body: some View {
        label
            .font(FocusoryTypography.icon)
            .foregroundStyle(foregroundColor)
            .frame(width: 28, height: 28)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .onHover { isHovering = $0 }
            .animation(.easeOut(duration: 0.15), value: isHovering)
    }

    /// 返回与按钮角色和当前交互状态匹配的前景色。
    private var foregroundColor: Color {
        if role == .destructive && isHovering { return .focusoryDanger }
        if isHovering || isPressed { return .focusoryTextPrimary }
        return .focusoryTextTertiary
    }

    /// 返回与按钮角色和当前交互状态匹配的背景色。
    private var backgroundColor: Color {
        if role == .destructive && (isHovering || isPressed) { return .focusoryDanger.opacity(0.08) }
        if isHovering || isPressed { return .focusoryPageBackground }
        return .clear
    }
}

extension View {
    /// 为按钮应用可按需调整尺寸的 Focusory 主操作样式。
    func focusoryPrimaryButton(
        horizontalPadding: CGFloat = 32,
        minHeight: CGFloat = 36,
        cornerRadius: CGFloat = 12,
        font: Font = FocusoryTypography.bodyEmphasized
    ) -> some View {
        buttonStyle(
            FocusoryFilledButtonStyle(
                color: .focusoryAccent,
                hoverColor: .focusoryAccentHover,
                pressedColor: .focusoryAccentPressed,
                horizontalPadding: horizontalPadding,
                minHeight: minHeight,
                cornerRadius: cornerRadius,
                font: font
            )
        )
    }
}