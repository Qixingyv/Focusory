import Foundation
import SwiftUI

/// 使用系统标签导航组织页面标题和当前功能内容的应用主视图。
struct ContentView: View {
    /// 组装根提供的用例依赖。
    let dependencies: AppDependencies
    /// 记录系统标签栏当前选中的顶层功能目的地。
    @State private var selectedDestination: AppDestination = .tasks
    /// 持有任务页面在主视图生命周期内共享的界面状态。
    @State private var taskListModel: TaskListModel

    /// 用组装根依赖创建主视图与任务页面状态。
    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _taskListModel = State(initialValue: TaskListModel(environment: dependencies.taskEnvironment))
    }

    /// 通过可适应侧边栏的系统标签视图组合应用顶层导航和功能页面。
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

    /// 组装给定目的地的页头与功能内容。
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

    /// 返回给定目的地对应的功能页面。
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
