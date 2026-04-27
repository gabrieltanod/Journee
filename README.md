# Journee

Journee is a beautiful, offline-only personal finance and budgeting app built with Swift, SwiftUI, and SwiftData. Designed with a focus on simplicity, speed, and privacy, Journee helps you track your expenses, manage your income, and stay on top of your budgeting cycles without relying on external servers.

## Features

### 📊 Dashboard & Budget Tracking
Get a clear, at-a-glance view of your financial health. The main dashboard displays your remaining budget and overall progress for the current budgeting cycle.

![Dashboard Screenshot Placeholder](docs/screenshots/dashboard_placeholder.png)
*(Replace with path to an actual screenshot of the Dashboard)*

### 📅 Calendar Grid View
Visualize your spending habits over time. The interactive calendar view shows daily spending totals, making it easy to identify high-expense days.

![Calendar Screenshot Placeholder](docs/screenshots/calendar_placeholder.png)
*(Replace with path to an actual screenshot of the Calendar)*

### ⚡️ Quick-Add Transactions
Logging an expense should be frictionless. Journee features a streamlined quick-add sheet. Plus, you can trigger it instantly using Lock Screen or Control Center shortcuts powered by App Intents.

![Quick Add Screenshot Placeholder](docs/screenshots/quick_add_placeholder.png)
*(Replace with path to an actual screenshot of the Quick Add sheet)*

### 🗂️ Two-Tier Category System
Organize your expenses exactly how you want. 
- Create custom **Head Categories** and **Sub-categories**.
- Quickly access your **'Most Frequent'** categories when logging transactions.
- Easily manage categories with native swipe-to-delete gestures.

![Categories Screenshot Placeholder](docs/screenshots/categories_placeholder.png)
*(Replace with path to an actual screenshot of the Category Management/Selection)*

### 🔄 Payday Cycles & Income Tracking
Budgets shouldn't be rigidly tied to calendar months if you don't want them to be. 
- Set custom payday cycles.
- Track both expenses and income.
- Prompt for setting budgets at the start of each cycle.

![Settings Screenshot Placeholder](docs/screenshots/settings_placeholder.png)
*(Replace with path to an actual screenshot of the Settings/Payday configuration)*

### 📈 Detailed Insights
Dive deeper into your spending habits.
- View breakdowns of expenses per category for a selected period.
- Navigate into specific categories to see individual transactions.
- Tap-to-edit or swipe-to-delete past expenses easily.

![Insights Screenshot Placeholder](docs/screenshots/insights_placeholder.png)
*(Replace with path to an actual screenshot of the Insights View)*

### 🔔 Daily Reminders
Stay consistent with local daily notifications reminding you to log your transactions.

## Architecture & Tech Stack

- **Frameworks:** SwiftUI, SwiftData, App Intents, UserNotifications
- **Architecture:** MVVM (Model-View-ViewModel)
- **Data Privacy:** 100% Offline-only. Your financial data never leaves your device.

## Getting Started

1. Clone the repository.
2. Open `Journee.xcodeproj` in Xcode.
3. Build and run on an iOS simulator or a physical device.

---
*Note: To add real screenshots, take screenshots of your app running, save them (e.g., in a `docs/screenshots` folder), and update the placeholder image paths in this README.*
