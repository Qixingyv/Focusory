# Focusory API 约定

## 目的与交付标准

- 目的：作为唯一接口契约，定义当前原型所需的客户端与 Python 业务后端交互。
- 受众：客户端、后端和集成测试人员。
- 交付标准：DTO 不暴露内部持久化对象，写操作可幂等重试，日期时间和错误语义明确。

## 通用约定

- 除登录、微信扫码状态和健康检查外，所有接口都需要 Focusory 登录态。
- 路径使用 `/v1`。
- 实体 ID 和本地操作 ID 使用 UUID。
- 写请求包含 `operation_id`，相同操作重试返回相同业务结果。
- 瞬时使用包含时区的 ISO 8601；本机日期使用 `YYYY-MM-DD` 并同时传递 IANA `time_zone_id`。
- 客户端不依赖人类错误文案判断类型，错误包含稳定 `code`、`message` 和可选 `field`。

## 账户接口

- `POST /v1/auth/apple/exchange`：验证 Apple 身份证明，通过已绑定 Apple 身份进入 Focusory 账户；首次登录时原子创建账户和首条身份绑定。
- `POST /v1/auth/wechat/qr-sessions`：创建微信扫码登录会话。
- `GET /v1/auth/wechat/qr-sessions/{id}`：查询待扫码、已扫码、已确认、过期或失败状态；已确认时通过已绑定微信身份登录，首次登录则原子创建账户和身份绑定。
- `GET /v1/me`：获取当前账户，包含 `bound_providers: [apple | wechat]`，不返回第三方原始凭据。
- `POST /v1/auth/logout`：失效当前登录态。本地数据清理由客户端在成功或明确的本地退出流程中执行。

### 身份绑定接口

- `POST /v1/me/identity-bindings/apple`：当前账户重新验证 Apple 身份并建立绑定。
- `POST /v1/me/identity-bindings/wechat/qr-sessions`：为当前账户创建微信扫码绑定会话。
- `GET /v1/me/identity-bindings/wechat/qr-sessions/{id}`：查询微信绑定会话；确认后原子创建身份绑定。
- `DELETE /v1/me/identity-bindings/{provider}`：解绑 Apple 或微信；事务内确认解绑后至少保留一个可登录身份。

绑定写请求必须包含 `operation_id`。当前账户重复绑定同一第三方身份时按幂等成功返回；同一 provider 已绑定不同身份，或目标身份已属于另一 Focusory 账户时，返回稳定冲突。系统不根据邮箱或昵称自动合并账户。

## 任务接口

- `GET /v1/tasks`：查询任务，可按 `active/completed/abandoned` 过滤。
- `POST /v1/tasks`：创建 `todo` 或 `ongoing` 任务。
- `PATCH /v1/tasks/{id}`：修改原型允许的字段；不允许修改 `mode`。
- `POST /v1/tasks/{id}/complete`：手动最终完成任务。
- `POST /v1/tasks/{id}/abandon`：放弃有历史记录的进行中任务。
- `DELETE /v1/tasks/{id}`：删除无历史记录的进行中任务。
- `POST /v1/tasks/{id}/todo-target-appends`：对系统达标的待办任务增加正整数目标。
- `POST /v1/tasks/{id}/daily-target-appends`：对今日已达标的持续任务增加当日正整数目标，不修改未来日期。

任务 DTO 使用：

- `mode: todo | ongoing`。
- `status: active | completed | abandoned`。
- 待办字段：`todo_target`。
- 持续字段：`has_date_range`、`has_daily_target`、`start_date`、`end_date`、`daily_target`。

## 会话与统计接口

- `GET /v1/sessions`：按日期或任务查询已完成会话。
- `POST /v1/sessions`：提交已在本地完成的会话及其任务/每日进度结果。
- `GET /v1/statistics/today?local_date=...&time_zone_id=...`：获取今日会话数、专注总时长和明细。

会话提交必须包含：`id`、`task_id`、`task_name_snapshot`、`started_at`、`ended_at`、`planned_duration_seconds`、`focus_duration_seconds`、`local_date` 和 `time_zone_id`。

## 同步接口

- `POST /v1/sync/push`：批量提交幂等变更，返回每个操作的成功或稳定错误。
- `GET /v1/sync/pull?cursor=...`：拉取当前账户在游标之后的服务端变更和新游标。

客户端必须先保存本地数据再调用同步接口；一次推送失败不得删除本地变更。

## 业务错误码

- `invalid_task_mode`
- `invalid_task_configuration`
- `task_not_active`
- `task_has_history`
- `task_has_no_history`
- `task_in_use`
- `todo_target_cannot_decrease`
- `todo_append_not_allowed`
- `daily_append_not_allowed`
- `date_range_invalid`
- `operation_conflict`
- `authentication_required`
- `provider_authentication_failed`
- `identity_already_bound`
- `identity_bound_to_another_account`
- `identity_not_bound`
- `last_identity_cannot_unbind`
