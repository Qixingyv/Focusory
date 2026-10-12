import Foundation
import SwiftUI

/// 提供数值输入和步进控制的数字输入器。
struct FocusoryNumberStepper<Value: FixedWidthInteger & SignedInteger>: View {
    /// 与调用方双向同步的当前数值。
    @Binding var currentValue: Value
    /// 定义可选数值范围，超出范围时禁用按钮。
    let allowedRange: ClosedRange<Value>
    /// 控制步进的单次增量。
    let step: Value
    
    /// 创建一个数字输入器并设置初始值和范围。
    init(currentValue: Binding<Value>, allowedRange: ClosedRange<Value>, step: Value = 1) {
        self._currentValue = currentValue
        self.allowedRange = allowedRange
        self.step = step
    }

    /// 使用步进按钮、数值显示和文本输入组合数字输入器。
    var body: some View {
        HStack(spacing: 0) {
            Button {
                adjustValue(by: -step)
            } label: {
                Image(systemName: "minus")
                    .font(FocusoryTypography.icon)
            }
            .buttonStyle(.plain)
            .frame(width: 24, height: 32)
            .disabled(!canDecrement)
            .foregroundColor(canDecrement ? Color.focusoryTextPrimary : Color.focusoryTextTertiary)
            
            Text(String(currentValue))
                .font(FocusoryTypography.body)
                .foregroundStyle(Color.focusoryTextPrimary)
                .frame(width: 40, height: 32)
                .fixedSize()
            
            Button {
                adjustValue(by: step)
            } label: {
                Image(systemName: "plus")
                    .font(FocusoryTypography.icon)
            }
            .buttonStyle(.plain)
            .frame(width: 24, height: 32)
            .disabled(!canIncrement)
            .foregroundColor(canIncrement ? Color.focusoryTextPrimary : Color.focusoryTextTertiary)
        }
        .background(Color.focusorySurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.focusoryBorderMedium, lineWidth: 1)
        }
    }
    
    /// 计算是否可以递减数值。
    private var canDecrement: Bool {
        currentValue > allowedRange.lowerBound
    }
    
    /// 计算是否可以递增数值。
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

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        FocusoryNumberStepper(currentValue: .constant(5), allowedRange: 1...20)
        
        HStack {
            Text("Value:")
            FocusoryNumberStepper(currentValue: .constant(15), allowedRange: 1...20)
        }
    }
}
