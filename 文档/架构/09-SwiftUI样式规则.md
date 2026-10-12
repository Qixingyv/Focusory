# Focusory SwiftUI 样式规则

## 1. 目的与范围

本文规定 Focusory macOS 客户端的 SwiftUI 样式写法，用于把《原型 UI 规范》中的视觉参数稳定映射为可维护、可适配和可审查的原生代码。

- 受众：macOS 开发人员、代码审查人员、UI 测试人员和后续参与界面实现的 AI 开发代理。
- 适用范围：`Features` 下的页面、组件、`ViewModifier`、`ButtonStyle`、布局辅助类型和 Asset Catalog 颜色资源。
- 不覆盖：产品视觉取舍、业务状态与用户流程；这些内容仍以产品文档、用例视图和功能文档为准。
- 交付标准：新增界面无需复制颜色或字号字面值，能够在窗口缩放、内容增长和本地化文本变化时保持结构稳定。

本文从 Apple 官方 [Food Truck](https://github.com/apple/sample-food-truck)、[Backyard Birds](https://github.com/apple/sample-backyard-birds) 和 [Composing Custom Layouts with SwiftUI](https://github.com/apple-sample-code/ComposingCustomLayoutsWithSwiftUI) 示例中提炼工程习惯。示例项目用于讲解 API，并非 Apple 内部编码规范；本文的“必须/应该/可以”是 Focusory 的项目化决策。

## 2. 真值来源与优先级

样式实现发生冲突时按以下顺序判断：

1. 用户流程、状态和可访问性要求：`文档/产品/02-用户故事.md` 及对应功能文档。
2. 视觉表现和验收参数：`文档/产品/05-原型UI规范.md`。
3. SwiftUI 代码写法：本文。
4. 单个页面或组件的局部实现。

原型中的 CSS、Tailwind、JSX 和 SVG 只表达视觉结果，不直接决定 SwiftUI 结构。不得为了逐字翻译原型而放弃原生控件、自适应布局或资源语义。

## 3. 总体原则

1. 系统语义优先：优先使用 SwiftUI 原生容器、控件、Shape、Material、`foregroundStyle` 和平台环境值。
2. 约束优先：使用父容器、理想尺寸、最小/最大尺寸和自适应网格表达布局，不使用绝对坐标拼装页面。
3. 视觉角色优先：颜色、字体和共享尺寸按用途命名，不按色值、像素值或控件所在位置命名。
4. 局部数值局部化：只把跨功能稳定复用的参数放进共享样式；组件特有参数留在组件内部或组件专属 `Metrics` 中。
5. 原生交互优先：按钮、表单、导航、列表和弹窗先组合系统能力，只有产品原型明确要求的品牌状态才自定义样式。
6. 可访问性不是补丁：样式不能只依赖颜色表达状态，文本缩放、本地化长度、键盘操作和稳定无障碍标识必须在初次实现时考虑。

## 4. 布局规则

### 4.1 页面结构

- 页面层级优先使用 `NavigationSplitView`、`NavigationStack`、`List`、`Table`、`ScrollView`、`Grid`、`LazyVGrid` 和 `LazyVStack`。
- Focusory 的任务、专注和统计属于平级顶层功能，根导航使用 `TabView` 的 `.sidebarAdaptable` 样式；品牌和账户信息只通过系统提供的侧边栏 header/bottom bar 扩展，账户区固定在底部，不自行重写标签选择行为。
- 功能内部出现列表—详情或更深层级时，再在对应标签内评估 `NavigationSplitView` 或 `NavigationStack`，不得用第二套根导航状态替代 `TabView` 的选择绑定。
- 宽窗口中的正文必须通过 `maxWidth` 收敛，并使用父容器对齐，不通过计算左右坐标居中。
- 滚动容器优先通过 `contentMargins` 或滚动内容自身的 padding 定义边距，避免在多层容器重复补偿。

### 4.2 自适应

- 根据可用空间、Size Class、动态字体或环境值决定布局，不根据具体 Mac 型号或屏幕名称分支。
- 一组内容需要在横排和竖排间切换时，优先考虑 `ViewThatFits` 或 `AnyLayout`。
- 重复卡片优先使用 `.adaptive(minimum:)` 网格；最小宽度应由内容可读性决定。
- 只有内建布局无法表达稳定关系时才实现 `Layout`；自定义布局应读取子视图理想尺寸和系统间距。

### 4.3 固定尺寸

固定尺寸只用于具有明确视觉或交互含义的对象，例如：

- 图标、头像、进度轨道和缩略图；
- 不低于产品要求的点击目标；
- 弹窗、窗口和内容区的最小或最大边界；
- 原型明确要求固定高度的空状态或计时器。

不得为普通文本、可本地化按钮标题或动态列表内容设置仅为“对齐截图”的固定宽高。

## 5. 间距与尺寸

- 无明确视觉要求时优先使用 `padding()`、Stack 默认间距或子视图首选间距。
- 原型已有明确参数时使用显式值，并优先在父容器通过 `spacing` 或 `padding` 管理关系。
- 不给连续子视图分别叠加零散 margin；同组元素的间距由最近的共同父容器负责。
- 页面级稳定尺寸放入 `FocusoryMetrics`；只被一个组件使用的尺寸不得提升为全局 token。
- 跨平台组件拥有成组差异时，可以建立组件专属 `Metrics`，按平台集中构造一组值。

Focusory 当前推荐尺度为：4 pt 微间距、8 pt 紧凑间距、12 pt 组件间距、16 pt 卡片内边距、20/24 pt 区块间距、32 pt 页面边距。该尺度用于减少随意取值，不覆盖《原型 UI 规范》中的明确参数。

## 6. 颜色规则

### 6.1 系统颜色与项目颜色

- 系统结构语义优先使用 `.primary`、`.secondary`、`.tertiary`、`.background`、`.fill`、`.separator` 或对应 macOS 系统色。
- Focusory 品牌与产品语义使用 Asset Catalog，例如 `.focusoryAccent`、`.focusorySuccess`、`.focusoryDanger`、`.focusorySurface`。
- 项目颜色按角色命名，不使用 `red500`、`gray100` 或 `lightCard` 等色值/外观名称。
- Swift 文件中禁止新增 RGB、十六进制颜色或无语义的临时颜色。
- 卡片、弹窗、输入框和选中项的白色表面必须使用 `.focusorySurface`，不得直接使用 `.white`。
- `.white` 可以用于主题色上的高对比前景或系统开关滑块等明确需要纯白的视觉元素。

### 6.2 深色外观

Focusory 当前原型明确以浅色外观交付，根视图暂时固定浅色。不得只为单个组件增加孤立的深色分支；启用深色模式时，必须在同一变更中：

1. 为所有结构、文字、边框和品牌表面补齐 Dark Appearance；
2. 移除根视图的强制浅色设置；
3. 验证 Material、阴影、图片和状态对比度；
4. 增加深色预览或 UI 验证。

### 6.3 Material 与阴影

- Material 只用于需要透出下层内容的浮层、图片叠加信息或系统感面板，不作为普通卡片的默认背景。
- 阴影用于表达层级，不用于代替边框或对比度；同类组件应复用一致的阴影参数。
- 状态不能只通过颜色、透明度或阴影表达，必须同时提供文字、图标或形状差异。

## 7. 字体规则

- Focusory 的高保真原型要求固定字号；代码必须通过 `FocusoryTypography` 的语义角色使用这些字号，不在具体 View 中重复 `.system(size:weight:)`。
- 新增文本先判断其角色是否能复用已有层级，例如页面标题、正文、辅助说明、表单标签、元信息或徽标。
- 只有大型计时数字、装饰图形、SF Symbol 或平台特有紧凑界面可以在局部声明特殊字体；声明处需要说明其视觉约束。
- 数值宽度变化会造成布局跳动时使用 `.monospacedDigit()`。
- 不通过无限缩小字体解决空间不足，应先调整布局、允许换行或切换布局方式。
- 字重最高默认使用 `.semibold`；只有新的产品视觉基线明确要求时才引入 `.bold`。

## 8. 形状、表面与控件

- 背景和形状同时确定时优先使用 `.background(style, in: shape)`，避免不必要的 background/clip 组合。
- 卡片和弹窗使用 `.continuous` 圆角；徽标使用小圆角，状态胶囊使用 `Capsule`，圆形按钮使用 `Circle`。
- 子元素需要继承父容器轮廓时使用 `ContainerRelativeShape` 或容器相对形状，而不是复制父圆角数值。
- 原生操作优先使用 `.buttonStyle(.plain/.bordered/.borderedProminent)`、`.controlSize` 和 `.buttonBorderShape`。
- 自定义 `ButtonStyle` 必须覆盖默认、hover、pressed 和 disabled 状态，并保持键盘与辅助功能语义。
- 危险操作继续遵守功能文档中的确认规则，不能因为样式抽取而改变交互流程。

## 9. 修饰器顺序

同类 View 应尽量保持以下顺序，便于审查 modifier 的作用范围：

1. 内容变换：`font`、`fontWeight`、`symbolVariant`、`lineLimit`；
2. 前景与文本：`foregroundStyle`、`multilineTextAlignment`；
3. 内容空间：`padding`；
4. 布局约束：`frame`、`fixedSize`、`layoutPriority`；
5. 表面与形状：`background`、`clipShape`、`overlay`、`shadow`；
6. 交互状态：`contentShape`、`onHover`、`animation`；
7. 平台语义：按钮/控件样式、导航、帮助、无障碍标识。

顺序不是格式化规则；当 modifier 语义需要不同作用范围时，以正确渲染和交互为准，并让差异在代码中清晰可见。

## 10. 文件组织

- 跨功能稳定复用的尺寸和字体放在 `Features/Shared/FocusoryStyle.swift`。
- 共享品牌颜色放在 `Resources/Assets.xcassets`，由 Xcode 生成类型安全符号。
- 跨功能复用的 View、`ViewModifier`、`ButtonStyle` 和 `ToggleStyle` 放在 `Features/Shared`。
- 只服务单个功能的样式与 Metrics 留在对应 `Features/<Feature>` 内。
- Domain 不保存颜色、字体、图标名或用户可见文案；领域枚举的展示映射位于 Features。
- Preview 与组件放在同文件或相邻文件，至少覆盖典型内容、空内容和最长合理文本。

## 11. 本地化与可访问性

- 用户可见静态文案继续通过 String Catalog 和 `LocalizedStringResource` 提供。
- 不用固定宽度裁切可本地化按钮文字；必须裁切的单行数据需要提供完整 help 或辅助功能值。
- 图标按钮必须具有可本地化的 label/help，并提供稳定的 `accessibilityIdentifier` 供 UI 测试使用。
- 选中、完成、错误、警告和禁用状态不得只依赖颜色。
- 新增组件至少人工检查：最长中文、英文或伪语言长度、窗口最小宽度、键盘焦点、VoiceOver 名称和禁用状态。

## 12. 代码审查清单

- [ ] 是否优先使用原生容器、控件和系统环境值？
- [ ] 布局是否依据可用空间，而不是设备名称或绝对坐标？
- [ ] 固定宽高是否只用于确有物理或视觉意义的元素？
- [ ] 表面色是否使用 `.focusorySurface`，结构色和品牌色是否具有语义？
- [ ] View 中是否没有新增 RGB、十六进制颜色和重复的固定字号？
- [ ] 字体是否通过 `FocusoryTypography` 或有明确说明的局部特殊字体使用？
- [ ] 共享参数与组件局部参数是否处于正确作用域？
- [ ] modifier 顺序是否能清楚表达作用范围？
- [ ] hover、pressed、disabled、键盘和无障碍状态是否完整？
- [ ] Preview、构建和相关 UI 测试是否通过？

## 13. 参考实现

- `Focusory/Focusory/Features/Shared/FocusoryStyle.swift`：共享尺寸与字体语义。
- `Focusory/Focusory/Resources/Assets.xcassets/FocusorySurface.colorset`：通用内容表面色。
- `Focusory/Focusory/App/ContentView.swift`：系统标签根导航和统一页面容器的应用示例。
- `Focusory/Focusory/Features/Tasks` 与 `Focusory/Focusory/Features/Shared`：当前任务界面和共享组件样式的应用示例。
- `文档/产品/05-原型UI规范.md`：视觉色值、尺寸和组件验收参数。
- `文档/架构/08-代码注释原则.md`：UI 类型、成员、函数与状态属性的注释要求。
