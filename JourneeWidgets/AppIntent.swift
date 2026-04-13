import AppIntents

/// App Intent that opens the app directly to the Quick Add sheet.
/// Shared between the main app target and the widget extension.
struct QuickAddIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Add Expense"
    static var description: IntentDescription = IntentDescription("Open Journee and add a new expense or income entry.")

    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        // Set the routing flag via UserDefaults (shared between app and widget)
        UserDefaults.standard.set(true, forKey: "shouldShowQuickAdd")
        return .result()
    }
}
