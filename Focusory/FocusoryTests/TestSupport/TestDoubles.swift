import Foundation
@testable import Focusory

/// 构造测试夹具使用的本机日期；字面量非法时立即失败。
func makeLocalDate(_ key: String) -> LocalDate {
    guard let localDate = LocalDate(key: key) else {
        preconditionFailure("测试夹具日期字面量非法：\(key)")
    }
    return localDate
}

/// 返回指定本机日期在给定时区中的零点瞬时。
func makeInstant(of localDate: LocalDate, in timeZoneID: TimeZoneID) -> Date {
    guard let instant = localDate.startInstant(in: timeZoneID.timeZone) else {
        preconditionFailure("测试夹具无法换算本机日期：\(localDate.key)")
    }
    return instant
}

/// 可控时钟；测试通过它固定当前瞬时。
@MainActor
final class FixedClock: Clock {
    /// 测试指定的当前时刻，可修改以模拟时间推进。
    var now: Date

    /// 用固定瞬时创建时钟。
    init(now: Date) {
        self.now = now
    }
}

/// 固定时区的测试日历；让跨日归属稳定可断言。
struct FixedCalendarProvider: CalendarProvider {
    /// 测试指定的时区，避免日期断言受机器设置影响。
    let timeZoneID: TimeZoneID

    /// 用给定 IANA 标识创建测试日历，无法解析时退回 GMT。
    init(timeZoneIdentifier: String = "Asia/Shanghai") {
        timeZoneID = TimeZoneID(timeZoneIdentifier) ?? TimeZoneID(TimeZone(secondsFromGMT: 0) ?? .gmt)
    }

    /// 按固定时区把瞬时换算为本机日期。
    func localDate(for instant: Date) -> LocalDate {
        LocalDate.containing(instant, in: timeZoneID.timeZone)
    }
}

/// 固定账户提供者。
struct FixedAccountProvider: CurrentAccountProvider {
    /// 测试使用的账户标识。
    let currentAccountID: AccountID
}

/// 可注入锁定状态并记录交接配置的计时桩。
@MainActor
final class StubFocusTimerService: FocusTimerService {
    /// 模拟正在运行或暂停中的任务，供验证禁止修改的操作。
    var lockedTaskIDs: Set<UUID> = []
    /// 测试预设的启动结果，用于模拟成功或拒绝。
    var startOutcome: StartFocusOutcome = .started
    /// 按调用顺序记录收到的专注配置，供测试检查交接内容。
    private(set) var handedOffConfigurations: [TaskRunConfiguration] = []

    /// 判断任务是否被锁定。
    func isTaskLocked(taskID: UUID) -> Bool {
        lockedTaskIDs.contains(taskID)
    }

    /// 记录交接配置并返回预设结果。
    func startFocus(configuration: TaskRunConfiguration) -> StartFocusOutcome {
        handedOffConfigurations.append(configuration)
        return startOutcome
    }
}
