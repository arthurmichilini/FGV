import SwiftUI

struct TripsView: View {
    @Environment(AppStore.self) private var store
    @State private var editing: TripDraft?

    struct TripDraft: Identifiable {
        let trip: Trip
        let isNew: Bool
        var id: String { trip.id }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Compare dinheiro e milhas em cada viagem e descubra a melhor forma de emitir.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if store.data.trips.isEmpty {
                        EmptyState(symbol: "airplane.departure",
                                   text: "Planeje uma viagem e compare o preço em dinheiro com as opções em milhas.")
                    } else {
                        ForEach(store.data.trips) { trip in
                            Button {
                                editing = TripDraft(trip: trip, isNew: false)
                            } label: {
                                TicketView(trip: trip, analysis: Engine.tripOptions(store.data, trip))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Button {
                        editing = TripDraft(trip: newTrip(), isNew: true)
                    } label: {
                        Label("Planejar viagem", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.ink)
                    perks
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
            .background(Theme.background)
            .navigationTitle("Viagens")
            .sheet(item: $editing) { draft in
                TripEditor(trip: draft.trip, isNew: draft.isNew)
            }
        }
    }

    private func newTrip() -> Trip {
        Trip(origin: "", dest: "", date: Engine.addDays(45), back: nil, pax: 1, bonusPct: 0,
             offers: [TripOffer(type: .cash), TripOffer(type: .miles, program: "smiles")])
    }

    private var perks: some View {
        let lounge = store.data.cards.filter { $0.lounge }.map { $0.name }
        let insured = store.data.cards.first { $0.insurance }
        let loungeText = lounge.isEmpty ? "Nenhum cartão cadastrado dá acesso." : lounge.joined(separator: ", ")
        let insuranceText = insured.map { "Emita a passagem com o \($0.name) para ativar o seguro do cartão." }
            ?? "Nenhum cartão com seguro cadastrado. Considere contratar à parte."
        let iofText = "IOF de \(Fmt.number(store.data.settings.iof, decimals: 2))% no cartão. Conta global com câmbio comercial costuma sair mais barata."
        return VStack(alignment: .leading, spacing: 12) {
            Text("Benefícios dos seus cartões").font(.title3.weight(.bold))
            perkRow(symbol: "sofa.fill", title: "Salas VIP", text: loungeText)
            perkRow(symbol: "cross.case.fill", title: "Seguro viagem", text: insuranceText)
            perkRow(symbol: "globe.americas.fill", title: "Compras no exterior", text: iofText)
        }
        .cardStyle()
    }

    private func perkRow(symbol: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol).foregroundStyle(Theme.accent).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(text).font(.footnote).foregroundStyle(.secondary)
            }
        }
    }
}

/// Cartão de embarque com a melhor opção da viagem.
struct TicketView: View {
    let trip: Trip
    let analysis: TripAnalysis

    var body: some View {
        let winner = analysis.options.first { $0.id == analysis.winnerId }
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Text(code(trip.origin))
                    Image(systemName: "airplane").font(.title3).foregroundStyle(Theme.accent)
                    Text(code(trip.dest))
                }
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text("Melhor opção").font(.caption2).foregroundStyle(.secondary)
                Text(winner?.label ?? "—").font(.headline).lineLimit(2)
                if let winner = winner {
                    Text(Fmt.brl0(winner.cost)).font(.footnote.monospacedDigit()).foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .frame(width: 118, alignment: .leading)
            .frame(maxHeight: .infinity)
            .background(Theme.background.opacity(0.6))
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 1)
                    .overlay(
                        DashLine()
                            .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                            .foregroundStyle(Color.secondary.opacity(0.5))
                    )
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .background(Theme.card)
        .clipShape(TicketShape(), style: FillStyle(eoFill: true))
        .accessibilityElement(children: .combine)
    }

    private func code(_ value: String) -> String {
        let clean = value.trimmingCharacters(in: .whitespaces)
        return clean.isEmpty ? "—" : String(clean.prefix(3)).uppercased()
    }

    private var subtitle: String {
        var parts: [String] = []
        if let name = trip.destName, !name.isEmpty { parts.append(name) }
        parts.append(trip.date.map { Fmt.date($0) } ?? "sem data")
        parts.append(trip.pax == 1 ? "1 pessoa" : "\(trip.pax) pessoas")
        return parts.joined(separator: " · ")
    }
}

/// Linha vertical (o picote do canhoto).
struct DashLine: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return p
    }
}

/// Retângulo arredondado com os recortes do canhoto.
struct TicketShape: Shape {
    var stubWidth: CGFloat = 118
    var notch: CGFloat = 9

    func path(in rect: CGRect) -> Path {
        var p = Path(roundedRect: rect, cornerRadius: 20, style: .continuous)
        let x = rect.maxX - stubWidth
        p.addEllipse(in: CGRect(x: x - notch, y: rect.minY - notch, width: notch * 2, height: notch * 2))
        p.addEllipse(in: CGRect(x: x - notch, y: rect.maxY - notch, width: notch * 2, height: notch * 2))
        return p
    }
}

/// Edição de uma viagem e comparação das opções.
struct TripEditor: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Trip
    @State private var hasReturn: Bool
    @State private var toastText: String?
    let isNew: Bool

    init(trip: Trip, isNew: Bool) {
        _draft = State(initialValue: trip)
        _hasReturn = State(initialValue: trip.back != nil)
        self.isNew = isNew
    }

    var body: some View {
        NavigationStack {
            Form {
                routeSection
                searchSection
                offersSection
                bonusSection
                resultSection
                if !isNew {
                    Section {
                        Button("Excluir viagem", role: .destructive) {
                            store.removeTrip(draft.id)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "Nova viagem" : "\(draft.origin) → \(draft.dest)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") { save() }
                        .disabled(draft.dest.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    ShareLink(item: shareText) {
                        Label("Enviar plano", systemImage: "square.and.arrow.up")
                    }
                    Spacer()
                    Button {
                        addToCalendar()
                    } label: {
                        Label("Calendário", systemImage: "calendar.badge.plus")
                    }
                }
            }
            .keyboardDoneButton()
            .alert("Calendário", isPresented: Binding(get: { toastText != nil }, set: { if !$0 { toastText = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(toastText ?? "")
            }
        }
    }

    private var routeSection: some View {
        Section("Trecho") {
            HStack {
                TextField("Origem (GRU)", text: $draft.origin)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                Image(systemName: "arrow.right").foregroundStyle(.secondary)
                TextField("Destino (LIS)", text: $draft.dest)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.trailing)
            }
            TextField("Nome do destino (opcional)", text: destNameBinding)
            DatePicker("Ida", selection: dateBinding, displayedComponents: .date)
            Toggle("Ida e volta", isOn: $hasReturn)
            if hasReturn {
                DatePicker("Volta", selection: backBinding, in: (draft.date ?? Date())..., displayedComponents: .date)
            }
            Stepper("Passageiros: \(draft.pax)", value: $draft.pax, in: 1...9)
        }
    }

    private var searchSection: some View {
        Section {
            if let url = googleFlightsURL {
                Link(destination: url) {
                    Label("Google Voos", systemImage: "magnifyingglass")
                }
            }
            ForEach(["smiles", "latam", "azul"], id: \.self) { id in
                Button {
                    AppLauncher.open(Catalog.program(id)?.link)
                } label: {
                    Label("Buscar no \(Catalog.program(id)?.name ?? id)", systemImage: "arrow.up.forward.app")
                }
            }
        } header: {
            Text("Pesquisar preços")
        } footer: {
            Text("Pesquise, volte aqui e anote as opções encontradas abaixo.")
        }
    }

    private var offersSection: some View {
        Section {
            ForEach($draft.offers) { $offer in
                OfferRow(offer: $offer)
            }
            .onDelete { draft.offers.remove(atOffsets: $0) }
            Button {
                draft.offers.append(TripOffer(type: .cash))
            } label: {
                Label("Preço em dinheiro", systemImage: "plus.circle")
            }
            Button {
                draft.offers.append(TripOffer(type: .miles, program: "latam"))
            } label: {
                Label("Opção em milhas", systemImage: "plus.circle")
            }
        } header: {
            Text("Opções encontradas")
        } footer: {
            Text("Deslize para a esquerda para remover uma opção.")
        }
    }

    private var bonusSection: some View {
        Section {
            Picker("Bônus de transferência", selection: bonusBinding) {
                ForEach([0, 50, 80, 100], id: \.self) { b in Text(verbatim: "\(b)%").tag(b) }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Bônus de transferência disponível")
        } footer: {
            Text("Usado para calcular quantos pontos do banco transferir para completar as milhas.")
        }
    }

    private var resultSection: some View {
        let analysis = Engine.tripOptions(store.data, draft)
        let sorted = analysis.options.filter { $0.cost > 0 }.sorted { $0.cost < $1.cost }
        return Section {
            if sorted.isEmpty {
                Text("Preencha as opções para comparar.").foregroundStyle(.secondary)
            } else {
                ForEach(sorted) { option in
                    TripOptionRow(option: option, isWinner: option.id == analysis.winnerId, bonus: Int(draft.bonusPct))
                }
            }
        } header: {
            Text("Resultado")
        } footer: {
            Text("O custo das milhas usa o valor de referência de cada programa, mais as taxas. Ajuste esses valores em Ajustes.")
        }
    }

    // MARK: Ligações

    private var destNameBinding: Binding<String> {
        Binding(get: { draft.destName ?? "" }, set: { draft.destName = $0.isEmpty ? nil : $0 })
    }

    private var dateBinding: Binding<Date> {
        Binding(get: { draft.date ?? Engine.addDays(45) }, set: { draft.date = $0 })
    }

    private var backBinding: Binding<Date> {
        Binding(get: { draft.back ?? Engine.addDays(7, to: draft.date ?? Date()) }, set: { draft.back = $0 })
    }

    private var bonusBinding: Binding<Int> {
        Binding(get: { Int(draft.bonusPct) }, set: { draft.bonusPct = Double($0) })
    }

    private var googleFlightsURL: URL? {
        var parts = "voos de \(draft.origin) para \(draft.dest)"
        if let d = draft.date { parts += " em \(Fmt.date(d))" }
        if hasReturn, let b = draft.back { parts += " volta \(Fmt.date(b))" }
        var comps = URLComponents(string: "https://www.google.com/travel/flights")
        comps?.queryItems = [
            URLQueryItem(name: "hl", value: "pt-BR"),
            URLQueryItem(name: "curr", value: "BRL"),
            URLQueryItem(name: "q", value: parts),
        ]
        return comps?.url
    }

    private var shareText: String {
        let analysis = Engine.tripOptions(store.data, draft)
        var lines = ["✈️ \(draft.origin) → \(draft.dest)" + (draft.date.map { " · \(Fmt.date($0))" } ?? "")]
        for option in analysis.options.filter({ $0.cost > 0 }).sorted(by: { $0.cost < $1.cost }) {
            let star = option.id == analysis.winnerId ? "★ " : "• "
            let price = option.offer.type == .miles
                ? "\(Fmt.int(option.offer.miles)) milhas + \(Fmt.brl(option.offer.taxes))"
                : Fmt.brl(option.offer.cash)
            lines.append("\(star)\(option.label): \(price) (≈ \(Fmt.brl0(option.cost)))")
        }
        lines.append("Calculado no Milheiro")
        return lines.joined(separator: "\n")
    }

    private func save() {
        draft.origin = draft.origin.trimmingCharacters(in: .whitespaces).uppercased()
        draft.dest = draft.dest.trimmingCharacters(in: .whitespaces).uppercased()
        if draft.date == nil { draft.date = Engine.addDays(45) }
        if !hasReturn { draft.back = nil }
        store.upsert(draft)
        dismiss()
    }

    private func addToCalendar() {
        guard let date = draft.date else { return }
        var items = [Reminders.CalendarItem(key: "trip-\(draft.id)-\(Int(date.timeIntervalSince1970))", date: date,
                                            title: "Viagem \(draft.origin) → \(draft.dest)",
                                            notes: "Confira check-in, seguro do cartão e sala VIP.",
                                            alarmDaysBefore: 7, recurrence: nil)]
        if hasReturn, let back = draft.back {
            items.append(Reminders.CalendarItem(key: "tripback-\(draft.id)-\(Int(back.timeIntervalSince1970))", date: back,
                                                title: "Volta \(draft.dest) → \(draft.origin)",
                                                notes: "Lembrete do Milheiro.", alarmDaysBefore: 1, recurrence: nil))
        }
        Task { @MainActor in
            let result = await Reminders.addToCalendar(items)
            switch result {
            case .added(let keys): toastText = keys.count == 1 ? "Viagem adicionada ao Calendário." : "Ida e volta adicionadas ao Calendário."
            case .denied: toastText = "Sem acesso ao Calendário. Libere em Ajustes > Privacidade e Segurança > Calendários."
            case .failed: toastText = "Não foi possível adicionar ao Calendário agora."
            }
        }
    }
}

struct OfferRow: View {
    @Binding var offer: TripOffer

    var body: some View {
        if offer.type == .cash {
            LabeledContent("Em dinheiro (R$)") {
                NumberField(placeholder: "Preço total", value: $offer.cash)
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Picker("Programa", selection: $offer.program) {
                    ForEach(Catalog.programs.filter { $0.kind == .airline }) { p in Text(p.name).tag(p.id) }
                }
                HStack(spacing: 10) {
                    BoxField(label: "Milhas", value: $offer.miles, decimals: 0)
                    BoxField(label: "Taxas R$", value: $offer.taxes)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct TripOptionRow: View {
    let option: TripOption
    let isWinner: Bool
    let bonus: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(option.label).font(.body.weight(.semibold))
                if isWinner { Pill(text: "melhor", style: .good) }
                if let r = option.redemption { Pill(text: r.verdict, style: pillStyle(r.tone)) }
                Spacer(minLength: 4)
                Text(Fmt.brl0(option.cost)).font(.body.weight(.semibold).monospacedDigit())
            }
            Text(detail).font(.caption).foregroundStyle(.secondary)
            if let plan = plan {
                Text(plan).font(.caption)
            }
        }
        .padding(.vertical, 4)
        .opacity(option.feasible ? 1 : 0.6)
    }

    private var detail: String {
        if option.offer.type == .cash { return option.detail }
        var text = "\(Fmt.int(option.offer.miles)) milhas + \(Fmt.brl(option.offer.taxes))"
        if let r = option.redemption { text += " · milheiro a \(Fmt.brl(r.cpm))" }
        return text
    }

    private var plan: String? {
        guard option.offer.type == .miles, option.offer.miles > 0 else { return nil }
        if option.have >= option.offer.miles { return "Você já tem \(Fmt.int(option.have)) milhas." }
        if let source = option.transferFrom {
            let bonusText = bonus > 0 ? " com \(bonus)% de bônus" : ""
            return "Faltam \(Fmt.int(option.missing)). Transfira \(Fmt.int(option.transferNeed)) pontos \(source.name)\(bonusText)."
        }
        return "Faltam \(Fmt.int(option.missing)) milhas e não há pontos suficientes para transferir."
    }

    private func pillStyle(_ tone: VerdictTone) -> PillStyle {
        switch tone {
        case .good: return .good
        case .warn: return .warn
        case .bad: return .bad
        }
    }
}
