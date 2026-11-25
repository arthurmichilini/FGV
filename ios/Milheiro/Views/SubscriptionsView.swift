import SwiftUI
import Charts

enum SubFilter: String, CaseIterable, Identifiable {
    case all, me, company, paused
    var id: String { rawValue }
    var label: String {
        switch self {
        case .all: return "Todas"
        case .me: return "Pago eu"
        case .company: return "Empresa"
        case .paused: return "Pausadas"
        }
    }
}

enum SubSheet: Identifiable {
    case add
    case edit(Subscription, isNew: Bool)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let sub, _): return "edit-\(sub.id)"
        }
    }
}

struct SubGroup: Identifiable {
    let category: ServiceCategory
    let subs: [Subscription]
    var id: String { category.rawValue }
}

extension Subscription {
    /// Assinatura nova com os valores sugeridos do catálogo.
    static func new(for svc: ServiceInfo, data: AppData) -> Subscription {
        let plan = svc.plans.count > 1 ? svc.plans[1] : svc.plans.first
        var sub = Subscription(serviceId: svc.id, name: svc.id == "custom" ? "" : svc.name, price: plan?.price ?? svc.price)
        sub.plan = plan?.name
        if let plan = plan { sub.includes = plan.includes } else if !svc.includes.isEmpty { sub.includes = svc.includes }
        sub.cardId = Engine.bestCard(data)?.card.id
        sub.pointsPerMonth = svc.pointsPerMonth
        sub.program = svc.program
        return sub
    }
}

struct SubscriptionsView: View {
    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router
    @State private var filter: SubFilter = .all
    @State private var sheet: SubSheet?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    SpendSummary(subs: store.data.subs)
                }
                Section {
                    Picker("Filtro", selection: $filter) {
                        ForEach(SubFilter.allCases) { f in Text(f.label).tag(f) }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
                if groups.isEmpty {
                    Section {
                        EmptyState(symbol: "rectangle.stack",
                                   text: filter == .paused ? "Nenhuma assinatura pausada." : "Nenhuma assinatura aqui ainda.",
                                   buttonTitle: "Adicionar assinatura") { sheet = .add }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                    }
                }
                ForEach(groups) { group in
                    Section(group.category.label) {
                        ForEach(group.subs) { sub in
                            row(sub)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Assinaturas")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { sheet = .add } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Adicionar assinatura")
                }
            }
            .sheet(item: $sheet) { item in
                switch item {
                case .add:
                    AddSubscriptionView { svc in
                        sheet = .edit(Subscription.new(for: svc, data: store.data), isNew: true)
                    }
                case .edit(let sub, let isNew):
                    SubscriptionEditor(sub: sub, isNew: isNew)
                }
            }
            .onAppear(perform: consumeRoute)
            .onChange(of: router.showNewSub) { _, _ in consumeRoute() }
        }
    }

    private func consumeRoute() {
        if router.showNewSub {
            router.showNewSub = false
            sheet = .add
        }
    }

    private var groups: [SubGroup] {
        let list = store.data.subs.filter { sub in
            switch filter {
            case .all: return !sub.paused
            case .me: return sub.payer == .me && !sub.paused
            case .company: return sub.payer == .company && !sub.paused
            case .paused: return sub.paused
            }
        }
        return ServiceCategory.allCases.compactMap { cat -> SubGroup? in
            let items = list.filter { Engine.service($0).cat == cat }
            return items.isEmpty ? nil : SubGroup(category: cat, subs: items)
        }
    }

    private func row(_ sub: Subscription) -> some View {
        let card = store.data.cards.first(where: { $0.id == sub.cardId })
        let opens: Int? = Engine.isTracking(sub) ? Engine.opens(store.usage, serviceId: sub.serviceId) : nil
        return Button {
            sheet = .edit(sub, isNew: false)
        } label: {
            SubscriptionRow(sub: sub, cardName: card?.name, opens: opens)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .leading) {
            Button {
                AppLauncher.open(Engine.service(sub).link)
            } label: {
                Label("Abrir app", systemImage: "arrow.up.forward.app")
            }
            .tint(Theme.accent)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                store.removeSub(sub.id)
            } label: {
                Label("Excluir", systemImage: "trash")
            }
            Button {
                store.togglePause(sub.id)
            } label: {
                Label(sub.paused ? "Reativar" : "Pausar", systemImage: sub.paused ? "play.fill" : "pause.fill")
            }
            .tint(.orange)
        }
    }
}

struct SubscriptionRow: View {
    let sub: Subscription
    let cardName: String?
    let opens: Int?

    var body: some View {
        let svc = Engine.service(sub)
        HStack(spacing: 12) {
            LogoTile(abbr: svc.abbr, color: svc.color, fg: svc.fg)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(sub.name).font(.body.weight(.semibold)).lineLimit(1)
                    if let plan = sub.plan {
                        Text(plan).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                Text(meta).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                if sub.payer == .company {
                    Pill(text: "empresa", style: .accent)
                } else {
                    Text(Fmt.brl(sub.price)).font(.body.weight(.semibold)).monospacedDigit()
                    Text(sub.cycle == .annual ? "por ano" : "por mês").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .contentShape(Rectangle())
        .opacity(sub.paused ? 0.5 : 1)
        .accessibilityElement(children: .combine)
    }

    private var meta: String {
        var parts: [String] = []
        if let opens = opens {
            parts.append(opens == 1 ? "1 abertura em 30 dias" : "\(opens) aberturas em 30 dias")
        } else {
            parts.append(sub.usage.label)
        }
        if let date = Engine.nextRenewal(sub) { parts.append("renova \(Fmt.relative(date))") }
        if let cardName = cardName { parts.append(cardName) }
        return parts.joined(separator: " · ")
    }
}

/// Total por mês e gráfico de rosca por categoria.
struct SpendSummary: View {
    let subs: [Subscription]

    private struct Slice: Identifiable {
        let category: ServiceCategory
        let value: Double
        var id: String { category.rawValue }
    }

    var body: some View {
        let total = subs.reduce(0.0) { $0 + Engine.monthly($1) }
        let slices = ServiceCategory.allCases.compactMap { cat -> Slice? in
            let value = subs.filter { Engine.service($0).cat == cat }.reduce(0.0) { $0 + Engine.monthly($1) }
            return value > 0 ? Slice(category: cat, value: value) : nil
        }
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Você paga").font(.subheadline).foregroundStyle(.secondary)
                Text(Fmt.brl(total)).font(.title.weight(.bold).monospacedDigit())
                Text("por mês · \(Fmt.brl0(total * 12)) por ano").font(.footnote).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(slices.prefix(4)) { slice in
                        HStack(spacing: 6) {
                            Circle().fill(Color(hex: slice.category.color)).frame(width: 8, height: 8)
                            Text(slice.category.label).font(.caption).lineLimit(1)
                            Spacer(minLength: 4)
                            Text(Fmt.brl0(slice.value)).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 6)
            }
            if !slices.isEmpty {
                Chart(slices) { slice in
                    SectorMark(angle: .value("Gasto", slice.value), innerRadius: .ratio(0.62), angularInset: 1.5)
                        .foregroundStyle(Color(hex: slice.category.color))
                        .cornerRadius(3)
                }
                .chartLegend(.hidden)
                .frame(width: 110, height: 110)
                .accessibilityLabel("Gasto por categoria")
            }
        }
        .padding(.vertical, 6)
    }
}

/// Escolha do serviço ao adicionar uma assinatura.
struct AddSubscriptionView: View {
    let onPick: (ServiceInfo) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var results: [ServiceInfo] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty { return Catalog.services }
        return Catalog.services.filter { $0.name.lowercased().contains(q) || $0.cat.label.lowercased().contains(q) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(results) { svc in
                        Button {
                            onPick(svc)
                        } label: {
                            VStack(spacing: 6) {
                                LogoTile(abbr: svc.abbr, color: svc.color, fg: svc.fg, size: 44)
                                Text(svc.name)
                                    .font(.footnote.weight(.semibold))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2, reservesSpace: true)
                                Text(svc.cat.label)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 6)
                            .frame(maxWidth: .infinity)
                            .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .background(Theme.background)
            .searchable(text: $query, prompt: "Netflix, Wellhub, Meli+…")
            .navigationTitle("Nova assinatura")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
            }
        }
    }
}

/// Edição de uma assinatura.
struct SubscriptionEditor: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Subscription
    @State private var confirmDelete = false
    let isNew: Bool

    init(sub: Subscription, isNew: Bool) {
        _draft = State(initialValue: sub)
        self.isNew = isNew
    }

    private var svc: ServiceInfo { Engine.service(draft) }

    var body: some View {
        NavigationStack {
            Form {
                headerSection
                valueSection
                usageSection
                billingSection
                if showsIncludes { includesSection }
                if svc.cat == .club { clubSection }
                if let note = svc.note {
                    Section { Text(note).font(.footnote).foregroundStyle(.secondary) }
                }
                if !isNew { manageSection }
            }
            .navigationTitle(isNew ? "Adicionar" : draft.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isNew ? "Adicionar" : "Salvar") { save() }
                        .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .keyboardDoneButton()
            .confirmationDialog("Excluir \(draft.name)?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Excluir", role: .destructive) {
                    store.removeSub(draft.id)
                    dismiss()
                }
            }
        }
    }

    private var headerSection: some View {
        Section {
            HStack(spacing: 12) {
                LogoTile(abbr: svc.abbr, color: svc.color, fg: svc.fg, size: 52)
                VStack(alignment: .leading, spacing: 2) {
                    Text(draft.name.isEmpty ? svc.name : draft.name).font(.headline)
                    Text(svc.cat.label).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if AppLauncher.canOpen(svc.link) {
                    Button {
                        AppLauncher.open(svc.link)
                    } label: {
                        Label("Abrir", systemImage: "arrow.up.forward.app")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            if svc.id == "custom" {
                TextField("Nome da assinatura", text: $draft.name)
            }
        }
    }

    private var valueSection: some View {
        Section("Plano e valor") {
            if !svc.plans.isEmpty {
                Picker("Plano", selection: planBinding) {
                    ForEach(svc.plans, id: \.name) { plan in
                        Text("\(plan.name) · \(Fmt.brl(plan.price))").tag(plan.name)
                    }
                }
            }
            LabeledContent("Valor (R$)") {
                NumberField(placeholder: "0,00", value: $draft.price)
            }
            Picker("Cobrança", selection: $draft.cycle) {
                ForEach(BillingCycle.allCases) { c in Text(c.label).tag(c) }
            }
            .pickerStyle(.segmented)
            Picker("Quem paga", selection: $draft.payer) {
                ForEach(Payer.allCases) { p in Text(p.label).tag(p) }
            }
            .pickerStyle(.segmented)
        }
    }

    private var usageSection: some View {
        Section {
            Picker("Quanto você usa", selection: $draft.usage) {
                ForEach(UsageLevel.allCases) { u in Text(u.label).tag(u) }
            }
            if svc.trackable {
                Toggle("Medir uso automaticamente", isOn: autoTrackBinding)
                NavigationLink("Como configurar no app Atalhos") { AutomationGuideView() }
            }
        } header: {
            Text("Uso")
        } footer: {
            if svc.trackable {
                Text("Com uma automação do app Atalhos, o Milheiro conta quantas vezes você abre o \(svc.name). Depois de 14 dias, a medição substitui o que você informou acima.")
            }
        }
    }

    private var billingSection: some View {
        Section("Renovação e cartão") {
            Picker("Dia da renovação", selection: dayBinding) {
                Text("Não sei").tag(0)
                ForEach(1...31, id: \.self) { d in Text("Dia \(d)").tag(d) }
            }
            if draft.cycle == .annual {
                Picker("Mês da renovação", selection: monthBinding) {
                    ForEach(1...12, id: \.self) { m in Text(Fmt.monthName(m).capitalized).tag(m) }
                }
            }
            Picker("Cartão usado", selection: cardBinding) {
                Text("Não sei").tag("")
                ForEach(store.data.cards) { card in Text(card.name).tag(card.id) }
            }
        }
    }

    private var showsIncludes: Bool {
        [.shipping, .mobility, .other].contains(svc.cat) || !svc.includes.isEmpty || !svc.plans.isEmpty
    }

    private var includesSection: some View {
        Section {
            ForEach(Catalog.services.filter { ($0.cat == .video || $0.cat == .music) && $0.id != svc.id }) { other in
                Toggle(other.name, isOn: includeBinding(other.id))
            }
        } header: {
            Text("Este plano inclui")
        } footer: {
            Text("O Milheiro avisa se você paga à parte por algo que já vem incluído.")
        }
    }

    private var clubSection: some View {
        Section("Clube de pontos") {
            LabeledContent("Pontos por mês") {
                NumberField(placeholder: "1.000", value: pointsBinding, decimals: 0)
            }
            Picker("Programa", selection: programBinding) {
                ForEach(Catalog.programs) { p in Text(p.name).tag(p.id) }
            }
        }
    }

    private var manageSection: some View {
        Section {
            Button(draft.paused ? "Reativar assinatura" : "Pausar assinatura") {
                draft.paused.toggle()
                store.upsert(draft)
                dismiss()
            }
            Button("Excluir assinatura", role: .destructive) { confirmDelete = true }
        }
    }

    // MARK: Ligações com o rascunho

    private var planBinding: Binding<String> {
        Binding(
            get: { draft.plan ?? svc.plans.first?.name ?? "" },
            set: { name in
                draft.plan = name
                if let plan = svc.plans.first(where: { $0.name == name }) {
                    draft.price = plan.price
                    draft.includes = plan.includes
                }
            })
    }

    private var dayBinding: Binding<Int> {
        Binding(get: { draft.renewDay ?? 0 }, set: { draft.renewDay = $0 == 0 ? nil : $0 })
    }

    private var monthBinding: Binding<Int> {
        Binding(get: { draft.renewMonth ?? Calendar.current.component(.month, from: Date()) },
                set: { draft.renewMonth = $0 })
    }

    private var cardBinding: Binding<String> {
        Binding(get: { draft.cardId ?? "" }, set: { draft.cardId = $0.isEmpty ? nil : $0 })
    }

    private var autoTrackBinding: Binding<Bool> {
        Binding(get: { draft.autoTrack }, set: { on in
            draft.autoTrack = on
            if on && draft.autoTrackSince == nil { draft.autoTrackSince = Date() }
            if !on { draft.autoTrackSince = nil }
        })
    }

    private var pointsBinding: Binding<Double> {
        Binding(get: { draft.pointsPerMonth ?? svc.pointsPerMonth ?? 0 }, set: { draft.pointsPerMonth = $0 })
    }

    private var programBinding: Binding<String> {
        Binding(get: { draft.program ?? svc.program ?? "smiles" }, set: { draft.program = $0 })
    }

    private func includeBinding(_ id: String) -> Binding<Bool> {
        Binding(
            get: { Engine.includes(draft).contains(id) },
            set: { on in
                var list = Engine.includes(draft)
                if on { if !list.contains(id) { list.append(id) } } else { list.removeAll { $0 == id } }
                draft.includes = list
            })
    }

    private func save() {
        draft.name = draft.name.trimmingCharacters(in: .whitespaces)
        if draft.cycle == .annual && draft.renewMonth == nil {
            draft.renewMonth = Calendar.current.component(.month, from: Date())
        }
        store.upsert(draft)
        dismiss()
    }
}
