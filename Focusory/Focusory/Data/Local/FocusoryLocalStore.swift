import Foundation
import SwiftData

/// 定义本地保存的数据类型，并创建存储容器和事务上下文。
enum FocusoryLocalStore {
    /// 本地数据库要保存的模型类型，供创建容器时注册。
    static let models: [any PersistentModel.Type] = [
        FocusTaskRecord.self,
        TaskDailyProgressRecord.self,
        FocusSessionRecord.self,
        SyncQueueItemRecord.self
    ]

    /// 创建本地容器。
    /// - Parameter isStoredInMemoryOnly: 测试与预览使用内存存储，不触碰开发者真实数据。
    static func makeContainer(isStoredInMemoryOnly: Bool = false) throws -> ModelContainer {
        let schema = Schema(models)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isStoredInMemoryOnly)
        return try ModelContainer(for: schema, configurations: configuration)
    }

    /// 创建关闭自动保存的上下文；写入只由 `SwiftDataLocalTransaction` 统一提交。
    static func makeTransactionContext(in container: ModelContainer) -> ModelContext {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return context
    }
}
