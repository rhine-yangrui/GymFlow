import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum FeedbackEngine {
    @MainActor
    static func impact() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    @MainActor
    static func success() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
}
