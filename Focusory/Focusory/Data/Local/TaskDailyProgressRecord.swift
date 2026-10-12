import Foundation
import SwiftData

/// SwiftData 每日进度实体；同一任务与本机日期唯一。
@Model
final class TaskDailyProgressRecord {
    /// 保证「任务 + 本机日期」唯一。
    #Unique<TaskDailyProgressRecord>([\.taskID, \.localDateKey])

    /// 每日进度标识。
    var id: UUID = UUID()
    /// 所属账户标识。
    var ownerID: UUID = UUID()
    /// 关联任务标识。
    var taskID: UUID = UUID()
    /// 归属的本机日期键。
    var localDateKey: String = ""
    /// 建立快照时的 IANA 时区标识。
    var timeZoneIdentifier: String = "GMT"
    /// 当日目标快照。
    var targetSnapshot: Int = 1
    /// 当日追加数量。
    var addedTargetCount: Int = 0
    /// 当日完成番茄数。
    var completedPomodoroCount: Int = 0
    /// 当日实际专注秒数。
    var focusDurationSeconds: Int = 0
    /// 创建瞬时。
    var createdAt: Date = Date()
    /// 最近更新瞬时。
    var updatedAt: Date = Date()
    /// 服务端版本号。
    var version: Int = 1

    /// 以领域对象创建实体。
    init(progress: TaskDailyProgress) {
        apply(progress)
    }

    /// 用领域对象覆盖实体全部字段。
    func apply(_ progress: TaskDailyProgress) {
        id = progress.id
        ownerID = progress.ownerID.rawValue
        taskID = progress.taskID
        localDateKey = progress.localDate.key
        timeZoneIdentifier = progress.timeZoneID.identifier
        targetSnapshot = progress.targetSnapshot
        addedTargetCount = progress.addedTargetCount
        completedPomodoroCount = progress.completedPomodoroCount
        focusDurationSeconds = progress.focusDurationSeconds
        createdAt = progress.createdAt
        updatedAt = progress.updatedAt
        version = progress.version
    }
}

extension TaskDailyProgressRecord {
    /// 还原为领域对象；日期键或时区非法时返回 nil。
    var domainModel: TaskDailyProgress? {
        guard let localDate = LocalDate(key: localDateKey),
              let timeZoneID = TimeZoneID(timeZoneIdentifier) else {
            return nil
        }
        return TaskDailyProgress(
            id: id,
            ownerID: AccountID(rawValue: ownerID),
            taskID: taskID,
            localDate: localDate,
            timeZoneID: timeZoneID,
            targetSnapshot: targetSnapshot,
            addedTargetCount: addedTargetCount,
            completedPomodoroCount: completedPomodoroCount,
            focusDurationSeconds: focusDurationSeconds,
            createdAt: createdAt,
            updatedAt: updatedAt,
            version: version
        )
    }
}
