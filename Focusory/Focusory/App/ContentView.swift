import Foundation
import SwiftUI

/// 提供任务、专注和统计之间的切换，并组合各页面的页头与内容。
struct ContentView: View {
    /// 应用启动时创建的依赖，用来初始化任务列表模型。
    let dependencies: AppDependencies
    /// 当前选中的业务页面，与 TabView 的选择双向同步。
    @State private var selectedDestination: AppDestination = .tasks
    /// 保存任务列表状态，切换顶层页面时继续使用。
    @State private var taskListModel: TaskListModel

    /// 接收应用依赖，并为任务列表状态提供初始对象。
    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _taskListModel = State(initialValue: TaskListModel(environment: dependencies.taskEnvironment))
    }

    /// 显示侧边栏导航及当前选中的业务页面。
    var body: some View {
        TabView(selection: $selectedDestination) {
            ForEach(AppDestination.allCases) { destination in
                Tab(value: destination) {
                    destinationPage(destination)
                } label: {
                    Label {
                        Text(destination.title)
                    } icon: {
                        Image(systemName: destination.symbolName)
                    }
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabViewSidebarHeader {
            AppTabSidebarHeader()
        }
        .tabViewSidebarBottomBar {
            AppTabSidebarBottomBar()
        }
        .tint(Color.focusoryAccent)
        .frame(minWidth: 900, minHeight: 620)
        .preferredColorScheme(.light)
    }

    /// 将指定页面的页头和功能内容上下排列。
    private func destinationPage(_ destination: AppDestination) -> some View {
        VStack(spacing: 0) {
            pageHeader(for: destination)
            destinationContent(for: destination)
        }
        .background(Color.focusoryPageBackground)
    }

    /// 显示页面标题、说明与同步状态的页头。
    private func pageHeader(for destination: AppDestination) -> some View {
        HStack(alignment: .center, spacing: 24) {
            VStack(alignment: .leading, spacing: 5) {
                Text(destination.title)
                    .font(FocusoryTypography.pageTitle)
                    .foregroundStyle(Color.focusoryTextPrimary)

                Text(destination.subtitle)
                    .font(FocusoryTypography.supporting)
                    .foregroundStyle(Color.focusoryTextTertiary)
            }

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(Color.focusorySuccess)
                    .frame(width: 6, height: 6)
                Text(.appSyncStatus)
                    .font(FocusoryTypography.captionEmphasized)
                    .foregroundStyle(Color.focusoryTextSecondary)
            }
            .padding(.horizontal, 10)
            .frame(height: 26)
            .background(Color.focusorySurface)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(Color.focusoryBorder, lineWidth: 1)
            }
        }
        .frame(maxWidth: FocusoryMetrics.mainContentWidth)
        .padding(.horizontal, FocusoryMetrics.pageHorizontalPadding)
        .padding(.top, 28)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("page-header")
    }

    /// 根据导航选择提供任务、专注或统计页面。
    @ViewBuilder
    private func destinationContent(for destination: AppDestination) -> some View {
        switch destination {
        case .tasks:
            TaskScreen(model: taskListModel) {
                selectedDestination = .focus
            }
        case .focus:
            FocusPlaceholderView()
        case .statistics:
            StatisticsPlaceholderView()
        }
    }
}

#Preview {
    if let dependencies = try? AppDependencies.makeInMemory() {
        ContentView(dependencies: dependencies)
            .frame(width: 1180, height: 760)
    } else {
        Text(verbatim: "preview unavailable")
    }
}
