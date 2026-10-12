import SwiftUI

/// 集中声明跨功能共享的页面尺寸和容器形状参数。
enum FocusoryMetrics {
    /// 限制主内容区在宽窗口中的最大宽度。
    static let mainContentWidth: CGFloat = 840
    /// 定义页面主内容与窗口边缘的水平留白。
    static let pageHorizontalPadding: CGFloat = 32
    /// 定义标准内容卡片的圆角半径。
    static let cardRadius: CGFloat = 12
    /// 定义模态弹窗的圆角半径。
    static let modalRadius: CGFloat = 16
}

/// 将原型指定的固定字号映射为可复用的界面语义层级。
enum FocusoryTypography {
    /// 页面一级标题使用的强调字体。
    static let pageTitle = Font.system(size: 24, weight: .semibold)
    /// 空状态图标等页面级符号使用的字体。
    static let pageIcon = Font.system(size: 21, weight: .regular)
    /// 空状态标题等局部标题使用的字体。
    static let sectionTitle = Font.system(size: 15, weight: .medium)
    /// 品牌名和弹窗标题使用的字体。
    static let heading = Font.system(size: 14, weight: .semibold)
    /// 强调型小图标使用的字体。
    static let emphasizedIcon = Font.system(size: 14, weight: .medium)
    /// 常规导航和操作图标使用的字体。
    static let icon = Font.system(size: 14, weight: .regular)
    /// 按钮、任务名和可交互标签使用的字体。
    static let bodyEmphasized = Font.system(size: 13, weight: .medium)
    /// 表单输入和普通正文使用的字体。
    static let body = Font.system(size: 13, weight: .regular)
    /// 页面说明和内联确认信息使用的字体。
    static let supporting = Font.system(size: 12, weight: .regular)
    /// 紧凑按钮和强调型辅助信息使用的字体。
    static let supportingEmphasized = Font.system(size: 12, weight: .medium)
    /// 表单标签和账户名称使用的字体。
    static let label = Font.system(size: 11, weight: .medium)
    /// 任务进度、日期和辅助说明使用的字体。
    static let metadata = Font.system(size: 11, weight: .regular)
    /// 状态、模式与数量徽标使用的字体。
    static let captionEmphasized = Font.system(size: 10, weight: .medium)
    /// 最弱的账户或环境说明使用的字体。
    static let caption = Font.system(size: 10, weight: .regular)
}
