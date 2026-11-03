import Foundation

/// 顶层导航目的地：任务、专注、统计。
enum AppDestination: String, CaseIterable, Identifiable {
    case tasks
    case focus
    case statistics

    /// 以导航项自身作为稳定标识，供 ForEach 区分各页面。
    var id: Self { self }

    /// 导航项和页头共同显示的本地化标题。
    var title: LocalizedStringResource {
        switch self {
        case .tasks: .navigationTasksTitle
        case .focus: .navigationFocusTitle
        case .statistics: .navigationStatisticsTitle
        }
    }

    /// 页头中标题下方的本地化说明。
    var subtitle: LocalizedStringResource {
        switch self {
        case .tasks: .navigationTasksSubtitle
        case .focus: .navigationFocusSubtitle
        case .statistics: .navigationStatisticsSubtitle
        }
    }

    /// 侧边栏导航图标使用的 SF Symbol 名称。
    var symbolName: String {
        switch self {
        case .tasks: "checklist"
        case .focus: "timer"
        case .statistics: "chart.bar.xaxis"
        }
    }
}
