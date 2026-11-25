import Foundation
import Observation
import WidgetKit

/// Estado do app. Toda alteração passa por `mutate`, que salva no App Group,
/// atualiza o widget e reagenda as notificações.
@Observable
final class AppStore {
    private(set) var data: AppData
    private(set) var usage: [String: [Date]]

    init() {
        data = SharedStore.load()
        usage = SharedStore.usageLog()
    }

    var analysis: Analysis { Engine.analyze(data, log: usage) }

    func mutate(_ change: (inout AppData) -> Void) {
        change(&data)
        persist()
    }

    func replace(with new: AppData) {
        data = new
        persist()
    }

    /// Relê o registro de uso (gravado pelas automações do app Atalhos).
    func refreshFromDisk() {
        usage = SharedStore.usageLog()
    }

    private func persist() {
        SharedStore.save(data)
        WidgetCenter.shared.reloadAllTimelines()
        let snapshot = data
        Task { await Reminders.reschedule(snapshot) }
    }

    // MARK: Assinaturas

    func upsert(_ sub: Subscription) {
        mutate { d in
            if let i = d.subs.firstIndex(where: { $0.id == sub.id }) { d.subs[i] = sub } else { d.subs.append(sub) }
        }
    }

    func removeSub(_ id: String) {
        mutate { d in d.subs.removeAll { $0.id == id } }
    }

    func togglePause(_ id: String) {
        mutate { d in
            if let i = d.subs.firstIndex(where: { $0.id == id }) { d.subs[i].paused.toggle() }
        }
    }

    // MARK: Cartões, carteira e viagens

    func upsert(_ card: PaymentCard) {
        mutate { d in
            if let i = d.cards.firstIndex(where: { $0.id == card.id }) { d.cards[i] = card } else { d.cards.append(card) }
        }
    }

    func removeCard(_ id: String) {
        mutate { d in d.cards.removeAll { $0.id == id } }
    }

    func upsert(_ entry: WalletEntry) {
        mutate { d in
            if let i = d.wallet.firstIndex(where: { $0.id == entry.id }) { d.wallet[i] = entry } else { d.wallet.append(entry) }
        }
    }

    func removeWallet(_ id: String) {
        mutate { d in d.wallet.removeAll { $0.id == id } }
    }

    func upsert(_ trip: Trip) {
        mutate { d in
            if let i = d.trips.firstIndex(where: { $0.id == trip.id }) { d.trips[i] = trip } else { d.trips.append(trip) }
        }
    }

    func removeTrip(_ id: String) {
        mutate { d in d.trips.removeAll { $0.id == id } }
    }

    // MARK: Dicas

    func dismiss(_ insightId: String) {
        mutate { d in if !d.dismissed.contains(insightId) { d.dismissed.append(insightId) } }
    }

    func restoreDismissed() {
        mutate { d in d.dismissed = [] }
    }

    // MARK: Calendário

    /// Adiciona renovações, vencimentos e viagens ao Calendário, sem repetir os já enviados.
    @MainActor
    func exportCalendar(subscriptionsOnly: Bool = false) async -> String {
        let already = Set(data.calendarExported ?? [])
        let items = Reminders.calendarItems(data, subscriptionsOnly: subscriptionsOnly).filter { !already.contains($0.key) }
        if items.isEmpty {
            return "Nada novo para adicionar. Informe o dia de renovação das assinaturas e o vencimento dos pontos."
        }
        let result = await Reminders.addToCalendar(items)
        switch result {
        case .added(let keys):
            mutate { d in d.calendarExported = (d.calendarExported ?? []) + keys }
            return keys.count == 1 ? "1 lembrete adicionado ao Calendário." : "\(keys.count) lembretes adicionados ao Calendário."
        case .denied:
            return "Sem acesso ao Calendário. Libere em Ajustes > Privacidade e Segurança > Calendários."
        case .failed:
            return "Não foi possível adicionar ao Calendário agora."
        }
    }
}
