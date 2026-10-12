# 任务卡：按页面与职责拆分 `FocusoryUI.swift`

## 1. 任务信息

- 执行者：OpenCode（本地 Ollama `qwen3-coder:30b`）
- 任务类型：macOS 前端结构重构
- 优先级：P1
- 状态：已完成（历史记录）
- 前置任务：无
- 产品行为变更：无

> 历史说明：本卡描述的页面拆分已经落地。卡中提到的 `Application/Tasks/TaskStore.swift` 已在 F01 任务管理 P0 实现中删除，任务状态改由 `Features/Tasks/TaskListModel` 与 `Application/Tasks` 用例承载；本卡只作为该次重构的记录保留。

## 2. 目标

将当前集中在 `Focusory/Focusory/Features/FocusoryUI.swift` 中的根导航、页面、页面专属组件和共享 UI，按照开发视图已定义的 `App`、`Features/Tasks`、`Features/Focus`、`Features/Statistics` 与 `Features/Shared` 边界拆分为独立 Swift 文件。

本任务只调整源码物理组织和必要的访问级别，必须保持现有界面、交互、状态流转、本地化资源、无障碍标识和测试行为不变。完成后删除已经搬空的 `FocusoryUI.swift`。

## 3. 非目标

- 不新增、删除或改变任何产品功能、业务规则或交互流程。
- 不调整页面布局、颜色、字体、间距、动画、控件外观或窗口尺寸。
- 不重构 `TaskStore`、`FocusTask` 或其他领域与应用层代码。
- 不引入 ViewModel、路由框架、依赖注入框架或其他新架构抽象。
- 不实现专注页、统计页、本地持久化、同步或 Python 后端能力。
- 不新增生产依赖，不修改部署目标和构建设置。
- 不修改 `Localizable.xcstrings` 中的 key、文案或翻译。
- 不顺手修复与文件拆分无关的问题，也不进行全项目格式化。
- 不修改用户故事、功能文档、逻辑视图、过程视图或物理视图；本任务没有产品行为变化。

## 4. 前置阅读

开始修改前，按顺序完整阅读：

1. 根目录 `AGENTS.md`。
2. `文档/AI开发/01-AI开发流程.md`。
3. `文档/架构/02-开发视图.md`，重点阅读 macOS 客户端目标目录、模块责任与依赖规则。
4. `文档/架构/08-代码注释原则.md`。
5. `文档/架构/09-SwiftUI样式规则.md`，重点阅读文件组织规则。
6. `Focusory/Focusory/Features/FocusoryUI.swift`。
7. `Focusory/Focusory/Features/Shared/FocusoryStyle.swift`。
8. `Focusory/Focusory/App/FocusoryApp.swift`。
9. `Focusory/Focusory/Application/Tasks/TaskStore.swift`。
10. `Focusory/Focusory/Domain/Tasks/FocusTask.swift`。
11. `Focusory/FocusoryUITests/FocusoryUITests.swift`。

## 5. 影响模块与目标文件

### 5.1 App 组装与根导航

创建以下文件：

```text
Focusory/Focusory/App/
├─ ContentView.swift
├─ AppDestination.swift
└─ AppSidebar.swift
```

- `ContentView.swift`：只保留应用根布局、页面页头、`TaskStore` 生命周期和页面切换。
- `AppDestination.swift`：保存根导航目的地及其标题、说明和图标展示映射。
- `AppSidebar.swift`：保存侧边栏、导航入口和当前本地账户区域。
- `ContentView` 的预览跟随 `ContentView.swift`。

### 5.2 Tasks 功能

创建以下文件：

```text
Focusory/Focusory/Features/Tasks/
├─ TaskScreen.swift
├─ TaskCard.swift
├─ TaskEditorSheet.swift
└─ TaskPresentation.swift
```

- `TaskScreen.swift`：保存任务筛选、空状态、任务列表、新建/编辑弹窗入口和页面预览。
- `TaskCard.swift`：保存任务卡片及其私有 `InlineTaskAction`。
- `TaskEditorSheet.swift`：保存任务编辑弹窗及只被该弹窗使用的私有 `FocusoryNumberStepper`。
- `TaskPresentation.swift`：保存 `FocusTaskMode` 与 `FocusTaskStatus` 的展示层本地化映射。

### 5.3 Focus 与 Statistics 功能

创建以下文件：

```text
Focusory/Focusory/Features/Focus/FocusPlaceholderView.swift
Focusory/Focusory/Features/Statistics/StatisticsPlaceholderView.swift
```

占位页只移动到所属功能目录，不改变内容或命名。

### 5.4 Shared UI

在 `Focusory/Focusory/Features/Shared/` 下创建：

```text
FocusoryCardStyle.swift
FocusoryButtonStyles.swift
FocusorySegmentedControl.swift
FocusorySwitchToggleStyle.swift
```

- `FocusoryCardStyle.swift`：保存 `FocusoryCardModifier` 和对应 `View` 扩展。
- `FocusoryButtonStyles.swift`：保存填充、描边、图标按钮样式、按钮内部私有视图，以及 `focusoryPrimaryButton` 扩展。
- `FocusorySegmentedControl.swift`：保存 `FocusorySegmentedItem` 与 `FocusorySegmentedControl`。
- `FocusorySwitchToggleStyle.swift`：保存 `FocusorySwitchToggleStyle`。
- 保留现有 `FocusoryStyle.swift`，继续只负责跨功能字体与尺寸语义。

## 6. 接口与架构约束

1. `ContentView` 继续持有 `selectedDestination` 和 `TaskStore`；不得把这些状态搬入页面或创建新的状态容器。
2. `TaskScreen` 的公开调用形式保持为 `TaskScreen(store:onStartFocus:)`。
3. `TaskCard`、`TaskEditorSheet` 和所有共享控件的调用方式保持不变。
4. 不得修改现有本地化资源符号、SF Symbols 名称和 `accessibilityIdentifier`。
5. 跨文件使用但不需要跨模块暴露的类型使用 Swift 默认的 `internal` 访问级别，不显式添加无必要的 `public`。
6. 文件内实现细节继续保持 `private`：
   - 各按钮样式的内部 Body 视图与对应按钮样式放在同一文件。
   - `InlineTaskAction` 与 `TaskCard` 放在同一文件。
   - `FocusoryNumberStepper` 与 `TaskEditorSheet` 放在同一文件。
7. 只有跨功能复用的 UI 才能放入 `Features/Shared`；任务专属组件不得为了缩短文件而提升为共享组件。
8. 每个文件仅导入实际需要的模块。使用 `Date`、`UUID` 等 Foundation 类型的文件显式导入 `Foundation`。
9. 保留并按新文件职责调整现有 `///` 文档注释；所有函数、初始化器、UI 类型、成员变量和计算属性继续符合项目注释规则。
10. Xcode 工程使用文件系统同步分组。正常情况下不得手工编辑 `Focusory.xcodeproj/project.pbxproj`；若新文件未自动进入 App target，停止并报告，不自行改造工程结构。
11. 除解决拆分后编译可见性所需的最小改动外，不改变任何实现逻辑。

## 7. 实现步骤

1. 在修改前运行一次 App target 构建，记录当前基线是否通过。若基线失败，保存完整错误并停止，避免把既有错误混入本任务。
2. 创建 `Features/Tasks`、`Features/Focus` 和 `Features/Statistics` 目录。
3. 将根布局、导航枚举和侧边栏分别移动到 `App` 下的目标文件。
4. 将共享卡片、按钮、分段控件和开关样式移动到 `Features/Shared` 下的目标文件。
5. 将任务页面、任务卡片、任务编辑弹窗和展示映射移动到 `Features/Tasks` 下的目标文件，并保持页面专属私有类型就近放置。
6. 将专注与统计占位页移动到各自功能目录。
7. 处理拆分造成的最小访问级别和 import 问题；不得借此改变 API 或引入新的抽象。
8. 确认所有声明只存在一份后，删除 `Focusory/Focusory/Features/FocusoryUI.swift`。
9. 更新 `文档/架构/02-开发视图.md` 的“当前代码基线”和相关实现位置描述，使其反映已经按 `App`、各 Feature 与 `Shared` 拆分的现状。不要修改没有受到影响的视图文档。
10. 运行格式、构建和测试验证，人工检查 diff 中不存在行为变化和无关重构。

## 8. 验收标准

- `Focusory/Focusory/Features/FocusoryUI.swift` 已删除，不再存在重复类型声明。
- 根导航文件位于 `App`，页面文件位于对应 Feature，共享 UI 位于 `Features/Shared`。
- `FocusoryNumberStepper` 没有被提升到 Shared；`InlineTaskAction` 没有离开 `TaskCard.swift`。
- App target 成功构建，未出现因拆分导致的找不到类型、访问级别或重复声明错误。
- 现有单元测试和 UI 测试通过。
- 启动应用后默认仍显示任务页，侧边栏切换、任务空状态、新建任务弹窗、任务卡片操作行为与拆分前一致。
- 所有原有 `accessibilityIdentifier` 保持不变，现有 UI 测试无需因选择器变化而修改。
- `Localizable.xcstrings`、领域模型、`TaskStore`、构建设置和 `project.pbxproj` 没有修改。
- 没有新增依赖，也没有新的编译警告。
- `文档/架构/02-开发视图.md` 不再把 `FocusoryUI.swift` 描述为当前集中实现位置。
- `git diff --check` 通过，diff 中不包含与任务无关的文件。

## 9. 验证命令

从仓库根目录依次运行：

```bash
git diff --check

xcodebuild \
  -project Focusory/Focusory.xcodeproj \
  -scheme Focusory \
  -destination 'platform=macOS' \
  build

xcodebuild \
  -project Focusory/Focusory.xcodeproj \
  -scheme Focusory \
  -destination 'platform=macOS' \
  test

rg -n '^(struct|enum|extension) (ContentView|AppDestination|AppSidebar|TaskScreen|TaskCard|TaskEditorSheet|FocusPlaceholderView|StatisticsPlaceholderView|FocusoryCardModifier|FocusoryFilledButtonStyle|FocusoryOutlineButtonStyle|FocusoryIconButtonStyle|FocusorySegmentedItem|FocusorySegmentedControl|FocusorySwitchToggleStyle)' \
  Focusory/Focusory/App \
  Focusory/Focusory/Features
```

如果完整 `test` 因本机 UI 测试运行环境失败，需要继续完成 `build`，单独记录环境错误与已运行的测试；不得把环境失败描述为测试通过。

## 10. 停止条件

出现以下任一情况时停止实现并把问题交回 Codex，不自行扩大范围：

- 当前基线在移动文件前就无法构建。
- 必须改变产品行为、业务规则、状态所有权或公开调用形式才能完成拆分。
- 必须修改本地化 key、UI 测试选择器或领域模型。
- Xcode 文件系统同步分组没有自动纳入新文件，需要重构工程配置。
- 发现文档与当前实现存在会影响文件归属的冲突。
- 验证暴露出与本任务无关、需要额外设计决定的问题。

## 11. 完成报告格式

完成后向 Codex 提交以下信息，不自行宣布产品或里程碑完成：

1. 修改、创建和删除的文件清单。
2. 实际执行的验证命令及每条命令的结果。
3. 与任务卡相比存在的任何偏差及原因。
4. 未解决问题和潜在风险；没有也要明确写“无”。
5. 建议 Codex 重点审查的访问级别、文件归属或行为回归点。
