import Foundation
import SwiftUI

/// 描述 Focusory 分段控件中一个可选项的值、文案与无障碍标识。
struct FocusorySegmentedItem<Value: Hashable>: Identifiable {
    /// 选中此项时交给调用方的值。
    let value: Value
    /// 选项的本地化文案。
    let title: LocalizedStringResource
    /// UI 测试定位该选项的稳定标识。
    let accessibilityIdentifier: String

    /// 以选项值作为稳定标识，供 ForEach 区分各项。
    var id: Value { value }
}

/// 在一组互斥选项之间读取并更新当前选择的分段控件。
struct FocusorySegmentedControl<Value: Hashable>: View {
    /// 当前选中值的绑定，点击选项时同步更新调用方状态。
    @Binding var selectedValue: Value
    /// 按显示顺序排列的可选项。
    let items: [FocusorySegmentedItem<Value>]
    /// 是否允许切换选项，控制按钮禁用状态和控件透明度。
    var isEnabled = true

    /// 将选项渲染为共享外框的一组互斥按钮。
    var body: some View {
        HStack(spacing: 2) {
            ForEach(items) { item in
                Button {
                    selectedValue = item.value
                } label: {
                    Text(item.title)
                        .font(FocusoryTypography.bodyEmphasized)
                        .foregroundStyle(selectedValue == item.value ? Color.focusoryTextPrimary : Color.focusoryTextSecondary)
                        .padding(.horizontal, 14)
                        .frame(height: 28)
                        .background(selectedValue == item.value ? Color.focusorySurface : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .shadow(color: selectedValue == item.value ? Color.black.opacity(0.08) : .clear, radius: 2, y: 1)
                }
                .buttonStyle(.plain)
                .disabled(!isEnabled)
                .accessibilityIdentifier(item.accessibilityIdentifier)
            }
        }
        .padding(2)
        .background(Color.focusoryBorder)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .opacity(isEnabled ? 1 : 0.4)
        .animation(.easeOut(duration: 0.15), value: selectedValue)
    }
}