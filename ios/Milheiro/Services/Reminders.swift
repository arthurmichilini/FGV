import Foundation
import UserNotifications
import EventKit

/// Notificações locais e eventos no Calendário do iPhone.
enum Reminders {
    // MARK: Notificações

    static func requestNotifications() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Reagenda tudo: renovações (2 dias antes), pontos vencendo (30 e 7 dias antes) e viagens (7 dias antes).
    static func reschedule(_ data: AppData) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard data.settings.notificationsOn else { return }
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }

        var requests: [UNNotificationRequest] = []

        for sub in data.subs where !sub.paused {
            guard let renewal = Engine.nextRenewal(sub), let fire = fireDate(renewal, daysBefore: 2) else { continue }
            let content = UNMutableNotificationContent()
            content.title = "\(sub.name) renova \(Fmt.relative(renewal, now: fire))"
            content.body = sub.payer == .company
                ? "Benefício pago pela empresa. Aproveite."
                : "Cobrança de \(Fmt.brl(sub.price)). Ainda vale a pena manter? Toque para ver sugestões."
            content.sound = .default
            content.userInfo = ["route": "assinaturas"]
            requests.append(UNNotificationRequest(identifier: "renew-\(sub.id)", content: content, trigger: trigger(fire)))
        }

        for w in data.wallet {
            guard let expiry = w.expiry, w.balance > 0 else { continue }
            let name = Catalog.program(w.programId)?.name ?? w.programId
            for lead in [30, 7] {
                guard let fire = fireDate(expiry, daysBefore: lead) else { continue }
                let content = UNMutableNotificationContent()
                content.title = "Pontos \(name) vencem em \(lead) dias"
                content.body = "\(Fmt.int(w.balance)) pontos em risco. Transfira com bônus ou emita antes do vencimento."
                content.sound = .default
                content.userInfo = ["route": "milhas"]
                requests.append(UNNotificationRequest(identifier: "exp-\(w.id)-\(lead)", content: content, trigger: trigger(fire)))
            }
        }

        for t in data.trips {
            guard let date = t.date, let fire = fireDate(date, daysBefore: 7) else { continue }
            let content = UNMutableNotificationContent()
            content.title = "Viagem \(t.origin) → \(t.dest) em 7 dias"
            content.body = "Confira check-in, seguro do cartão e acesso à sala VIP."
            content.sound = .default
            content.userInfo = ["route": "viagens"]
            requests.append(UNNotificationRequest(identifier: "trip-\(t.id)", content: content, trigger: trigger(fire)))
        }

        // O iOS guarda até 64 notificações agendadas por app.
        for request in requests.prefix(60) {
            try? await center.add(request)
        }
    }

    static func fireDate(_ date: Date, daysBefore: Int) -> Date? {
        let cal = Engine.calendar
        guard let day = cal.date(byAdding: .day, value: -daysBefore, to: Engine.startOfDay(date)),
              let at9 = cal.date(bySettingHour: 9, minute: 0, second: 0, of: day),
              at9 > Date() else { return nil }
        return at9
    }

    static func trigger(_ date: Date) -> UNCalendarNotificationTrigger {
        let comps = Engine.calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
    }

    // MARK: Calendário

    struct CalendarItem {
        let key: String
        let date: Date
        let title: String
        let notes: String
        let alarmDaysBefore: Int
        let recurrence: EKRecurrenceFrequency?
    }

    enum CalendarResult {
        case added([String])
        case denied
        case failed
    }

    static func calendarItems(_ data: AppData, subscriptionsOnly: Bool) -> [CalendarItem] {
        var items: [CalendarItem] = []
        for s in data.subs where !s.paused {
            guard let date = Engine.nextRenewal(s) else { continue }
            let price = s.payer == .company ? "" : " · \(Fmt.brl(s.price))"
            items.append(CalendarItem(
                key: "sub-\(s.id)-\(s.renewDay ?? 0)-\(s.cycle.rawValue)",
                date: date,
                title: "Renova \(s.name)\(price)",
                notes: "Decida antes da cobrança: manter, pausar ou cancelar. Veja as sugestões no Milheiro.",
                alarmDaysBefore: 2,
                recurrence: s.cycle == .annual ? .yearly : .monthly))
        }
        if subscriptionsOnly { return items }
        for w in data.wallet {
            guard let date = w.expiry else { continue }
            let name = Catalog.program(w.programId)?.name ?? w.programId
            items.append(CalendarItem(
                key: "exp-\(w.id)-\(Int(date.timeIntervalSince1970))",
                date: date,
                title: "Vencem pontos \(name)",
                notes: "Saldo: \(Fmt.int(w.balance)). Transfira com bônus ou emita antes do vencimento.",
                alarmDaysBefore: 30,
                recurrence: nil))
        }
        for t in data.trips {
            guard let date = t.date else { continue }
            items.append(CalendarItem(
                key: "trip-\(t.id)-\(Int(date.timeIntervalSince1970))",
                date: date,
                title: "Viagem \(t.origin) → \(t.dest)",
                notes: "Confira check-in, seguro do cartão e sala VIP.",
                alarmDaysBefore: 7,
                recurrence: nil))
        }
        return items
    }

    static func addToCalendar(_ items: [CalendarItem]) async -> CalendarResult {
        let store = EKEventStore()
        let granted: Bool
        do {
            granted = try await store.requestWriteOnlyAccessToEvents()
        } catch {
            return .failed
        }
        guard granted else { return .denied }

        var added: [String] = []
        for item in items {
            let event = EKEvent(eventStore: store)
            event.title = item.title
            event.notes = item.notes
            event.isAllDay = true
            event.startDate = item.date
            event.endDate = item.date
            event.calendar = store.defaultCalendarForNewEvents
            // Alarme às 9h, alguns dias antes.
            event.addAlarm(EKAlarm(relativeOffset: -Double(item.alarmDaysBefore) * Engine.day + 9 * 3600))
            if let frequency = item.recurrence {
                event.addRecurrenceRule(EKRecurrenceRule(recurrenceWith: frequency, interval: 1, end: nil))
            }
            do {
                try store.save(event, span: .futureEvents)
                added.append(item.key)
            } catch {
                continue
            }
        }
        return added.isEmpty ? .failed : .added(added)
    }
}
