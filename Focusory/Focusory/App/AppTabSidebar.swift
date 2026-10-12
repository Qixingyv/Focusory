import SwiftUI

/// 在系统标签侧边栏顶部显示 Focusory 品牌标识。
struct AppTabSidebarHeader: View {
    /// 组合品牌图标和不可翻译的产品名称。
    var body: some View {
        HStack(spacing: 9) {
            Image("BrandMark")
                .resizable()
                .interpolation(.high)
                .frame(width: 30, height: 30)
                .accessibilityHidden(true)

            Text(verbatim: "Focusory")
                .font(FocusoryTypography.heading)
                .foregroundStyle(Color.focusoryTextPrimary)
        }
        .padding(.vertical, 8)
    }
}

/// 在系统标签侧边栏底部工具栏显示本地账户信息和退出入口。
struct AppTabSidebarBottomBar: View {
    /// 表示用户是否正在确认退出账户操作。
    @State private var isShowingSignOutConfirmation = false

    /// 组合本地账户身份、退出操作和确认提示。
    var body: some View {
        HStack(spacing: 9) {
            Circle()
                .fill(Color.focusorySurface)
                .frame(width: 30, height: 30)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(FocusoryTypography.supporting)
                        .foregroundStyle(Color.focusoryTextTertiary)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(.accountDefaultUserName)
                    .font(FocusoryTypography.label)
                    .foregroundStyle(Color.focusoryTextPrimary)
                Text(.accountLocalWorkspace)
                    .font(FocusoryTypography.caption)
                    .foregroundStyle(Color.focusoryTextTertiary)
            }

            Spacer(minLength: 4)

            Button {
                isShowingSignOutConfirmation = true
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
            }
            .buttonStyle(FocusoryIconButtonStyle(role: nil))
            .help(Text(.accountActionSignOut))
            .accessibilityIdentifier("account-sign-out-button")
        }
        .padding(.vertical, 6)
        .alert(.accountSignOutConfirmationTitle, isPresented: $isShowingSignOutConfirmation) {
            Button(.commonActionCancel, role: .cancel) {}
            Button(.accountActionSignOut, role: .destructive) {}
        } message: {
            Text(.accountSignOutConfirmationMessage)
        }
    }
}
