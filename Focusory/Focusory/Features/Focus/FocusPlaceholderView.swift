import Foundation
import SwiftUI

/// 专注功能尚未实现时显示的说明页面。
struct FocusPlaceholderView: View {
    /// 显示专注功能的占位图标、标题和说明。
    var body: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(Color.focusoryAccentSurface)
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: "timer")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.focusoryAccent)
                }
            
            Text(.focusPlaceholderTitle)
                .font(FocusoryTypography.sectionTitle)
                .foregroundStyle(Color.focusoryTextPrimary)
            
            Text(.focusPlaceholderDescription)
                .font(FocusoryTypography.supporting)
                .foregroundStyle(Color.focusoryTextTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("focus-placeholder")
    }
}

#Preview {
    FocusPlaceholderView()
}
