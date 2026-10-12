import Foundation
import SwiftUI

/// 占位页面，用于统计功能。
struct StatisticsPlaceholderView: View {
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
