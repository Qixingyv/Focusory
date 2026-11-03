import Foundation

/// IANA 时区标识；用于把瞬时换算为用户本机日期。
struct TimeZoneID: Hashable, Sendable {
    /// 时区名称，如 `Asia/Shanghai`，供保存和日期换算使用。
    let identifier: String

    /// 接受可解析的 IANA 标识，否则返回 nil。
    init?(_ identifier: String) {
        guard TimeZone(identifier: identifier) != nil else { return nil }
        self.identifier = identifier
    }

    /// 从系统时区取得标识。
    init(_ timeZone: TimeZone) {
        identifier = timeZone.identifier
    }

    /// 该标识对应的时区；标识失效时退回 GMT，避免读取历史快照时崩溃。
    var timeZone: TimeZone {
        TimeZone(identifier: identifier) ?? TimeZone(secondsFromGMT: 0) ?? .gmt
    }
}

/// 用户本机日历中的某一天；不带时刻，必须与时区标识成对使用。
struct LocalDate: Hashable, Comparable, Sendable {
    /// 公历年份。
    let year: Int
    /// 公历月份。
    let month: Int
    /// 公历月中的日期。
    let day: Int

    /// 创建本机日期；字段越界或该日不存在时返回 nil。
    init?(year: Int, month: Int, day: Int) {
        guard (1...9999).contains(year), (1...12).contains(month), (1...31).contains(day) else {
            return nil
        }

        var utcCalendar = Calendar(identifier: .gregorian)
        guard let utcTimeZone = TimeZone(secondsFromGMT: 0) else { return nil }
        utcCalendar.timeZone = utcTimeZone

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        guard let resolved = utcCalendar.date(from: components) else { return nil }

        let roundTrip = utcCalendar.dateComponents([.year, .month, .day], from: resolved)
        guard roundTrip.year == year, roundTrip.month == month, roundTrip.day == day else {
            return nil
        }

        self.year = year
        self.month = month
        self.day = day
    }

    /// 把瞬时按给定时区换算为本机日期。
    static func containing(_ instant: Date, in timeZone: TimeZone) -> LocalDate {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: instant)
        // 公历换算必然产生合法字段，兜底值只用于满足非可选返回。
        return LocalDate(
            year: components.year ?? 1970,
            month: components.month ?? 1,
            day: components.day ?? 1
        ) ?? LocalDate(year: 1970, month: 1, day: 1)!
    }

    /// 返回该日在该时区的零点时刻，供日期选择器和展示换算使用。
    func startInstant(in timeZone: TimeZone) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return calendar.date(from: components)
    }

    /// 按年、月、日顺序比较。
    static func < (lhs: LocalDate, rhs: LocalDate) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    /// 持久化使用的规范化日期键，格式 `yyyy-MM-dd`。
    var key: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    /// 解析 `yyyy-MM-dd` 日期键；格式或日期不合法时返回 nil。
    init?(key: String) {
        let parts = key.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]) else {
            return nil
        }
        self.init(year: year, month: month, day: day)
    }
}
