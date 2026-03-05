import SwiftUI
import SwiftData

@main
struct JourneeApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView()
        }
        .modelContainer(for: [
            Expense.self,
            Category.self,
            MonthlyBudget.self,
        ])
    }
}
