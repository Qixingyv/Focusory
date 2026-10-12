# Codex 配置说明

本文件说明仓库内自动加载的 ChatGPT/Codex 与 OpenCode 配置和人类可读文档之间的职责边界，不复制具体产品或架构事实。

## 文件职责

| 位置 | 职责 |
| --- | --- |
| `/AGENTS.md` | ChatGPT/Codex 与 OpenCode 每次任务都应遵循的项目规则、AI 分工、架构方法和验证约定 |
| `/opencode.json` | OpenCode 的本地模型提供者和默认模型配置；当前使用 Ollama `qwen3-coder:30b` |
| `/.agents/skills/` | 按任务触发的可复用工作流 |
| `/.codex/config.toml` | 项目级沙盒、审批和功能开关 |
| `/.codex/rules/` | 命令的允许、确认和禁止规则 |
| `/.codex/hooks.json` | Codex 生命周期 hook 注册；实现检查前不启用 |
| `/.codex/hooks/` | hook 使用的项目脚本 |

## 维护边界

- 产品或架构事实写入 `文档/`，不要复制进技能正文。
- `AGENTS.md` 只保留长期、跨任务都成立的规则，并作为 ChatGPT/Codex 与 OpenCode 的共同约束。
- `opencode.json` 只配置开发执行环境和模型，不承载产品需求、架构决策或单次任务内容。
- 技能负责说明特定任务如何完成，不替代产品需求。
- Rules 控制命令权限，Hooks 在生命周期节点执行确定性检查；两者不要混用。
- Hook 首版只做只读检查和提示，不自动修改业务文档或源码。
