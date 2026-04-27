import SwiftUI
import SwiftData
import UserNotifications

@main
struct JourneeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [
            Expense.self,
            Category.self,
            MonthlyBudget.self,
            HeadCategory.self,
        ])
    }
}

// MARK: - Root View (routing layer)

struct RootView: View {
    @State private var appState = AppState.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
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
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // Check for pending Quick Add from widget/notification
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    appState.checkPendingQuickAdd()
                }
            }
        }
    }
}

// MARK: - App Delegate (Notification Handling)

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Handle notification tap while app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // Handle notification tap — open Quick Add
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if userInfo["openQuickAdd"] as? Bool == true {
            DispatchQueue.main.async {
                AppState.shared.shouldShowQuickAdd = true
            }
        }
        completionHandler()
    }
}
