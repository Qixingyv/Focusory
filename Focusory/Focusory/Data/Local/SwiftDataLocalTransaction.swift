import Foundation
import SwiftData

/// SwiftData 本地事务适配；闭包内的写入在结束时一次提交，失败时整体回滚。
final class SwiftDataLocalTransaction: LocalTransaction {
    /// 与仓储共用的上下文，统一提交或回滚仓储暂存的写入。
    private let context: ModelContext

    /// 用指定上下文创建事务执行器。
    init(context: ModelContext) {
        self.context = context
    }

    /// 在同一个本地事务中执行写入并提交。
    /// - 失败：闭包抛错或提交失败时回滚已暂存的全部写入，并抛出原始错误。
    func perform<T>(_ work: () throws -> T) throws -> T {
        do {
            let result = try work()
            if context.hasChanges {
                try context.save()
            }
            return result
        } catch {
            context.rollback()
            throw error
        }
    }
}
