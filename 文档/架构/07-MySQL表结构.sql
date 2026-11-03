-- Focusory MySQL 9.7 LTS 参考表结构
--
-- 用途：作为首个 Alembic 迁移的数据库契约，不代替 Alembic 迁移文件。
-- 业务语义与结构说明：文档/架构/06-数据模型.md
-- 字段名、中文名与 MySQL 类型：06-数据模型.md 各实体的「字段与 MySQL 类型」表；
-- 本文件是列类型、默认值、生成列、检查约束、外键和索引的真值源。
-- 使用前提：
--   1. 连接会话时区固定为 UTC。
--   2. 数据库默认字符集为 utf8mb4。
--   3. UUID 由创建端生成，持久化为小写带连字符的 CHAR(36)。
--   4. 应用启动时不得使用 ORM create_all() 替代迁移。

CREATE TABLE user_accounts (
    id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    display_name VARCHAR(100) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    last_login_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),

    CONSTRAINT pk_user_accounts PRIMARY KEY (id)
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = 'Focusory 云端数据所有者';

CREATE TABLE account_identities (
    id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    user_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    provider VARCHAR(16) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    provider_user_id VARCHAR(255) COLLATE utf8mb4_bin NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    last_authenticated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),

    CONSTRAINT pk_account_identities PRIMARY KEY (id),
    CONSTRAINT uq_account_identities_provider_subject
        UNIQUE (provider, provider_user_id),
    CONSTRAINT uq_account_identities_user_provider
        UNIQUE (user_id, provider),
    CONSTRAINT fk_account_identities_user
        FOREIGN KEY (user_id) REFERENCES user_accounts (id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT chk_account_identities_provider
        CHECK (provider IN ('apple', 'wechat'))
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '用户可同时绑定的 Apple 与微信第三方身份';

CREATE TABLE focus_tasks (
    id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    user_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    name VARCHAR(255) NOT NULL,
    mode VARCHAR(16) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    status VARCHAR(16) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'active',
    completion_source VARCHAR(16) CHARACTER SET ascii COLLATE ascii_bin NULL,

    focus_duration_seconds INT UNSIGNED NOT NULL DEFAULT 1500,
    break_duration_seconds INT UNSIGNED NOT NULL DEFAULT 300,

    todo_target INT UNSIGNED NULL,

    has_date_range TINYINT UNSIGNED NOT NULL DEFAULT 0,
    start_date DATE NULL,
    end_date DATE NULL,
    has_daily_target TINYINT UNSIGNED NOT NULL DEFAULT 0,
    daily_target INT UNSIGNED NULL,

    completed_at DATETIME(6) NULL,
    abandoned_at DATETIME(6) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
        ON UPDATE CURRENT_TIMESTAMP(6),
    version BIGINT UNSIGNED NOT NULL DEFAULT 1,

    CONSTRAINT pk_focus_tasks PRIMARY KEY (id),
    CONSTRAINT uq_focus_tasks_id_user UNIQUE (id, user_id),
    CONSTRAINT fk_focus_tasks_user
        FOREIGN KEY (user_id) REFERENCES user_accounts (id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,

    CONSTRAINT chk_focus_tasks_name
        CHECK (CHAR_LENGTH(TRIM(name)) BETWEEN 1 AND 255),
    CONSTRAINT chk_focus_tasks_mode
        CHECK (mode IN ('todo', 'ongoing')),
    CONSTRAINT chk_focus_tasks_status
        CHECK (status IN ('active', 'completed', 'abandoned')),
    CONSTRAINT chk_focus_tasks_completion_source
        CHECK (completion_source IS NULL OR completion_source IN ('auto', 'manual')),
    CONSTRAINT chk_focus_tasks_focus_duration
        CHECK (
            focus_duration_seconds BETWEEN 300 AND 7200
            AND MOD(focus_duration_seconds, 300) = 0
        ),
    CONSTRAINT chk_focus_tasks_break_duration
        CHECK (break_duration_seconds BETWEEN 60 AND 3600),
    CONSTRAINT chk_focus_tasks_version
        CHECK (version >= 1),

    CONSTRAINT chk_focus_tasks_mode_configuration
        CHECK (
            (
                mode = 'todo'
                AND todo_target IS NOT NULL
                AND todo_target >= 1
                AND has_date_range = 0
                AND start_date IS NULL
                AND end_date IS NULL
                AND has_daily_target = 0
                AND daily_target IS NULL
            )
            OR
            (
                mode = 'ongoing'
                AND todo_target IS NULL
                AND has_date_range IN (0, 1)
                AND has_daily_target IN (0, 1)
                AND (
                    (has_date_range = 0 AND start_date IS NULL AND end_date IS NULL)
                    OR
                    (
                        has_date_range = 1
                        AND start_date IS NOT NULL
                        AND end_date IS NOT NULL
                        AND end_date >= start_date
                    )
                )
                AND (
                    (has_daily_target = 0 AND daily_target IS NULL)
                    OR (
                        has_daily_target = 1
                        AND daily_target IS NOT NULL
                        AND daily_target >= 1
                    )
                )
            )
        ),
    CONSTRAINT chk_focus_tasks_lifecycle
        CHECK (
            (
                status = 'active'
                AND completed_at IS NULL
                AND abandoned_at IS NULL
                AND (
                    completion_source IS NULL
                    OR (mode = 'todo' AND completion_source = 'auto')
                )
            )
            OR
            (
                status = 'completed'
                AND completion_source IS NOT NULL
                AND completion_source = 'manual'
                AND completed_at IS NOT NULL
                AND abandoned_at IS NULL
            )
            OR
            (
                status = 'abandoned'
                AND completion_source IS NULL
                AND completed_at IS NULL
                AND abandoned_at IS NOT NULL
            )
        ),

    INDEX idx_focus_tasks_user_status_updated (user_id, status, updated_at),
    INDEX idx_focus_tasks_user_mode (user_id, mode)
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '待办与持续任务，使用单表互斥配置';

CREATE TABLE task_daily_progress (
    id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    user_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    task_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    local_date DATE NOT NULL,
    time_zone_id VARCHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,

    target_snapshot INT UNSIGNED NOT NULL,
    added_target_count INT UNSIGNED NOT NULL DEFAULT 0,
    completed_pomodoro_count INT UNSIGNED NOT NULL DEFAULT 0,
    focus_duration_seconds BIGINT UNSIGNED NOT NULL DEFAULT 0,

    effective_target INT UNSIGNED
        GENERATED ALWAYS AS (target_snapshot + added_target_count) STORED,
    is_met TINYINT(1)
        GENERATED ALWAYS AS (
            completed_pomodoro_count >= target_snapshot + added_target_count
        ) STORED,

    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
        ON UPDATE CURRENT_TIMESTAMP(6),
    version BIGINT UNSIGNED NOT NULL DEFAULT 1,

    CONSTRAINT pk_task_daily_progress PRIMARY KEY (id),
    CONSTRAINT uq_task_daily_progress_task_date UNIQUE (task_id, local_date),
    CONSTRAINT fk_task_daily_progress_task_owner
        FOREIGN KEY (task_id, user_id) REFERENCES focus_tasks (id, user_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT chk_task_daily_progress_timezone
        CHECK (CHAR_LENGTH(TRIM(time_zone_id)) BETWEEN 1 AND 64),
    CONSTRAINT chk_task_daily_progress_target
        CHECK (target_snapshot >= 1),
    CONSTRAINT chk_task_daily_progress_version
        CHECK (version >= 1),

    INDEX idx_task_daily_progress_user_date (user_id, local_date),
    INDEX idx_task_daily_progress_user_updated (user_id, updated_at)
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '持续任务的每日目标快照与进度';

CREATE TABLE focus_sessions (
    id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    user_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    task_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    task_name_snapshot VARCHAR(255) NOT NULL,

    started_at DATETIME(6) NOT NULL,
    ended_at DATETIME(6) NOT NULL,
    planned_duration_seconds INT UNSIGNED NOT NULL,
    focus_duration_seconds INT UNSIGNED NOT NULL,
    local_date DATE NOT NULL,
    time_zone_id VARCHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,

    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    version BIGINT UNSIGNED NOT NULL DEFAULT 1,

    CONSTRAINT pk_focus_sessions PRIMARY KEY (id),
    CONSTRAINT fk_focus_sessions_task_owner
        FOREIGN KEY (task_id, user_id) REFERENCES focus_tasks (id, user_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT chk_focus_sessions_task_name
        CHECK (CHAR_LENGTH(TRIM(task_name_snapshot)) BETWEEN 1 AND 255),
    CONSTRAINT chk_focus_sessions_time_order
        CHECK (ended_at >= started_at),
    CONSTRAINT chk_focus_sessions_planned_duration
        CHECK (
            planned_duration_seconds BETWEEN 300 AND 7200
            AND MOD(planned_duration_seconds, 300) = 0
        ),
    CONSTRAINT chk_focus_sessions_focus_duration
        CHECK (focus_duration_seconds > 0),
    CONSTRAINT chk_focus_sessions_timezone
        CHECK (CHAR_LENGTH(TRIM(time_zone_id)) BETWEEN 1 AND 64),
    CONSTRAINT chk_focus_sessions_version
        CHECK (version >= 1),

    INDEX idx_focus_sessions_user_local_date_ended
        (user_id, local_date, ended_at DESC),
    INDEX idx_focus_sessions_task_ended (task_id, ended_at DESC)
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '不可变的已完成专注会话事实';

CREATE TABLE processed_operations (
    operation_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    user_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    operation_type VARCHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    request_hash BINARY(32) NOT NULL,
    outcome VARCHAR(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    http_status SMALLINT UNSIGNED NOT NULL,
    result_payload JSON NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),

    CONSTRAINT pk_processed_operations PRIMARY KEY (operation_id),
    CONSTRAINT fk_processed_operations_user
        FOREIGN KEY (user_id) REFERENCES user_accounts (id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT chk_processed_operations_type
        CHECK (CHAR_LENGTH(TRIM(operation_type)) BETWEEN 1 AND 64),
    CONSTRAINT chk_processed_operations_outcome
        CHECK (outcome IN ('success', 'business_error')),
    CONSTRAINT chk_processed_operations_http_status
        CHECK (http_status BETWEEN 200 AND 499),

    INDEX idx_processed_operations_user_created (user_id, created_at)
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '已终结幂等操作及可重放的稳定结果';

CREATE TABLE server_changes (
    cursor BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    entity_type VARCHAR(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    entity_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    operation_type VARCHAR(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    entity_version BIGINT UNSIGNED NOT NULL,
    payload JSON NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),

    CONSTRAINT pk_server_changes PRIMARY KEY (cursor),
    CONSTRAINT fk_server_changes_user
        FOREIGN KEY (user_id) REFERENCES user_accounts (id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT chk_server_changes_entity_type
        CHECK (CHAR_LENGTH(TRIM(entity_type)) BETWEEN 1 AND 32),
    CONSTRAINT chk_server_changes_operation_type
        CHECK (operation_type IN ('create', 'update', 'delete')),
    CONSTRAINT chk_server_changes_entity_version
        CHECK (entity_version >= 1),

    INDEX idx_server_changes_user_cursor (user_id, cursor),
    INDEX idx_server_changes_entity (user_id, entity_type, entity_id, cursor)
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '按全局递增游标拉取的用户增量变更';

-- 由 Alembic 在实际迁移中管理 alembic_version 表。
-- 不建表的概念：
--   * TodayStatistics：从 focus_sessions 查询推导。
--   * ActiveTimerSnapshot：仅保存在 macOS 客户端。
--   * SyncQueueItem：仅保存在 macOS 客户端。
--   * 登录会话/刷新令牌：等登录态形式和刷新策略决策后再建表。
--   * 微信扫码会话：等超时、重试和持久化方式决策后再建表。
--
-- 无法仅用单表 CHECK 表达的账户绑定规则：
--   * 创建账户时，user_accounts 和首个 account_identities 必须在同一事务中提交。
--   * 解绑前必须锁定当前账户的身份集合，不得删除最后一个登录身份。
