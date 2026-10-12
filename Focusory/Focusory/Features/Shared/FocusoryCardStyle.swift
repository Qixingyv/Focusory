import Foundation
import SwiftUI

/// 为内容提供 Focusory 统一卡片外观的视图修饰器。
struct FocusoryCardModifier: ViewModifier {
    /// 为内容应用 Focusory 统一的卡片背景、圆角和边框。
    func body(content: Content) -> some View {
        content
            .background(Color.focusorySurface)
            .clipShape(RoundedRectangle(cornerRadius: FocusoryMetrics.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: FocusoryMetrics.cardRadius, style: .continuous)
                    .stroke(Color.focusoryBorder, lineWidth: 1)
            }
    }
}

extension View {
    /// 将视图包装为 Focusory 标准卡片容器。
    func focusoryCard() -> some View {
        modifier(FocusoryCardModifier())
    }
}