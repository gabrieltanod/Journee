import SwiftUI
import SwiftData

@main
struct JourneeApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                DashboardView()
                    .tabItem {
                        Label("Tracker", systemImage: "list.bullet")
                    }

                InsightsView()
                    .tabItem {
                        Label("Insights", systemImage: "chart.pie.fill")
                    }

                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "list.bullet.clipboard")
                    }
            }
        }
        .modelContainer(for: [
            Expense.self,
            Category.self,
            MonthlyBudget.self,
        ])
    }
}
