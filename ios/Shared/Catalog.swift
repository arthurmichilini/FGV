import Foundation

// Catálogo de bancos, programas de pontos, assinaturas e lojas.
// Preços, taxas de acúmulo e benefícios são ESTIMATIVAS de referência (nov/2026)
// e mudam com frequência. Tudo pode ser ajustado dentro do app.
//
// AppLink.scheme = esquema de URL do app no iPhone (quando conhecido).
// AppLink.web    = site oficial. No iPhone, links universais desses sites
//                  costumam abrir o app quando ele está instalado.

struct AppLink: Hashable {
    var scheme: String? = nil
    var web: String? = nil
}

enum ServiceCategory: String, CaseIterable, Identifiable {
    case video, music, gym, shipping, delivery, mobility, cloud, ai, club, other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .video: return "Streaming de vídeo"
        case .music: return "Música"
        case .gym: return "Academia e bem-estar"
        case .shipping: return "Compras e frete"
        case .delivery: return "Delivery"
        case .mobility: return "Mobilidade"
        case .cloud: return "Armazenamento"
        case .ai: return "Inteligência artificial"
        case .club: return "Clube de pontos"
        case .other: return "Outros"
        }
    }

    /// Categorias em que um serviço costuma bastar.
    var exclusive: Bool {
        switch self {
        case .music, .gym, .delivery, .cloud: return true
        default: return false
        }
    }

    var color: UInt32 {
        switch self {
        case .video: return 0x3F5BD9
        case .music: return 0x1A9E6E
        case .gym: return 0xD9475C
        case .shipping: return 0xD99A1E
        case .delivery: return 0xE06A2B
        case .mobility: return 0x6B7280
        case .cloud: return 0x2F8FD1
        case .ai: return 0x8B5CF6
        case .club: return 0x0E7A6D
        case .other: return 0x94A3B8
        }
    }
}

enum ProgramKind: String {
    case bank
    case airline
}

struct LoyaltyProgram: Identifiable, Hashable {
    let id: String
    let name: String
    let kind: ProgramKind
    let color: UInt32
    let abbr: String
    /// Valor de referência em R$ por 1.000 pontos para resgates bons.
    let ref: Double
    /// Para onde os pontos podem ser transferidos (proporção padrão 1:1).
    let partners: [String]
    let link: AppLink
}

struct CardProduct: Hashable {
    let name: String
    let earn: EarnType
    var cashbackPct: Double = 0
    var ptsPerUSD: Double = 0
    var program: String = ""
    var fee: Double = 0
    var lounge: Bool = false
    var insurance: Bool = false
    var merchantBoost: [String: Double] = [:]
}

struct Bank: Identifiable, Hashable {
    let id: String
    let name: String
    let color: UInt32
    var fg: UInt32 = 0xFFFFFF
    let abbr: String
    let link: AppLink
    let products: [CardProduct]
}

struct ServicePlan: Hashable {
    let name: String
    let price: Double
    let includes: [String]
}

struct ServiceInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let cat: ServiceCategory
    var also: [ServiceCategory] = []
    let price: Double
    var annual: Double? = nil
    let color: UInt32
    var fg: UInt32 = 0xFFFFFF
    let abbr: String
    var includes: [String] = []
    var plans: [ServicePlan] = []
    var note: String? = nil
    var pointsPerMonth: Double? = nil
    var program: String? = nil
    /// Pode ter o uso medido por automação do app Atalhos.
    var trackable: Bool = true
    let link: AppLink
}

struct Merchant: Identifiable, Hashable {
    let id: String
    let name: String
    var perk: String? = nil
    var perkText: String? = nil
    var travel: Bool = false
    var intl: Bool = false
}

enum Catalog {
    static let programs: [LoyaltyProgram] = [
        LoyaltyProgram(id: "livelo", name: "Livelo", kind: .bank, color: 0xE5007E, abbr: "Lv", ref: 30,
                       partners: ["smiles", "latam", "azul", "tap"],
                       link: AppLink(web: "https://www.livelo.com.br")),
        LoyaltyProgram(id: "esfera", name: "Esfera", kind: .bank, color: 0xEC0000, abbr: "Es", ref: 30,
                       partners: ["smiles", "latam", "azul", "tap"],
                       link: AppLink(web: "https://www.esfera.com.vc")),
        LoyaltyProgram(id: "atomos", name: "Átomos C6", kind: .bank, color: 0x1F1F1F, abbr: "C6", ref: 30,
                       partners: ["smiles", "latam", "azul", "tap", "livelo", "esfera"],
                       link: AppLink(web: "https://www.c6bank.com.br")),
        LoyaltyProgram(id: "itau", name: "Itaú Pontos", kind: .bank, color: 0xEC7000, abbr: "It", ref: 28,
                       partners: ["latam", "smiles", "azul"],
                       link: AppLink(web: "https://www.itau.com.br")),
        LoyaltyProgram(id: "nupontos", name: "Nubank Rewards", kind: .bank, color: 0x820AD1, abbr: "Nu", ref: 25,
                       partners: ["smiles", "latam", "azul"],
                       link: AppLink(scheme: "nubank://", web: "https://nubank.com.br")),
        LoyaltyProgram(id: "interloop", name: "Inter Loop", kind: .bank, color: 0xFF7A00, abbr: "In", ref: 20,
                       partners: ["smiles", "latam"],
                       link: AppLink(web: "https://inter.co")),
        LoyaltyProgram(id: "smiles", name: "Smiles", kind: .airline, color: 0xFF5A00, abbr: "Sm", ref: 17,
                       partners: [], link: AppLink(web: "https://www.smiles.com.br")),
        LoyaltyProgram(id: "latam", name: "LATAM Pass", kind: .airline, color: 0x1B0088, abbr: "LA", ref: 25,
                       partners: [], link: AppLink(web: "https://latampass.latam.com")),
        LoyaltyProgram(id: "azul", name: "Azul Fidelidade", kind: .airline, color: 0x0A3E8C, abbr: "Az", ref: 15,
                       partners: [], link: AppLink(web: "https://www.voeazul.com.br")),
        LoyaltyProgram(id: "tap", name: "TAP Miles&Go", kind: .airline, color: 0x00A651, abbr: "TP", ref: 30,
                       partners: [], link: AppLink(web: "https://www.flytap.com/pt-br/miles-and-go")),
    ]

    static let banks: [Bank] = [
        Bank(id: "nubank", name: "Nubank", color: 0x820AD1, abbr: "Nu",
             link: AppLink(scheme: "nubank://", web: "https://nubank.com.br"),
             products: [
                CardProduct(name: "Nubank (básico)", earn: .noRewards),
                CardProduct(name: "Ultravioleta", earn: .cashback, cashbackPct: 1, lounge: true, insurance: true),
                CardProduct(name: "Nubank Rewards", earn: .points, ptsPerUSD: 1, program: "nupontos", fee: 190),
             ]),
        Bank(id: "itau", name: "Itaú", color: 0xEC7000, abbr: "It",
             link: AppLink(web: "https://www.itau.com.br"),
             products: [
                CardProduct(name: "Itaú Personnalité Infinite", earn: .points, ptsPerUSD: 2.2, program: "itau", fee: 1300, lounge: true, insurance: true),
                CardProduct(name: "Itaú Platinum", earn: .points, ptsPerUSD: 1.5, program: "itau", fee: 500),
             ]),
        Bank(id: "santander", name: "Santander", color: 0xEC0000, abbr: "Sa",
             link: AppLink(web: "https://www.santander.com.br"),
             products: [
                CardProduct(name: "Santander Unique", earn: .points, ptsPerUSD: 2.2, program: "esfera", fee: 1300, lounge: true, insurance: true),
                CardProduct(name: "Santander Unlimited", earn: .points, ptsPerUSD: 2, program: "esfera", fee: 900),
             ]),
        Bank(id: "bradesco", name: "Bradesco", color: 0xCC092F, abbr: "Br",
             link: AppLink(web: "https://banco.bradesco"),
             products: [
                CardProduct(name: "Bradesco Visa Infinite", earn: .points, ptsPerUSD: 2.5, program: "livelo", fee: 1200, lounge: true, insurance: true),
                CardProduct(name: "Bradesco Platinum", earn: .points, ptsPerUSD: 1.6, program: "livelo", fee: 600),
             ]),
        Bank(id: "bb", name: "Banco do Brasil", color: 0xF9DD16, fg: 0x0038A8, abbr: "BB",
             link: AppLink(web: "https://www.bb.com.br"),
             products: [
                CardProduct(name: "Ourocard Visa Infinite", earn: .points, ptsPerUSD: 2.2, program: "livelo", fee: 1100, lounge: true, insurance: true),
                CardProduct(name: "Ourocard Platinum", earn: .points, ptsPerUSD: 1.4, program: "livelo", fee: 500),
             ]),
        Bank(id: "c6", name: "C6 Bank", color: 0x1F1F1F, abbr: "C6",
             link: AppLink(web: "https://www.c6bank.com.br"),
             products: [
                CardProduct(name: "C6 Carbon", earn: .points, ptsPerUSD: 2.5, program: "atomos", fee: 1020, lounge: true, insurance: true),
                CardProduct(name: "C6 Platinum", earn: .points, ptsPerUSD: 1, program: "atomos"),
             ]),
        Bank(id: "inter", name: "Inter", color: 0xFF7A00, abbr: "In",
             link: AppLink(web: "https://inter.co"),
             products: [
                CardProduct(name: "Inter Black", earn: .cashback, cashbackPct: 1, lounge: true),
                CardProduct(name: "Inter Gold", earn: .cashback, cashbackPct: 0.25),
             ]),
        Bank(id: "xp", name: "XP", color: 0x111111, abbr: "XP",
             link: AppLink(web: "https://www.xpi.com.br"),
             products: [
                CardProduct(name: "XP Visa Infinite", earn: .cashback, cashbackPct: 1, lounge: true, insurance: true),
             ]),
        Bank(id: "btg", name: "BTG Pactual", color: 0x0B2A55, abbr: "BT",
             link: AppLink(web: "https://www.btgpactual.com"),
             products: [
                CardProduct(name: "BTG Black", earn: .points, ptsPerUSD: 2.5, program: "livelo", lounge: true, insurance: true),
             ]),
        Bank(id: "mercadopago", name: "Mercado Pago", color: 0x00B1EA, abbr: "MP",
             link: AppLink(scheme: "mercadopago://", web: "https://www.mercadopago.com.br"),
             products: [
                CardProduct(name: "Cartão Mercado Pago", earn: .cashback, merchantBoost: ["mercadolivre": 5]),
             ]),
        Bank(id: "picpay", name: "PicPay", color: 0x11C76F, abbr: "PP",
             link: AppLink(scheme: "picpay://", web: "https://www.picpay.com"),
             products: [
                CardProduct(name: "PicPay Card", earn: .cashback),
             ]),
    ]

    static let services: [ServiceInfo] = [
        ServiceInfo(id: "netflix", name: "Netflix", cat: .video, price: 44.90, color: 0xE50914, abbr: "N",
                    link: AppLink(scheme: "nflx://", web: "https://www.netflix.com/browse")),
        ServiceInfo(id: "disney", name: "Disney+", cat: .video, price: 46.90, annual: 449.90, color: 0x0E2A8A, abbr: "D+",
                    link: AppLink(scheme: "disneyplus://", web: "https://www.disneyplus.com")),
        ServiceInfo(id: "max", name: "HBO Max", cat: .video, price: 39.90, annual: 359.90, color: 0x002BE7, abbr: "Mx",
                    link: AppLink(scheme: "hbomax://", web: "https://www.max.com")),
        ServiceInfo(id: "primevideo", name: "Prime Video", cat: .video, price: 19.90, color: 0x1A98FF, abbr: "PV",
                    link: AppLink(scheme: "aiv://", web: "https://www.primevideo.com")),
        ServiceInfo(id: "globoplay", name: "Globoplay", cat: .video, price: 29.90, annual: 269.90, color: 0xFB0234, abbr: "Gp",
                    link: AppLink(scheme: "globoplay://", web: "https://globoplay.globo.com")),
        ServiceInfo(id: "appletv", name: "Apple TV+", cat: .video, price: 29.90, color: 0x111111, abbr: "tv",
                    link: AppLink(scheme: "videos://", web: "https://tv.apple.com")),
        ServiceInfo(id: "paramount", name: "Paramount+", cat: .video, price: 24.90, color: 0x0064FF, abbr: "P+",
                    link: AppLink(web: "https://www.paramountplus.com")),
        ServiceInfo(id: "youtube", name: "YouTube Premium", cat: .video, also: [.music], price: 26.90, color: 0xFF0000, abbr: "YT",
                    link: AppLink(scheme: "youtube://", web: "https://www.youtube.com/premium")),
        ServiceInfo(id: "spotify", name: "Spotify", cat: .music, price: 23.90, color: 0x1DB954, abbr: "Sp",
                    link: AppLink(scheme: "spotify://", web: "https://open.spotify.com")),
        ServiceInfo(id: "deezer", name: "Deezer", cat: .music, price: 26.90, color: 0xA238FF, abbr: "Dz",
                    link: AppLink(scheme: "deezer://", web: "https://www.deezer.com")),
        ServiceInfo(id: "amazonmusic", name: "Amazon Music", cat: .music, price: 21.90, color: 0x25D1DA, abbr: "AM",
                    link: AppLink(web: "https://music.amazon.com.br")),
        ServiceInfo(id: "amazonprime", name: "Amazon Prime", cat: .shipping, price: 19.90, annual: 166.80, color: 0x00A8E1, abbr: "a",
                    includes: ["primevideo", "amazonmusic"],
                    link: AppLink(scheme: "com.amazon.mobile.shopping://", web: "https://www.amazon.com.br/prime")),
        ServiceInfo(id: "melimais", name: "Meli+", cat: .shipping, price: 24.90, color: 0xFFE600, fg: 0x2D3277, abbr: "M+",
                    plans: [
                        ServicePlan(name: "Essencial", price: 9.90, includes: []),
                        ServicePlan(name: "Total", price: 24.90, includes: ["disney", "deezer"]),
                        ServicePlan(name: "Mega", price: 49.90, includes: ["disney", "max", "deezer"]),
                    ],
                    note: "Os benefícios do Meli+ mudam com frequência. Confira o que seu plano inclui no app do Mercado Livre e ajuste aqui.",
                    link: AppLink(scheme: "meli://", web: "https://www.mercadolivre.com.br/assinaturas")),
        ServiceInfo(id: "ifood", name: "Clube iFood", cat: .delivery, price: 12.90, color: 0xEA1D2C, abbr: "iF",
                    link: AppLink(scheme: "ifood://", web: "https://www.ifood.com.br")),
        ServiceInfo(id: "rappi", name: "Rappi Pro", cat: .delivery, price: 24.90, color: 0xFF441F, abbr: "Ra",
                    link: AppLink(web: "https://www.rappi.com.br")),
        ServiceInfo(id: "uberone", name: "Uber One", cat: .mobility, also: [.delivery], price: 25.90, color: 0x000000, abbr: "U1",
                    link: AppLink(scheme: "uber://", web: "https://www.uber.com/br/pt-br/u/uber-one/")),
        ServiceInfo(id: "wellhub", name: "Wellhub (Gympass)", cat: .gym, price: 129.90, color: 0xE5285D, abbr: "Wh",
                    link: AppLink(web: "https://wellhub.com/pt-br/")),
        ServiceInfo(id: "totalpass", name: "TotalPass", cat: .gym, price: 99.90, color: 0x00C389, abbr: "TP",
                    link: AppLink(web: "https://www.totalpass.com/br/")),
        ServiceInfo(id: "academia", name: "Academia (mensalidade)", cat: .gym, price: 119.90, color: 0x475569, abbr: "Ac",
                    trackable: false, link: AppLink()),
        ServiceInfo(id: "icloud", name: "iCloud+", cat: .cloud, price: 14.90, color: 0x3693F3, abbr: "iC",
                    trackable: false, link: AppLink(web: "https://www.icloud.com")),
        ServiceInfo(id: "googleone", name: "Google One", cat: .cloud, price: 9.99, annual: 99.99, color: 0x4285F4, abbr: "G1",
                    trackable: false, link: AppLink(web: "https://one.google.com")),
        ServiceInfo(id: "chatgpt", name: "ChatGPT Plus", cat: .ai, price: 110.00, color: 0x10A37F, abbr: "GP",
                    link: AppLink(web: "https://chatgpt.com")),
        ServiceInfo(id: "claude", name: "Claude Pro", cat: .ai, price: 110.00, color: 0xD97757, abbr: "Cl",
                    link: AppLink(web: "https://claude.ai")),
        ServiceInfo(id: "clubesmiles", name: "Clube Smiles", cat: .club, price: 42.00, color: 0xFF5A00, abbr: "CS",
                    pointsPerMonth: 1000, program: "smiles", trackable: false,
                    link: AppLink(web: "https://www.smiles.com.br/clube-smiles")),
        ServiceInfo(id: "clubelivelo", name: "Clube Livelo", cat: .club, price: 39.90, color: 0xE5007E, abbr: "CL",
                    pointsPerMonth: 1000, program: "livelo", trackable: false,
                    link: AppLink(web: "https://www.livelo.com.br/clube")),
        ServiceInfo(id: "clubelatam", name: "Clube LATAM Pass", cat: .club, price: 45.00, color: 0x1B0088, abbr: "CL",
                    pointsPerMonth: 1000, program: "latam", trackable: false,
                    link: AppLink(web: "https://latampass.latam.com")),
        ServiceInfo(id: "clubeazul", name: "Clube Azul", cat: .club, price: 38.00, color: 0x0A3E8C, abbr: "CA",
                    pointsPerMonth: 1000, program: "azul", trackable: false,
                    link: AppLink(web: "https://www.voeazul.com.br")),
        ServiceInfo(id: "custom", name: "Outra assinatura", cat: .other, price: 0, color: 0x64748B, abbr: "+",
                    trackable: false, link: AppLink()),
    ]

    static let merchants: [Merchant] = [
        Merchant(id: "mercadolivre", name: "Mercado Livre", perk: "melimais",
                 perkText: "Meli+: frete grátis a partir de um valor mínimo menor. Confira antes de pagar o frete."),
        Merchant(id: "amazon", name: "Amazon", perk: "amazonprime",
                 perkText: "Prime: frete grátis e entregas rápidas em itens elegíveis."),
        Merchant(id: "magalu", name: "Magalu"),
        Merchant(id: "ifood", name: "iFood", perk: "ifood",
                 perkText: "Clube iFood: cupons de entrega grátis. Veja se ainda tem cupom no mês."),
        Merchant(id: "uber", name: "Uber / Uber Eats", perk: "uberone",
                 perkText: "Uber One: cashback em Uber Cash nas corridas e taxa zero no Eats."),
        Merchant(id: "mercado", name: "Supermercado"),
        Merchant(id: "posto", name: "Combustível"),
        Merchant(id: "aereo", name: "Passagem aérea / hotel", travel: true),
        Merchant(id: "internacional", name: "Compra internacional", intl: true),
        Merchant(id: "outro", name: "Outra loja"),
    ]

    static func program(_ id: String?) -> LoyaltyProgram? {
        guard let id = id else { return nil }
        return programs.first { $0.id == id }
    }

    static func bank(_ id: String?) -> Bank? {
        guard let id = id else { return nil }
        return banks.first { $0.id == id }
    }

    static func service(_ id: String?) -> ServiceInfo? {
        guard let id = id else { return nil }
        return services.first { $0.id == id }
    }

    static func merchant(_ id: String?) -> Merchant? {
        guard let id = id else { return nil }
        return merchants.first { $0.id == id }
    }

    static var custom: ServiceInfo {
        services.first { $0.id == "custom" } ?? services[services.count - 1]
    }

    static var outroMerchant: Merchant {
        merchants.first { $0.id == "outro" } ?? merchants[merchants.count - 1]
    }
}
