import SwiftUI
import UserNotifications

/// Local notifications only. The device keeps pantry data; no remote push server is needed.
/// Notification permission is requested from the settings screen, not on first launch.
enum PantryNotifications {
    private static let center = UNUserNotificationCenter.current()
    private static let lowStockKey = "bite.notification.lowStockAlreadySent"
    private static let lowThreshold = 2

    static func configureForegroundDelivery() {
        center.delegate = BiteNotificationDelegate.shared
    }

    static func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
    }

    static func update(pantry: [PantryItem], shopping: [ShoppingItem],
                       plan: [String: [String: [String]]]) async {
        let prefs = UserDefaults.standard
        let lowEnabled = prefs.bool(forKey: "bite.notify.lowStock")
        let expiryEnabled = prefs.bool(forKey: "bite.notify.expiry")
        let shoppingEnabled = prefs.bool(forKey: "bite.notify.shopping")
        let mealsEnabled = prefs.bool(forKey: "bite.notify.meals")
        let calendar = Calendar.current
        let now = Date()
        let outstanding = pantry.filter { $0.amount > 0 && $0.amount <= lowThreshold }
        var alerted = Set(prefs.stringArray(forKey: lowStockKey) ?? [])
        let currentlyLow = Set(outstanding.map { $0.id.uuidString })
        alerted.formIntersection(currentlyLow) // Restocking allows future notifications.

        // Pending reminders are replaced idempotently on inventory changes.
        center.removePendingNotificationRequests(withIdentifiers: ["bite.shopping.reminder", "bite.plan.reminder"])
        let lowIDs = pantry.map { "bite.low.\($0.id.uuidString)" }
        let expiryIDs = pantry.map { "bite.expiry.\($0.id.uuidString)" }
        center.removePendingNotificationRequests(withIdentifiers: lowIDs + expiryIDs)

        if lowEnabled {
            for item in outstanding where !alerted.contains(item.id.uuidString) {
                let content = UNMutableNotificationContent()
                content.title = "Running low: \(item.name)"
                content.body = "Only \(item.amount) left in your pantry. Add it to your shopping list?"
                content.sound = .default
                let req = UNNotificationRequest(identifier: "bite.low.\(item.id.uuidString)",
                                                content: content,
                                                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false))
                if (try? await center.add(req)) != nil { alerted.insert(item.id.uuidString) }
            }
        }
        prefs.set(Array(alerted), forKey: lowStockKey)

        if expiryEnabled {
            for item in pantry where item.amount > 0 {
                guard let expiry = item.expiry, expiry >= calendar.startOfDay(for: now) else { continue }
                let alertDate = calendar.date(byAdding: .day, value: -2,
                                              to: calendar.startOfDay(for: expiry)) ?? expiry
                let content = UNMutableNotificationContent()
                content.title = "Food expiring soon"
                content.body = "\(item.name) expires on \(expiry.formatted(date: .abbreviated, time: .omitted))."
                content.sound = .default
                let trigger: UNNotificationTrigger
                if alertDate <= now {
                    trigger = UNTimeIntervalNotificationTrigger(timeInterval: 8, repeats: false)
                } else {
                    let day = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: alertDate) ?? alertDate
                    trigger = UNCalendarNotificationTrigger(dateMatching: calendar.dateComponents(
                        [.year, .month, .day, .hour, .minute], from: day), repeats: false)
                }
                try? await center.add(UNNotificationRequest(identifier: "bite.expiry.\(item.id.uuidString)",
                                                             content: content, trigger: trigger))
            }
        }
        if shoppingEnabled && shopping.contains(where: { !$0.checked }) {
            let content = UNMutableNotificationContent()
            content.title = "Your shopping list is ready"
            content.body = "You have ingredients to buy for your next meals."
            content.sound = .default
            try? await center.add(UNNotificationRequest(identifier: "bite.shopping.reminder", content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 60 * 60 * 24, repeats: false)))
        }
        if mealsEnabled {
            let upcoming = plan.keys.sorted().compactMap { key -> Date? in
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd"
                return f.date(from: key)
            }.first { $0 > now && $0.timeIntervalSince(now) < 7 * 24 * 3600 }
            if let upcoming {
                let content = UNMutableNotificationContent()
                content.title = "Meal plan reminder"
                content.body = "You have meals planned for tomorrow."
                content.sound = .default
                let previous = calendar.date(byAdding: .day, value: -1, to: upcoming) ?? upcoming
                let reminder = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: previous) ?? previous
                if reminder > now {
                    try? await center.add(UNNotificationRequest(identifier: "bite.plan.reminder", content: content,
                        trigger: UNCalendarNotificationTrigger(dateMatching: calendar.dateComponents(
                            [.year, .month, .day, .hour, .minute], from: reminder), repeats: false)))
                }
            }
        }
    }
}

struct PantryNotificationsView: View {
    @EnvironmentObject private var app: AppState
    @AppStorage("bite.notify.lowStock") private var lowStock = false
    @AppStorage("bite.notify.expiry") private var expiring = false
    @AppStorage("bite.notify.shopping") private var shopping = false
    @AppStorage("bite.notify.meals") private var meals = false
    @State private var permissionDenied = false

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $lowStock) { Label("Low stock alerts", systemImage: "archivebox") }
                Toggle(isOn: $expiring) { Label("Expiring soon", systemImage: "calendar.badge.exclamationmark") }
                Toggle(isOn: $shopping) { Label("Shopping reminders", systemImage: "cart") }
                Toggle(isOn: $meals) { Label("Meal plan reminders", systemImage: "calendar") }
            } header: {
                Text("Pantry alerts")
            } footer: {
                Text("Stock alerts trigger when an ingredient drops to 2 or fewer. Expiration alerts are scheduled two days before the date. Reminders are local to this device.")
            }
            Section {
                Button("Enable notifications on this iPhone") {
                    Task {
                        let allowed = await PantryNotifications.requestAuthorization()
                        permissionDenied = !allowed
                        if allowed { await update() }
                    }
                }
                Text("Notifications only appear after you grant permission in iOS Settings.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .tint(Color.biteGreen)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: lowStock) { _, _ in Task { await update() } }
        .onChange(of: expiring) { _, _ in Task { await update() } }
        .onChange(of: shopping) { _, _ in Task { await update() } }
        .onChange(of: meals) { _, _ in Task { await update() } }
        .alert("Notifications disabled", isPresented: $permissionDenied) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Enable notifications for BITE! in the iPhone Settings app.")
        }
    }

    private func update() async {
        await PantryNotifications.update(pantry: app.pantry, shopping: app.shopping, plan: app.plan)
    }
}

/// Present visible banners even when BITE! is open in the foreground.
private final class BiteNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = BiteNotificationDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }
}
