import Foundation
import SwiftData

/// SwiftData 任务实体；枚举以稳定原始值保存，本机日期以 `yyyy-MM-dd` 键保存。
@Model
final class FocusTaskRecord {
    /// 保证任务标识唯一。
    #Unique<FocusTaskRecord>([\.id])

    /// 任务标识。
    var id: UUID = UUID()
    /// 所属账户标识。
    var ownerID: UUID = UUID()
    /// 任务名。
    var name: String = ""
    /// 任务模式原始值。
    var modeRawValue: String = FocusTaskMode.todo.rawValue
    /// 整体状态原始值。
    var statusRawValue: String = FocusTaskStatus.active.rawValue
    /// 完成来源原始值。
    var completionSourceRawValue: String?
    /// 计划专注分钟数。
    var focusDurationMinutes: Int = 25
    /// 计划休息分钟数。
    var breakDurationMinutes: Int = 5
    /// 待办总目标。
    var todoTarget: Int?
    /// 是否启用计划周期。
    var hasDateRange: Bool = false
    /// 计划开始日本机日期键。
    var startDateKey: String?
    /// 计划截止日本机日期键。
    var endDateKey: String?
    /// 是否启用每日目标。
    var hasDailyTarget: Bool = false
    /// 每日基础目标。
    var dailyTarget: Int?
    /// 创建瞬时。
    var createdAt: Date = Date()
    /// 最近更新瞬时。
    var updatedAt: Date = Date()
    /// 手动完成瞬时。
    var completedAt: Date?
    /// 放弃瞬时。
    var abandonedAt: Date?
    /// 服务端版本号。
    var version: Int = 1

    /// 以领域对象创建实体。
    init(task: FocusTask) {
        apply(task)
    }

    /// 用领域对象覆盖实体全部字段。
    func apply(_ task: FocusTask) {
        id = task.id
        ownerID = task.ownerID.rawValue
        name = task.name
        modeRawValue = task.mode.rawValue
        statusRawValue = task.status.rawValue
        completionSourceRawValue = task.completionSource?.rawValue
        focusDurationMinutes = task.focusDurationMinutes
        breakDurationMinutes = task.breakDurationMinutes
        todoTarget = task.todoTarget
        hasDateRange = task.hasDateRange
        startDateKey = task.startDate?.key
        endDateKey = task.endDate?.key
        hasDailyTarget = task.hasDailyTarget
        dailyTarget = task.dailyTarget
        createdAt = task.createdAt
        updatedAt = task.updatedAt
        completedAt = task.completedAt
        abandonedAt = task.abandonedAt
        version = task.version
    }
}

extension FocusTaskRecord {
    /// 还原为领域对象；原始值非法时返回 nil，避免把损坏数据当成有效任务。
    var domainModel: FocusTask? {
        guard let mode = FocusTaskMode(rawValue: modeRawValue),
              let status = FocusTaskStatus(rawValue: statusRawValue) else {
            return nil
        }
        let completionSource = completionSourceRawValue.flatMap(TaskCompletionSource.init(rawValue:))
        return FocusTask(
            id: id,
            ownerID: AccountID(rawValue: ownerID),
            name: name,
            mode: mode,
            status: status,
            completionSource: completionSource,
            focusDurationMinutes: focusDurationMinutes,
            breakDurationMinutes: breakDurationMinutes,
            todoTarget: todoTarget,
            hasDateRange: hasDateRange,
            startDate: startDateKey.flatMap(LocalDate.init(key:)),
            endDate: endDateKey.flatMap(LocalDate.init(key:)),
            hasDailyTarget: hasDailyTarget,
            dailyTarget: dailyTarget,
            createdAt: createdAt,
            updatedAt: updatedAt,
            completedAt: completedAt,
            abandonedAt: abandonedAt,
            version: version
        )
    }
}
