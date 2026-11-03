import Foundation
import SwiftData

/// SwiftData 任务实体；枚举以稳定原始值保存，本机日期以 `yyyy-MM-dd` 键保存。
@Model
final class FocusTaskRecord {
    /// 保证任务标识唯一。
    #Unique<FocusTaskRecord>([\.id])

    /// 任务标识。
    var id: UUID = UUID()
    /// 数据所属的账户，用于限定查询和写入范围。
    var ownerID: UUID = UUID()
    /// 任务名。
    var name: String = ""
    /// 以字符串保存任务模式，读取时转换回领域枚举。
    var modeRawValue: String = FocusTaskMode.todo.rawValue
    /// 以字符串保存任务状态，供存储查询和领域还原使用。
    var statusRawValue: String = FocusTaskStatus.active.rawValue
    /// 以字符串保存完成来源；未记录时为空。
    var completionSourceRawValue: String?
    /// 每轮计划专注时长，单位为分钟。
    var focusDurationMinutes: Int = 25
    /// 每轮计划休息时长，单位为分钟。
    var breakDurationMinutes: Int = 5
    /// 待办总目标。
    var todoTarget: Int?
    /// 是否启用计划周期。
    var hasDateRange: Bool = false
    /// 以日期键保存计划开始日，不附带具体时刻。
    var startDateKey: String?
    /// 以日期键保存计划截止日，不附带具体时刻。
    var endDateKey: String?
    /// 是否启用每日目标。
    var hasDailyTarget: Bool = false
    /// 每天计划完成的番茄数，不含当日追加。
    var dailyTarget: Int?
    /// 创建时刻。
    var createdAt: Date = Date()
    /// 最近修改时刻。
    var updatedAt: Date = Date()
    /// 手动最终完成的时刻，用于已完成列表排序。
    var completedAt: Date?
    /// 放弃任务的时刻，用于已放弃列表排序。
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
    /// 供仓储读取的任务对象；模式或状态无法识别时返回 nil。
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
