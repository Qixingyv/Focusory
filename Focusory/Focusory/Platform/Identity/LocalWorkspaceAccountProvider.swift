import Foundation

/// P0 的本机工作空间账户；F05 接入登录态后由当前会话提供账户标识。
struct LocalWorkspaceAccountProvider: CurrentAccountProvider {
    /// 固定的本机工作空间标识，保证重启后数据仍解析到同一账户。
    static let localWorkspaceAccountID = AccountID(
        rawValue: UUID(uuidString: "F0C05000-0000-4000-8000-000000000001") ?? UUID()
    )

    /// 向业务用例提供本机工作空间账户，统一数据访问范围。
    var currentAccountID: AccountID { Self.localWorkspaceAccountID }
}
