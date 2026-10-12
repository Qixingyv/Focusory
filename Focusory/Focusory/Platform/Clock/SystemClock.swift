import Foundation

/// 系统时钟适配；业务时间真值来自系统瞬时而不是界面刷新次数。
struct SystemClock: Clock {
    /// 当前瞬时。
    var now: Date { Date() }
}

/// 系统日历适配；把瞬时归属到用户当前本机时区下的日期。
struct SystemCalendarProvider: CalendarProvider {
    /// 当前本机时区。
    var timeZoneID: TimeZoneID {
        TimeZoneID(TimeZone.current)
    }

    /// 把瞬时按当前本机时区换算为本机日期。
    func localDate(for instant: Date) -> LocalDate {
        LocalDate.containing(instant, in: TimeZone.current)
    }
}
