# 功能文档索引

本目录以用户能够感知的完整能力为单位组织文档。一个功能可以覆盖多个用例，但每个用例只能明确归属到一个主功能，避免重复维护相同流程。

| 编号 | 功能 | 对应用例 | 优先级 | 文档状态 | 流程图状态 |
| --- | --- | --- | --- | --- | --- |
| F01 | [任务管理](F01-任务管理.md) | UC-02、UC-06、UC-07、UC-08、UC-12、UC-13 | P0 | P0 本机闭环已实现；P1 同步待实现 | 泳道图已渲染（图片 + `.mmd` 源） |
| F02 | [专注计时](F02-专注计时.md) | UC-03、UC-04 | P0 | 待梳理 | 待补充 |
| F03 | [休息](F03-休息.md) | UC-05 | P0 | 待梳理 | 待补充 |
| F04 | [今日统计](F04-今日统计.md) | UC-09 | P0 | 待梳理 | 待补充 |
| F05 | [账户与身份](F05-账户与身份.md) | UC-01、UC-11、UC-14 | P1 | 设计就绪（部分） | 泳道图已补充（Mermaid） |
| F06 | [离线与同步](F06-离线与同步.md) | UC-10 | P1 | 待梳理 | 待补充 |

## 单份功能文档要求

每份文档应作为该功能的端到端设计入口，使后续设计、开发和测试 AI 能判断目标与非目标、设计依据、所需数据、完整流程、业务规则与状态、前后端和外部系统的交付边界、接口与同步契约、4+1 影响、实现位置、验收标准和测试覆盖。文档至少包含一张主流程图和一张完整功能泳道图；泳道图至少包含用户、前端、后端，覆盖关键成功、失败和恢复路径。无后端、同步或外部接口影响时也要明确写出结论和依据。

上述内容必须写入功能文档正文。模板中的必填章节或交付面不适用时，写明“不适用”或“不需要”及依据，不得只在对话总结、任务卡或其他文档中补充。

功能文档解释端到端行为，不代替用例规格或架构视图。跨功能的业务规则继续以 [`02-用户故事.md`](../02-用户故事.md) 中的编号规则为准，功能文档只引用，不复制定义。

## 功能图交付与渲染规则

### 交付形式

功能图以「Mermaid `.mmd` 图源 + 渲染后的 PNG 图片」成对交付，两者放在功能文档同目录的 `assets/` 下并保持同名：

- 文档正文嵌入图片。宽幅 Mermaid 泳道图在 Obsidian 等查看器中会被裁切或缩放到无法阅读，图片可保证完整显示。
- `.mmd` 图源必须与图片一起提交，用于审查和重新渲染；不得只保留图片，也不得只保留正文中的 Mermaid 代码块。
- 正文、图源、图片三者的内容必须在同一变更中保持一致。

文档中的引用格式：

````markdown
![Fxx 分角色泳道图](assets/Fxx-swimlane.png)

图源：[`assets/Fxx-swimlane.mmd`](assets/Fxx-swimlane.mmd)，由 Mermaid 渲染为图片；修改流程后需重新渲染。
````

### 命名

- 图源与图片同名成对：`assets/Fxx-swimlane.mmd` 与 `assets/Fxx-swimlane.png`。
- 一份文档有多张图时用用途后缀区分，例如 `Fxx-main-flow.png`、`Fxx-swimlane.png`。

### 绘制约定

- 判断节点的分支统一写 `PASS` / `NG`；不是成败判定的第三分支（如“待同步”“开始专注”）保留描述性文字。
- 泳道至少覆盖用户、前端、后端；不参与的泳道保留并说明原因。
- 使用白色背景渲染，保证在浅色和深色查看器中均可读。
- 泳道图优先使用横向 `flowchart LR`（一列一条泳道）。图像过宽导致内联不可读时，优先拆成多张图，不要强行改为 `TB`：实测 `TB` 容易出现节点裁切和连线交叉。

### 渲染命令

在仓库根目录执行。首次运行通过 `npx` 下载 `mermaid-cli`，之后走本地缓存。

```bash
mkdir -p .render-tmp
cat > .render-tmp/puppeteer-config.json <<'JSON'
{
  "executablePath": "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
  "args": ["--no-sandbox", "--disable-setuid-sandbox"]
}
JSON

PUPPETEER_SKIP_DOWNLOAD=true npx -y @mermaid-js/mermaid-cli \
  -i "文档/产品/功能/assets/F01-task-swimlane.mmd" \
  -o "文档/产品/功能/assets/F01-task-swimlane.png" \
  --size 2600 -s 2 -b white \
  -p .render-tmp/puppeteer-config.json

rm -rf .render-tmp
```

关键参数与注意事项：

- 当前 `mermaid-cli` 用 `--size` 控制最大边长，没有 `-w` 参数；`-s 2` 输出 2 倍分辨率，`-b white` 设置白色背景。
- 通过 `-p puppeteer-config.json` 复用本机 Google Chrome；同时设置 `PUPPETEER_SKIP_DOWNLOAD=true`，避免 puppeteer 额外下载 Chromium。
- 本机 `~/.npm` 缓存权限异常报 `EPERM` 时，追加 `npm_config_cache="<仓库内临时目录>"` 使用独立缓存。
- 渲染依赖会写入 `npx` 缓存（可达数百 MB），必须放在仓库临时目录并在渲染后删除，不得提交。

### 维护

流程、角色或分支变化时，先改 `.mmd` 图源，再按上节命令重新渲染覆盖 PNG；仅更新图片而图源未同步，或反之，均视为未完成。
