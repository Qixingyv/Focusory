import Foundation
import Testing
@testable import Focusory

/// 执行可能抛错的操作并返回任务失败结果；未按预期抛出时记录问题。
@MainActor
func captureTaskFailure(_ operation: () throws -> Void) -> TaskFailure {
    do {
        try operation()
        Issue.record("预期抛出 TaskFailure，但操作成功")
        return TaskFailure(.persistenceFailed)
    } catch let failure as TaskFailure {
        return failure
    } catch {
        Issue.record("预期抛出 TaskFailure，实际抛出 \(error)")
        return TaskFailure(.persistenceFailed)
    }
}
