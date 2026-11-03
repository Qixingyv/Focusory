import Foundation
import SwiftData

/// SwiftData 专注会话实体；会话是不可变历史事实，F01 只读取它推导任务进度。
@Model
final class FocusSessionRecord {
    /// 保证会话标识唯一。
    #Unique<FocusSessionRecord>([\.id])

    /// 会话标识。
    var id: UUID = UUID()
    /// 数据所属的账户，用于限定查询和写入范围。
    var ownerID: UUID = UUID()
    /// 关联任务标识。
    var taskID: UUID = UUID()
    /// 会话完成时的任务名，保留历史名称以免被后续改名覆盖。
    var taskNameSnapshot: String = ""
    /// 本轮专注开始的时刻。
    var startedAt: Date = Date()
    /// 本轮专注结束的时刻，用于确定会话归属日期。
    var endedAt: Date = Date()
    /// 本轮计划专注秒数。
    var plannedDurationSeconds: Int = 0
    /// 排除暂停后的实际专注秒数。
    var focusDurationSeconds: Int = 0
    /// 会话归属的本机日期键。
    var localDateKey: String = ""
    /// 会话归属日期使用的时区，供还原当时的日期判断。
    var timeZoneIdentifier: String = "GMT"
    /// 创建时刻。
    var createdAt: Date = Date()
    /// 服务端版本号。
    var version: Int = 1

    /// 以完整会话事实创建实体；会话创建属于 F02，F01 只读取已保存会话。
    init(
        id: UUID = UUID(),
        ownerID: UUID,
        taskID: UUID,
        taskNameSnapshot: String,
        startedAt: Date,
        endedAt: Date,
        plannedDurationSeconds: Int,
        focusDurationSeconds: Int,
        localDateKey: String,
        timeZoneIdentifier: String,
        createdAt: Date,
        version: Int = 1
    ) {
        self.id = id
        self.ownerID = ownerID
        self.taskID = taskID
        self.taskNameSnapshot = taskNameSnapshot
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.plannedDurationSeconds = plannedDurationSeconds
        self.focusDurationSeconds = focusDurationSeconds
        self.localDateKey = localDateKey
        self.timeZoneIdentifier = timeZoneIdentifier
        self.createdAt = createdAt
        self.version = version
    }
}
