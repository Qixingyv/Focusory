import Foundation

/// 业务数据的所有者标识；所有查询与写入都必须按它限定范围。
struct AccountID: Hashable, Sendable {
    /// 账户标识原文。
    let rawValue: UUID

    /// 包装一个账户标识。
    init(rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}
