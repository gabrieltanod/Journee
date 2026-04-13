import AppIntents

/// App Intent that opens the app directly to the Quick Add sheet.
/// Exposed to Shortcuts, Siri, and the Lock Screen / Control Center widget.
struct QuickAddIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Add Expense"
    static var description: IntentDescription = IntentDescription("Open Journee and add a new expense or income entry.")

    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        // Use UserDefaults so this works from both the main app and widget extension processes
        UserDefaults.standard.set(true, forKey: "shouldShowQuickAdd")
        // Also set in-memory if running inside the main app process
        await MainActor.run {
            AppState.shared.shouldShowQuickAdd = true
        }
        return .result()
    }
}

/// Provides the App Shortcut so it appears in Spotlight and Siri suggestions.
struct JourneeShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: QuickAddIntent(),
            phrases: [
                "Add expense in \(.applicationName)",
                "Quick add in \(.applicationName)",
                "Log expense in \(.applicationName)"
            ],
            shortTitle: "Quick Add",
            systemImageName: "plus.circle.fill"
        )
    }
}
