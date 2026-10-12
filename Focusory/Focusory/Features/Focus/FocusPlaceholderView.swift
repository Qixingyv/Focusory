import Foundation
import SwiftUI

/// 占位页面，用于专注功能。
struct FocusPlaceholderView: View {
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
