import Foundation
import SwiftUI

/// Lightweight global routing state for deep-link and shortcut triggers.
@Observable
final class AppState {
    static let shared = AppState()

    var shouldShowQuickAdd: Bool = false

    private init() {}

    /// Check UserDefaults for a pending Quick Add flag (set by widget extension or notification).
    /// Call this when the app becomes active.
    func checkPendingQuickAdd() {
        if UserDefaults.standard.bool(forKey: "shouldShowQuickAdd") {
            UserDefaults.standard.set(false, forKey: "shouldShowQuickAdd")
            shouldShowQuickAdd = true
        }
    }
}
