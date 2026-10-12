import SwiftUI

/// 在 Canvas 中演示背景与前景文字叠放的 SwiftUI 学习页面。
struct ZStackExampleView: View {
    /// 将前景文字叠放在铺满预览区域的主题色背景上。
    var body: some View {
        VStack {
                ForEach(0..<50) { index in
                    Text("第 \(index) 行")
                }
            }
    }
}

#Preview {
    ZStackExampleView()
        .frame(width: 400, height: 300)
}
