import Foundation

/// 向业务提供系统当前时刻，避免用界面刷新次数推算时间。
struct SystemClock: Clock {
    /// 当前时刻，供业务计算时间使用。
    var now: Date { Date() }
}

/// 系统日历适配；把瞬时归属到用户当前本机时区下的日期。
struct SystemCalendarProvider: CalendarProvider {
    /// 本机时区，用于确定业务数据归属哪一天。
    var timeZoneID: TimeZoneID {
        TimeZoneID(TimeZone.current)
    }

    /// 把瞬时按当前本机时区换算为本机日期。
    func localDate(for instant: Date) -> LocalDate {
        LocalDate.containing(instant, in: TimeZone.current)
    }
}
