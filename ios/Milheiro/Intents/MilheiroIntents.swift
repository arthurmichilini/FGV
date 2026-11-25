import AppIntents
import Foundation

// Integração com Siri, Spotlight, app Atalhos e Botão de Ação.
//
// O destaque é "Registrar uso de app": numa automação do app Atalhos
// ("Quando o Netflix for aberto → Registrar uso"), o Milheiro passa a medir
// quanto você usa cada assinatura de verdade.

enum ServicoOption: String, AppEnum, CaseIterable {
    case netflix
    case disney
    case hbomax = "max"
    case primevideo
    case globoplay
    case appletv
    case paramount
    case youtube
    case spotify
    case deezer
    case amazonmusic
    case amazonprime
    case melimais
    case ifood
    case rappi
    case uberone
    case wellhub
    case totalpass
    case chatgpt
    case claude

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "App de assinatura"

    static let caseDisplayRepresentations: [ServicoOption: DisplayRepresentation] = [
        .netflix: "Netflix",
        .disney: "Disney+",
        .hbomax: "HBO Max",
        .primevideo: "Prime Video",
        .globoplay: "Globoplay",
        .appletv: "Apple TV+",
        .paramount: "Paramount+",
        .youtube: "YouTube",
        .spotify: "Spotify",
        .deezer: "Deezer",
        .amazonmusic: "Amazon Music",
        .amazonprime: "Amazon",
        .melimais: "Mercado Livre",
        .ifood: "iFood",
        .rappi: "Rappi",
        .uberone: "Uber",
        .wellhub: "Wellhub",
        .totalpass: "TotalPass",
        .chatgpt: "ChatGPT",
        .claude: "Claude",
    ]
}

enum LojaOption: String, AppEnum, CaseIterable {
    case mercadolivre
    case amazon
    case magalu
    case ifood
    case uber
    case mercado
    case posto
    case aereo
    case internacional
    case outro

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Loja"

    static let caseDisplayRepresentations: [LojaOption: DisplayRepresentation] = [
        .mercadolivre: "Mercado Livre",
        .amazon: "Amazon",
        .magalu: "Magalu",
        .ifood: "iFood",
        .uber: "Uber",
        .mercado: "Supermercado",
        .posto: "Posto de combustível",
        .aereo: "Passagem aérea ou hotel",
        .internacional: "Compra internacional",
        .outro: "Outra loja",
    ]
}

struct RegistrarUsoIntent: AppIntent {
    static let title: LocalizedStringResource = "Registrar uso de app"
    static let description = IntentDescription("Use numa automação do app Atalhos: quando você abrir um app de assinatura, o Milheiro registra o uso e descobre o que você quase não usa.")

    @Parameter(title: "App")
    var servico: ServicoOption

    static var parameterSummary: some ParameterSummary {
        Summary("Registrar uso de \(\.$servico)")
    }

    func perform() async throws -> some IntentResult {
        SharedStore.recordUsage(servico.rawValue)
        return .result()
    }
}

struct QualCartaoIntent: AppIntent {
    static let title: LocalizedStringResource = "Qual cartão usar?"
    static let description = IntentDescription("Diz qual dos seus cartões rende mais numa compra.")

    @Parameter(title: "Valor da compra")
    var valor: Double

    @Parameter(title: "Loja", default: .outro)
    var loja: LojaOption

    static var parameterSummary: some ParameterSummary {
        Summary("Qual cartão usar em \(\.$valor) na loja \(\.$loja)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let data = SharedStore.load()
        if data.cards.isEmpty {
            return .result(dialog: "Cadastre seus cartões no Milheiro primeiro.")
        }
        let result = Engine.purchase(data, amount: valor, merchantId: loja.rawValue)
        guard let best = result.ranking.first else {
            return .result(dialog: "Não encontrei cartões cadastrados.")
        }
        var text = "Use o \(best.card.name). Volta cerca de \(Fmt.brl(best.net)) numa compra de \(Fmt.brl(valor))."
        if let perk = result.perk { text += " " + perk }
        return .result(dialog: "\(text)")
    }
}

struct ResumoIntent: AppIntent {
    static let title: LocalizedStringResource = "Resumo do Milheiro"
    static let description = IntentDescription("Quanto você gasta em assinaturas, quanto pode economizar e o seu aproveitamento.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let data = SharedStore.load()
        let analysis = Engine.analyze(data, log: SharedStore.usageLog())
        var text = "Você paga \(Fmt.brl(analysis.monthlyTotal)) por mês em assinaturas"
        if analysis.savings > 0 {
            text += " e pode economizar \(Fmt.brl(analysis.savings)) por mês"
        }
        text += ". Seu aproveitamento é \(analysis.score) de 100."
        if let first = analysis.insights.first(where: { $0.saving > 0 || $0.risk > 0 }) {
            text += " Primeira dica: \(first.title)."
        }
        return .result(dialog: "\(text)")
    }
}

struct MilheiroShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: QualCartaoIntent(),
            phrases: [
                "Qual cartão usar no \(.applicationName)",
                "Qual cartão usar na \(\.$loja) com o \(.applicationName)",
            ],
            shortTitle: "Qual cartão usar?",
            systemImageName: "creditcard")
        AppShortcut(
            intent: ResumoIntent(),
            phrases: [
                "Resumo do \(.applicationName)",
                "Quanto posso economizar no \(.applicationName)",
            ],
            shortTitle: "Resumo",
            systemImageName: "chart.pie")
        AppShortcut(
            intent: RegistrarUsoIntent(),
            phrases: [
                "Registrar uso no \(.applicationName)",
                "Registrar uso de \(\.$servico) no \(.applicationName)",
            ],
            shortTitle: "Registrar uso",
            systemImageName: "hand.tap")
    }
}
