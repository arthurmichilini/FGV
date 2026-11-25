import Foundation

// Modelos de dados do Milheiro. Ficam num arquivo JSON dentro do App Group,
// compartilhado entre o app, o widget e a extensão de compartilhamento.
// Campos novos devem ser Optional para que dados antigos continuem abrindo.

enum EarnType: String, Codable, CaseIterable, Identifiable {
    case points
    case cashback
    case noRewards = "none"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .points: return "Pontos"
        case .cashback: return "Cashback"
        case .noRewards: return "Não acumula"
        }
    }
}

enum BillingCycle: String, Codable, CaseIterable, Identifiable {
    case monthly
    case annual

    var id: String { rawValue }
    var label: String { self == .monthly ? "Mensal" : "Anual" }
}

enum Payer: String, Codable, CaseIterable, Identifiable {
    case me
    case company

    var id: String { rawValue }
    var label: String { self == .me ? "Eu pago" : "Empresa paga" }
}

enum UsageLevel: String, Codable, CaseIterable, Identifiable {
    case daily
    case weekly
    case monthly
    case rarely

    var id: String { rawValue }

    var label: String {
        switch self {
        case .daily: return "Todo dia"
        case .weekly: return "Toda semana"
        case .monthly: return "Às vezes"
        case .rarely: return "Quase nunca"
        }
    }

    var rank: Int {
        switch self {
        case .daily: return 0
        case .weekly: return 1
        case .monthly: return 2
        case .rarely: return 3
        }
    }
}

enum OfferType: String, Codable {
    case cash
    case miles
}

struct PaymentCard: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var bankId: String = ""
    var name: String = ""
    var earn: EarnType = .points
    var cashbackPct: Double = 0
    var ptsPerUSD: Double = 1
    var program: String = "livelo"
    var fee: Double = 0
    var monthlySpend: Double = 0
    var lounge: Bool = false
    var insurance: Bool = false
    var merchantBoost: [String: Double] = [:]
}

struct WalletEntry: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var programId: String = "livelo"
    var balance: Double = 0
    var expiry: Date? = nil
}

struct Subscription: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var serviceId: String
    var name: String
    var price: Double
    var cycle: BillingCycle = .monthly
    var payer: Payer = .me
    var usage: UsageLevel = .weekly
    var renewDay: Int? = nil
    var renewMonth: Int? = nil
    var cardId: String? = nil
    var includes: [String]? = nil
    var plan: String? = nil
    var pointsPerMonth: Double? = nil
    var program: String? = nil
    var paused: Bool = false
    /// Uso medido por uma automação do app Atalhos ("quando eu abrir o app X").
    var autoTrack: Bool = false
    var autoTrackSince: Date? = nil
}

struct TripOffer: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var type: OfferType = .cash
    var cash: Double = 0
    var program: String = "smiles"
    var miles: Double = 0
    var taxes: Double = 0
}

struct Trip: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var origin: String = ""
    var dest: String = ""
    var destName: String? = nil
    var date: Date? = nil
    var back: Date? = nil
    var pax: Int = 1
    var bonusPct: Double = 0
    var offers: [TripOffer] = []
}

struct AppSettings: Codable, Hashable {
    var usd: Double = 5.4
    var iof: Double = 3.5
    var cdiMonthly: Double = 1.0
    /// Valor de referência do milheiro (R$ por 1.000 pontos) por programa.
    var ref: [String: Double] = [:]
    var notificationsOn: Bool = false
}

struct AppData: Codable {
    var version: Int = 1
    var onboarded: Bool = false
    var example: Bool = false
    var name: String = ""
    var cards: [PaymentCard] = []
    var wallet: [WalletEntry] = []
    var subs: [Subscription] = []
    var trips: [Trip] = []
    var dismissed: [String] = []
    var settings: AppSettings = AppSettings()
    /// Lembretes já enviados ao Calendário (para não duplicar).
    var calendarExported: [String]? = nil
}
