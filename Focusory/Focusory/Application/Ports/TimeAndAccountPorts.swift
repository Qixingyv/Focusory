import Foundation

/// 当前瞬时契约；界面刷新频率不改变业务上的时间真值。
protocol Clock {
    /// 当前时刻，供业务计算时间使用。
    var now: Date { get }
}

/// 本机日历契约；负责把瞬时归属到一个用户本机日期。
protocol CalendarProvider {
    /// 本机时区，用于确定业务数据归属哪一天。
    var timeZoneID: TimeZoneID { get }
    /// 把瞬时按本机时区换算为本机日期。
    func localDate(for instant: Date) -> LocalDate
}

/// 当前账户契约；提供受信任的账户标识，界面不得自行指定其他账户。
protocol CurrentAccountProvider {
    /// 当前账户标识。
    var currentAccountID: AccountID { get }
}
