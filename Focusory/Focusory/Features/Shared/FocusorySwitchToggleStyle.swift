import Foundation
import SwiftUI

/// 将布尔设置呈现为 Focusory 开关外观的切换样式。
struct FocusorySwitchToggleStyle: ToggleStyle {
    /// 构建保持 Focusory 视觉风格的开关控件。
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            configuration.label
            Spacer()
            Button {
                configuration.isOn.toggle()
            } label: {
                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(configuration.isOn ? Color.focusoryAccent : Color.focusoryBorderMedium)
                        .frame(width: 44, height: 24)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                        .padding(2)
                        .shadow(color: Color.black.opacity(0.14), radius: 1, y: 1)
                }
            }
            .buttonStyle(.plain)
        }
        .animation(.easeOut(duration: 0.15), value: configuration.isOn)
    }
}