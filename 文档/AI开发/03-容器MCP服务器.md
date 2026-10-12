# 容器 MCP 服务器

## 目的

为 Codex 提供可审计、范围受限的本机容器控制能力，使开发者可以通过 MCP 查看 Docker/OrbStack 状态、排查容器问题并管理 Compose 项目。

该能力服务开发流程，不属于 Focusory 面向最终用户的番茄钟功能，因此不改变产品用例视图和核心领域模型。

本文档归入 AI 开发分区，相关采用决策记录在 [`04-决策记录.md`](./04-决策记录.md)；Focusory 产品的开发、过程和物理视图不重复维护该工具的内部架构。

## 受众

- 使用 Codex 开发和调试 Focusory 的开发者。
- 维护 Python 工具和安全策略的后端开发人员。
- 需要核对工具权限、破坏性操作和运行边界的测试或安全人员。

## 核心内容

### 用例边界

成功流程：

1. Codex 通过 STDIO 启动 MCP Server。
2. Server 返回跨工具安全说明与工具定义。
3. Codex 先查询运行时、容器或 Compose 状态。
4. 需要时调用启动、停止或重启工具。
5. Server 校验参数和路径，在无 shell 模式下调用本机 `docker` 或 `orb` CLI。
6. Server 返回结构化状态、退出码、输出和耗时。

失败流程：

- Docker 或 OrbStack 未安装时返回可诊断的命令错误。
- Docker Engine 未运行时保留 Docker CLI 的错误信息。
- Compose 路径超出白名单时拒绝执行。
- 容器或服务标识可能被解析为命令选项时拒绝执行。
- 命令超时或输出超限时返回对应标志，不无限等待或无限扩充模型上下文。
- 高影响操作缺少显式确认时拒绝执行。

### 开发视图

代码独立位于 `/Users/qixingyu/Documents/Codex/tools/focusory-container-mcp/`，不放入 Focusory 产品代码仓库：

```text
focusory-container-mcp/
├── pyproject.toml
├── src/focusory_container_mcp/
│   ├── server.py       # MCP 工具声明和 STDIO 入口
│   ├── services.py     # Docker、Compose、OrbStack 用例服务
│   ├── policy.py       # 路径白名单和输入校验
│   └── runner.py       # 无 shell、带超时和输出限制的进程执行
└── tests/
```

依赖方向为 `server -> services -> policy/runner`。策略和进程执行层不依赖 MCP SDK，便于独立测试。容器与 Compose 能力统一使用 Docker CLI；OrbStack 适配只负责运行时生命周期，因为 OrbStack 已提供兼容的 Docker Engine 和 context。

公开接口为 17 个 MCP 工具：

- 运行时：`runtime_status`、`runtime_start`、`runtime_stop`、`runtime_restart`。
- 容器查询：`container_list`、`container_inspect`、`container_logs`、`container_stats`。
- 容器生命周期：`container_start`、`container_stop`、`container_restart`。
- Compose：`compose_list`、`compose_inspect`、`compose_up`、`compose_stop`、`compose_restart`、`compose_down`。

### 过程视图

- MCP Server 是由 Codex 启动的本地 STDIO 子进程。
- 每次工具调用同步等待一个或少量本机 CLI 进程完成。
- 普通命令默认 30 秒超时；构建和生命周期操作使用明确的更长上限。
- 单个 stdout、stderr 默认最多返回 512000 字节。
- `container_stats` 只读取一次快照，`container_logs` 不开启无限 follow。
- 当前版本不维护共享业务状态；并发一致性交给 Docker Engine。调用方不应并行修改同一个容器或 Compose 项目。

### 物理视图

- 运行节点：开发者本机 macOS。
- MCP 通信：本机 STDIO，不监听网络端口。
- 容器通信：本机 Docker CLI 连接当前 context，OrbStack 通常使用 `orbstack` context。
- 文件访问：Compose 项目目录必须位于 `FOCUSORY_MCP_ALLOWED_ROOTS`。
- 凭据：Server 不读取或返回 Docker Registry 凭据，也不提供登录工具。
- 恢复：MCP 子进程可由 Codex 重启；停止或重启容器后的业务恢复由 Compose/Docker 健康检查负责。

### 安全规则

- 所有命令以参数数组执行，禁止 shell 拼接。
- 不提供任意 Docker 命令、容器内 exec、prune、镜像或卷删除。
- 不提供 privileged、Docker Socket 挂载或宿主根目录挂载能力。
- `compose_up` 在变更状态前解析最终配置，并拒绝特权模式、host PID/IPC、高危 capability、宿主设备和白名单外的本地路径。
- `compose_inspect` 遮盖密码、secret、token、credential 和私钥等敏感配置字段，不返回含敏感值的原始 Compose 配置输出。
- `runtime_stop` 与 `compose_down` 要求 `confirm=true`。
- `compose_down` 默认不删除 volume。
- MCP 工具声明只读、幂等和破坏性提示，供客户端决策和审批使用。
- Codex 接入建议使用 `default_tools_approval_mode = "writes"`，只读查询可直接执行，状态变更继续经过客户端审批。

## 交付物

- 可安装的 `focusory-container-mcp` Python 包和命令行入口。
- 17 个具备结构化输入输出的 MCP 工具。
- 路径白名单、显式确认、超时和输出限制。
- 服务单元测试与真实 STDIO MCP 握手测试。
- Codex CLI 和项目 `config.toml` 接入示例。

## 交付标准

- Python 3.11 及以上环境可以安装并启动 Server。
- MCP 客户端可以初始化会话并发现全部 17 个工具。
- 查询操作不会改变容器状态。
- 受限路径和非法标识在执行子进程前被拒绝。
- 高影响操作没有显式确认时不执行。
- Server 不监听网络，不暴露通用 shell 或 Docker Socket。
- 自动化测试覆盖核心安全边界、输出限制和 STDIO 握手。
