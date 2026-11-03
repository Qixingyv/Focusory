import Foundation
import SwiftUI

/// 统计功能尚未实现时显示的说明页面。
struct StatisticsPlaceholderView: View {
    /// 显示统计功能的占位图标、标题和说明。
    var body: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(Color.focusoryAccentSurface)
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.focusoryAccent)
                }
            
            Text(.statisticsPlaceholderTitle)
                .font(FocusoryTypography.sectionTitle)
                .foregroundStyle(Color.focusoryTextPrimary)
            
            Text(.statisticsPlaceholderDescription)
                .font(FocusoryTypography.supporting)
                .foregroundStyle(Color.focusoryTextTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("statistics-placeholder")
    }
}

#Preview {
    StatisticsPlaceholderView()
}
