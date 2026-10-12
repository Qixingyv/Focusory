import Foundation

/// 顶层导航目的地：任务、专注、统计。
enum AppDestination: String, CaseIterable, Identifiable {
    case tasks
    case focus
    case statistics

    /// 枚举标识。
    var id: Self { self }

    /// 页头本地化标题。
    var title: LocalizedStringResource {
        switch self {
        case .tasks: .navigationTasksTitle
        case .focus: .navigationFocusTitle
        case .statistics: .navigationStatisticsTitle
        }
    }

    /// 页头本地化说明。
    var subtitle: LocalizedStringResource {
        switch self {
        case .tasks: .navigationTasksSubtitle
        case .focus: .navigationFocusSubtitle
        case .statistics: .navigationStatisticsSubtitle
        }
    }

    /// 侧边栏 SF Symbol 名称。
    var symbolName: String {
        switch self {
        case .tasks: "checklist"
        case .focus: "timer"
        case .statistics: "chart.bar.xaxis"
        }
    }
}
