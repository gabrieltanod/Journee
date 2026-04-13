import AppIntents
import SwiftUI
import WidgetKit

/// Lock Screen / Control Center button that opens Journee straight into Quick Add.
struct JourneeWidgetsControl: ControlWidget {
    static let kind: String = "GabrielTanod.Journee.QuickAdd"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: QuickAddIntent()) {
                Label("Quick Add", systemImage: "plus.circle.fill")
            }
        }
        .displayName("Quick Add Expense")
        .description("Instantly open Journee to add a new entry.")
    }
}
