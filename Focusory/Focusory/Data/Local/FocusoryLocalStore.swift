import Foundation
import SwiftData

/// 本地持久化 schema 与容器工厂。
enum FocusoryLocalStore {
    /// 当前 schema 包含的实体。
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
