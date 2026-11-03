import Foundation

/// 业务数据的所有者标识；所有查询与写入都必须按它限定范围。
struct AccountID: Hashable, Sendable {
    /// 账户对应的 UUID，供存储映射和身份比较使用。
    let rawValue: UUID

    /// 包装一个账户标识。
    init(rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}
