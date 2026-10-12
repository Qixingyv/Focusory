import Foundation

/// 本地原子提交契约；保证业务对象与待同步变更「全部成功或全部回滚」。
/// 仓储在事务内只暂存写入，由本契约统一提交，不得各自保存。
protocol LocalTransaction {
    /// 在同一个本地事务中执行写入并提交。
    /// - 失败：闭包抛错或提交失败时整体回滚，抛出原始错误或 `TaskFailure(.persistenceFailed)`。
    func perform<T>(_ work: () throws -> T) throws -> T
}
