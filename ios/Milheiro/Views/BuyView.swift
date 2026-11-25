import SwiftUI

/// "Qual cartão usar?": ranking dos cartões para uma compra.
struct BuyView: View {
    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router
    @State private var amount: Double = 899.90
    @State private var merchantId = "mercadolivre"
    @State private var installments = 1
    @State private var pixPct: Double = 0
    @State private var portalPts: Double = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Digite o valor, cole um preço copiado ou compartilhe um produto do Safari, da Amazon ou do Mercado Livre direto para o Milheiro.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    inputCard
                    results
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
            .background(Theme.background)
            .navigationTitle("Qual cartão usar?")
            .keyboardDoneButton()
            .onAppear(perform: consumeRoute)
            .onChange(of: router.pendingAmount) { _, _ in consumeRoute() }
        }
    }

    private func consumeRoute() {
        if let value = router.pendingAmount {
            amount = value
            router.pendingAmount = nil
        }
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("R$").font(.title2.weight(.semibold)).foregroundStyle(.secondary)
                NumberField(placeholder: "0,00", value: $amount, alignment: .leading)
                    .font(.system(size: 38, weight: .semibold, design: .rounded))
                PasteButton(payloadType: String.self) { strings in
                    guard let text = strings.first else { return }
                    let parsed = ShareParser.parse(text)
                    DispatchQueue.main.async {
                        if let value = parsed.amount { amount = value }
                        if let merchant = parsed.merchantId { merchantId = merchant }
                    }
                }
                .labelStyle(.iconOnly)
                .buttonBorderShape(.capsule)
            }
            Divider()
            VStack(alignment: .leading, spacing: 6) {
                Text("Onde").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                FlowLayout(spacing: 6) {
                    ForEach(Catalog.merchants) { m in
                        Chip(title: m.name, selected: merchantId == m.id) { merchantId = m.id }
                    }
                }
            }
            HStack(alignment: .bottom, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Parcelas").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    Picker("Parcelas", selection: $installments) {
                        ForEach(1...12, id: \.self) { n in Text("\(n)×").tag(n) }
                    }
                    .pickerStyle(.menu)
                    .padding(.vertical, 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.background, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                }
                BoxField(label: "Desconto Pix %", value: $pixPct)
                BoxField(label: "Shopping pts/R$", value: $portalPts)
            }
        }
        .cardStyle()
    }

    @ViewBuilder
    private var results: some View {
        if store.data.cards.isEmpty {
            EmptyState(symbol: "creditcard", text: "Cadastre seus cartões na aba Milhas para ver qual rende mais.",
                       buttonTitle: "Ir para Milhas") { router.tab = .milhas }
        } else {
            let result = Engine.purchase(store.data, amount: amount, merchantId: merchantId, installments: installments,
                                         pixPct: pixPct, portalPts: portalPts)
            if let best = result.ranking.first {
                WinnerCard(best: best, amount: amount, pix: result.pix)
                notes(result)
                if result.ranking.count > 1 {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(result.ranking.dropFirst()) { item in
                            RankingRow(item: item)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                        }
                    }
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
    }

    private func notes(_ result: PurchaseResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let perk = result.perk {
                NoteRow(symbol: "sparkles", text: perk, color: Theme.good)
            }
            if result.iof > 0 {
                NoteRow(symbol: "globe.americas", text: "Inclui IOF de \(Fmt.pct(result.iof, decimals: 1)) (\(Fmt.brl(amount * result.iof))). Uma conta global pode sair mais barata.", color: Theme.warn)
            }
            if result.portal > 0 {
                NoteRow(symbol: "cart", text: "Comprando pelo shopping de pontos, você ganha mais \(Fmt.brl(result.portal)) em pontos, somados ao cartão.", color: Theme.good)
            }
            if result.yieldGain > 0.5 {
                NoteRow(symbol: "chart.line.uptrend.xyaxis", text: "Parcelando em \(installments)× sem juros e deixando o dinheiro rendendo perto do CDI, você ganha cerca de \(Fmt.brl(result.yieldGain)).", color: Theme.accent)
            }
        }
    }
}

struct WinnerCard: View {
    let best: CardReturn
    let amount: Double
    let pix: Double

    var body: some View {
        let pixWins = pix > 0 && pix > best.net
        let bank = Catalog.bank(best.card.bankId)
        VStack(alignment: .leading, spacing: 10) {
            Text(pixWins ? "MELHOR FORMA DE PAGAR" : "USE ESTE CARTÃO")
                .font(.caption2.weight(.bold))
                .tracking(1)
                .opacity(0.8)
            HStack(spacing: 10) {
                if pixWins {
                    Image(systemName: "qrcode").font(.title2)
                    Text("Pix com desconto").font(.title3.weight(.bold))
                } else {
                    LogoTile(abbr: bank?.abbr ?? "?", color: bank?.color ?? 0x64748B, fg: bank?.fg ?? 0xFFFFFF, size: 36)
                    Text(best.card.name).font(.title3.weight(.bold)).lineLimit(2)
                }
            }
            Text(message(pixWins: pixWins)).font(.subheadline).opacity(0.9)
            if !pixWins, let bank = bank {
                Button {
                    AppLauncher.open(bank.link)
                } label: {
                    Label("Abrir app \(bank.name)", systemImage: "arrow.up.forward.app")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(Theme.onInk)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(Theme.onInk)
        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .sensoryFeedback(.success, trigger: best.card.id)
    }

    private func message(pixWins: Bool) -> String {
        if pixWins {
            return "O desconto de \(Fmt.brl(pix)) vale mais que os \(Fmt.brl(best.net)) que o melhor cartão devolveria."
        }
        let points = best.points > 0 ? " (\(Fmt.int(best.points)) pontos)" : ""
        if best.net >= 0 {
            return "Volta cerca de \(Fmt.brl(best.net))\(points) nesta compra de \(Fmt.brl(amount))."
        }
        return "Rende \(Fmt.brl(best.back))\(points), mas o IOF custa \(Fmt.brl(best.iofCost)). Saldo: \(Fmt.brl(best.net))."
    }
}

struct RankingRow: View {
    let item: CardReturn

    var body: some View {
        let bank = Catalog.bank(item.card.bankId)
        HStack(spacing: 10) {
            LogoTile(abbr: bank?.abbr ?? "?", color: bank?.color ?? 0x64748B, fg: bank?.fg ?? 0xFFFFFF, size: 30)
            Text(item.card.name).font(.subheadline.weight(.semibold)).lineLimit(1)
            Spacer(minLength: 8)
            Text(Fmt.brl(item.net)).font(.subheadline.monospacedDigit()).foregroundStyle(item.net < 0 ? Theme.bad : Color.primary)
        }
    }
}

struct NoteRow: View {
    let symbol: String
    let text: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol).foregroundStyle(color)
            Text(text).font(.footnote).fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
