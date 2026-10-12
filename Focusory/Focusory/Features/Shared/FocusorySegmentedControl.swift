import Foundation
import SwiftUI

/// 描述 Focusory 分段控件中一个可选项的值、文案与无障碍标识。
struct FocusorySegmentedItem<Value: Hashable>: Identifiable {
    /// 保存选项被选中时写入绑定的值。
    let value: Value
    /// 选项的本地化文案。
    let title: LocalizedStringResource
    /// 提供 UI 测试和辅助功能定位该选项的稳定标识。
    let accessibilityIdentifier: String

    /// 选项标识，取绑定值。
    var id: Value { value }
}

/// 在一组互斥选项之间读取并更新当前选择的分段控件。
struct FocusorySegmentedControl<Value: Hashable>: View {
    /// 与调用方双向同步的当前选中值。
    @Binding var selectedValue: Value
    /// 定义控件按显示顺序呈现的可选项。
    let items: [FocusorySegmentedItem<Value>]
    /// 表示用户当前是否可以更改选中项。
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