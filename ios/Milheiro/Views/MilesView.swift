import SwiftUI

enum MilesSheet: Identifiable {
    case wallet(WalletEntry, isNew: Bool)
    case card(PaymentCard, isNew: Bool)
    case redeem

    var id: String {
        switch self {
        case .wallet(let entry, _): return "wallet-\(entry.id)"
        case .card(let card, _): return "card-\(card.id)"
        case .redeem: return "redeem"
        }
    }
}

struct MilesView: View {
    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router
    @State private var sheet: MilesSheet?

    var body: some View {
        let summary = Engine.walletSummary(store.data)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Fmt.int(summary.points))
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text("pontos e milhas · valem cerca de \(Fmt.brl0(summary.value))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    walletSection
                    RedemptionTool()
                    TransferTool()
                    cardsSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
            .background(Theme.background)
            .navigationTitle("Milhas e pontos")
            .keyboardDoneButton()
            .sheet(item: $sheet) { item in
                switch item {
                case .wallet(let entry, let isNew):
                    WalletEditor(entry: entry, isNew: isNew)
                case .card(let card, let isNew):
                    CardEditor(card: card, isNew: isNew)
                case .redeem:
                    NavigationStack {
                        ScrollView { RedemptionTool().padding(16) }
                            .background(Theme.background)
                            .navigationTitle("Vale o resgate?")
                            .navigationBarTitleDisplayMode(.inline)
                            .keyboardDoneButton()
                    }
                    .presentationDetents([.medium, .large])
                }
            }
            .onAppear(perform: consumeRoute)
            .onChange(of: router.showRedeem) { _, _ in consumeRoute() }
        }
    }

    private func consumeRoute() {
        if router.showRedeem {
            router.showRedeem = false
            sheet = .redeem
        }
    }

    private var walletSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Carteira", trailing: "Adicionar") { sheet = .wallet(newEntry(), isNew: true) }
            if store.data.wallet.isEmpty {
                EmptyState(symbol: "wallet.pass",
                           text: "Adicione Livelo, Smiles, LATAM Pass e os outros programas em que você tem pontos.",
                           buttonTitle: "Adicionar programa") { sheet = .wallet(newEntry(), isNew: true) }
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(store.data.wallet) { entry in
                        Button {
                            sheet = .wallet(entry, isNew: false)
                        } label: {
                            PassCard(entry: entry, value: entry.balance / 1000 * Engine.ref(store.data, entry.programId))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var cardsSection: some View {
        let firstId = store.data.cards.first?.id
        return VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Meus cartões", trailing: "Adicionar") { sheet = .card(PaymentCard(), isNew: true) }
            if store.data.cards.isEmpty {
                EmptyState(symbol: "creditcard",
                           text: "Cadastre seus cartões para saber qual usar em cada compra.",
                           buttonTitle: "Adicionar cartão") { sheet = .card(PaymentCard(), isNew: true) }
            } else {
                VStack(spacing: 0) {
                    ForEach(store.data.cards) { card in
                        if card.id != firstId { Divider().padding(.leading, 66) }
                        Button {
                            sheet = .card(card, isNew: false)
                        } label: {
                            CardRow(card: card, rate: Engine.cardRate(store.data, card))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    private func newEntry() -> WalletEntry {
        let used = Set(store.data.wallet.map { $0.programId })
        let next = Catalog.programs.first { !used.contains($0.id) }?.id ?? "livelo"
        return WalletEntry(programId: next, balance: 0, expiry: nil)
    }
}

struct PassCard: View {
    let entry: WalletEntry
    let value: Double

    var body: some View {
        let program = Catalog.program(entry.programId)
        let isBank = program?.kind == .bank
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(program?.name ?? entry.programId)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(1)
                Spacer(minLength: 4)
                Text(verbatim: isBank ? "BANCO" : "CIA. AÉREA")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(0.6)
                    .opacity(0.75)
            }
            Spacer(minLength: 8)
            Text(Fmt.int(entry.balance))
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .monospacedDigit()
            HStack(spacing: 4) {
                Text("≈ \(Fmt.brl0(value))").font(.caption)
                Spacer(minLength: 4)
                if let expiry = entry.expiry {
                    expiryPill(expiry)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .leading)
        .foregroundStyle(Color.white)
        .background(Color(hex: program?.color ?? 0x64748B))
        .overlay(alignment: .bottomTrailing) {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 100, height: 100)
                .offset(x: 30, y: 40)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func expiryPill(_ date: Date) -> some View {
        let days = Engine.daysUntil(date)
        return Text("vence \(Fmt.relative(date))")
            .font(.system(size: 10, weight: .bold))
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(days <= 90 ? Theme.bad : Color.white.opacity(0.2), in: Capsule())
    }
}

struct CardRow: View {
    let card: PaymentCard
    let rate: Double

    var body: some View {
        let bank = Catalog.bank(card.bankId)
        HStack(spacing: 12) {
            LogoTile(abbr: bank?.abbr ?? "?", color: bank?.color ?? 0x64748B, fg: bank?.fg ?? 0xFFFFFF)
            VStack(alignment: .leading, spacing: 2) {
                Text(card.name.isEmpty ? "Cartão" : card.name).font(.body.weight(.semibold)).lineLimit(1)
                Text(detail).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(Fmt.pct(rate)).font(.body.weight(.semibold)).monospacedDigit()
                Text("de retorno").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
    }

    private var detail: String {
        let earn: String
        switch card.earn {
        case .points:
            earn = "\(Fmt.number(card.ptsPerUSD)) pts/US$ · \(Catalog.program(card.program)?.name ?? "")"
        case .cashback:
            earn = "\(Fmt.number(card.cashbackPct))% de cashback"
        case .noRewards:
            earn = "Não acumula"
        }
        let fee = card.fee > 0 ? "anuidade \(Fmt.brl0(card.fee))" : "sem anuidade"
        return "\(earn) · \(fee)"
    }
}

// MARK: Calculadoras

struct RedemptionTool: View {
    @Environment(AppStore.self) private var store
    @State private var programId = "smiles"
    @State private var cash: Double = 2400
    @State private var miles: Double = 60_000
    @State private var taxes: Double = 180

    var body: some View {
        let result = Engine.redemption(store.data, cash: cash, miles: miles, taxes: taxes, programId: programId)
        VStack(alignment: .leading, spacing: 12) {
            Text("Vale a pena esse resgate?").font(.title3.weight(.bold))
            Text("Compare o preço em dinheiro com as milhas pedidas pela mesma passagem.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                Text("Programa").foregroundStyle(.secondary)
                Spacer()
                Picker("Programa", selection: $programId) {
                    ForEach(Catalog.programs.filter { $0.kind == .airline }) { p in Text(p.name).tag(p.id) }
                }
                .pickerStyle(.menu)
            }
            HStack(spacing: 10) {
                BoxField(label: "Preço em R$", value: $cash)
                BoxField(label: "Milhas", value: $miles, decimals: 0)
                BoxField(label: "Taxas R$", value: $taxes)
            }
            if let result = result {
                VerdictView(result: result)
            } else {
                Text("Informe o preço em dinheiro e as milhas pedidas.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .cardStyle()
    }
}

struct TransferTool: View {
    @Environment(AppStore.self) private var store
    @State private var from = "livelo"
    @State private var to = "smiles"
    @State private var points: Double = 10_000
    @State private var bonus = 100

    var body: some View {
        let partners = Catalog.program(from)?.partners ?? []
        let result = Engine.transfer(store.data, from: from, to: to, points: points, bonusPct: Double(bonus))
        let note: String = result.after > result.before
            ? "Ganho estimado de \(Fmt.brl0(result.after - result.before)) em valor de resgate."
            : "Sem bônus, a transferência costuma não valer a pena. Espere uma campanha."
        VStack(alignment: .leading, spacing: 12) {
            Text("Simular transferência").font(.title3.weight(.bold))
            HStack {
                Text("De").foregroundStyle(.secondary)
                Spacer()
                Picker("De", selection: $from) {
                    ForEach(Catalog.programs.filter { $0.kind == .bank }) { p in Text(p.name).tag(p.id) }
                }
                .pickerStyle(.menu)
            }
            HStack {
                Text("Para").foregroundStyle(.secondary)
                Spacer()
                Picker("Para", selection: $to) {
                    ForEach(partners, id: \.self) { id in Text(Catalog.program(id)?.name ?? id).tag(id) }
                }
                .pickerStyle(.menu)
            }
            BoxField(label: "Pontos", value: $points, decimals: 0)
            VStack(alignment: .leading, spacing: 4) {
                Text("Bônus da campanha").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Picker("Bônus", selection: $bonus) {
                    ForEach([0, 50, 80, 100], id: \.self) { b in Text(verbatim: "\(b)%").tag(b) }
                }
                .pickerStyle(.segmented)
            }
            HStack(alignment: .center) {
                transferSide(title: Catalog.program(from)?.name ?? from, points: points, value: result.before, alignment: .leading)
                Spacer()
                Image(systemName: "arrow.right").foregroundStyle(Theme.accent).font(.title3.weight(.semibold))
                Spacer()
                transferSide(title: Catalog.program(to)?.name ?? to, points: result.out, value: result.after, alignment: .trailing)
            }
            .padding(12)
            .background(Theme.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            Text(note).font(.footnote).foregroundStyle(.secondary)
        }
        .cardStyle()
        .onChange(of: from) { _, newFrom in
            let list = Catalog.program(newFrom)?.partners ?? []
            if !list.contains(to), let first = list.first { to = first }
        }
    }

    private func transferSide(title: String, points: Double, value: Double, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            Text(Fmt.int(points)).font(.title3.weight(.semibold)).monospacedDigit()
            Text("≈ \(Fmt.brl0(value))").font(.caption).foregroundStyle(.secondary)
        }
    }
}

// MARK: Editores

struct WalletEditor: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: WalletEntry
    @State private var hasExpiry: Bool
    @State private var expiry: Date
    let isNew: Bool

    init(entry: WalletEntry, isNew: Bool) {
        _draft = State(initialValue: entry)
        _hasExpiry = State(initialValue: entry.expiry != nil)
        _expiry = State(initialValue: entry.expiry ?? Engine.addDays(365))
        self.isNew = isNew
    }

    var body: some View {
        let program = Catalog.program(draft.programId)
        NavigationStack {
            Form {
                Section {
                    Picker("Programa", selection: $draft.programId) {
                        ForEach(Catalog.programs) { p in Text(p.name).tag(p.id) }
                    }
                    LabeledContent("Saldo") {
                        NumberField(placeholder: "0", value: $draft.balance, decimals: 0)
                    }
                    Toggle("Tenho pontos com vencimento", isOn: $hasExpiry)
                    if hasExpiry {
                        DatePicker("Vencimento mais próximo", selection: $expiry, displayedComponents: .date)
                    }
                } footer: {
                    Text("Veja o saldo e as datas de vencimento no app ou no site do programa.")
                }
                Section {
                    Button {
                        AppLauncher.open(program?.link)
                    } label: {
                        Label("Abrir \(program?.name ?? "programa")", systemImage: "arrow.up.forward.app")
                    }
                    if !isNew {
                        Button("Remover da carteira", role: .destructive) {
                            store.removeWallet(draft.id)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "Adicionar programa" : (program?.name ?? "Programa"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        draft.expiry = hasExpiry ? expiry : nil
                        store.upsert(draft)
                        dismiss()
                    }
                }
            }
            .keyboardDoneButton()
        }
    }
}

struct CardEditor: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: PaymentCard
    let isNew: Bool

    init(card: PaymentCard, isNew: Bool) {
        _draft = State(initialValue: card)
        self.isNew = isNew
    }

    var body: some View {
        let bank = Catalog.bank(draft.bankId)
        NavigationStack {
            Form {
                Section("Banco e produto") {
                    Picker("Banco", selection: bankBinding) {
                        Text("Escolha").tag("")
                        ForEach(Catalog.banks) { b in Text(b.name).tag(b.id) }
                    }
                    if let bank = bank {
                        Picker("Produto", selection: productBinding(bank)) {
                            Text("Personalizado").tag("")
                            ForEach(bank.products, id: \.name) { p in Text(p.name).tag(p.name) }
                        }
                    }
                    TextField("Nome do cartão", text: $draft.name)
                }
                Section {
                    Picker("Como acumula", selection: $draft.earn) {
                        ForEach(EarnType.allCases) { e in Text(e.label).tag(e) }
                    }
                    .pickerStyle(.segmented)
                    if draft.earn == .points {
                        LabeledContent("Pontos por US$") {
                            NumberField(placeholder: "1,0", value: $draft.ptsPerUSD)
                        }
                        Picker("Programa", selection: $draft.program) {
                            ForEach(Catalog.programs) { p in Text(p.name).tag(p.id) }
                        }
                    }
                    if draft.earn == .cashback {
                        LabeledContent("Cashback (%)") {
                            NumberField(placeholder: "1,0", value: $draft.cashbackPct)
                        }
                    }
                } header: {
                    Text("Acúmulo")
                } footer: {
                    Text("Os valores sugeridos são estimativas. Ajuste conforme o seu contrato.")
                }
                Section("Custos e uso") {
                    LabeledContent("Anuidade por ano (R$)") {
                        NumberField(placeholder: "0", value: $draft.fee)
                    }
                    LabeledContent("Gasto médio por mês (R$)") {
                        NumberField(placeholder: "0", value: $draft.monthlySpend)
                    }
                    Toggle("Dá acesso a salas VIP", isOn: $draft.lounge)
                    Toggle("Tem seguro viagem", isOn: $draft.insurance)
                }
                Section {
                    if let bank = bank {
                        Button {
                            AppLauncher.open(bank.link)
                        } label: {
                            Label("Abrir app \(bank.name)", systemImage: "arrow.up.forward.app")
                        }
                    }
                    if !isNew {
                        Button("Excluir cartão", role: .destructive) {
                            store.removeCard(draft.id)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "Adicionar cartão" : (draft.name.isEmpty ? "Cartão" : draft.name))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        store.upsert(draft)
                        dismiss()
                    }
                    .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .keyboardDoneButton()
        }
    }

    private var bankBinding: Binding<String> {
        Binding(
            get: { draft.bankId },
            set: { id in
                draft.bankId = id
                if let product = Catalog.bank(id)?.products.first { apply(product) }
            })
    }

    private func productBinding(_ bank: Bank) -> Binding<String> {
        Binding(
            get: { bank.products.contains(where: { $0.name == draft.name }) ? draft.name : "" },
            set: { name in
                if let product = bank.products.first(where: { $0.name == name }) { apply(product) }
            })
    }

    private func apply(_ product: CardProduct) {
        draft.name = product.name
        draft.earn = product.earn
        draft.cashbackPct = product.cashbackPct
        draft.ptsPerUSD = product.ptsPerUSD
        if !product.program.isEmpty { draft.program = product.program }
        draft.fee = product.fee
        draft.lounge = product.lounge
        draft.insurance = product.insurance
        draft.merchantBoost = product.merchantBoost
    }
}
