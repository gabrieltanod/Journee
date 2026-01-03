import SwiftUI

@main
struct JourneeApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                JournalView()
                    .tabItem {
                        Label("Journal", systemImage: "pencil")
                    }
                
                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "clock")
                    }
            }
        }
    }
}
