import SwiftUI

enum HomeSheet: Identifiable {
    case settings
    case redeem
    case addSub
    case automation
    case editSub(Subscription, isNew: Bool)

    var id: String {
        switch self {
        case .settings: return "settings"
        case .redeem: return "redeem"
        case .addSub: return "add"
        case .automation: return "automation"
        case .editSub(let sub, _): return "edit-\(sub.id)"
        }
    }
}

struct HomeView: View {
    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router
    @Environment(Toast.self) private var toast
    @State private var sheet: HomeSheet?

    var body: some View {
        let analysis = store.analysis
        let visible = analysis.insights.filter { !store.data.dismissed.contains($0.id) }
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if store.data.example {
                        ExampleBanner { store.replace(with: AppData()) }
                    }
                    HeroCard(analysis: analysis, wallet: Engine.walletSummary(store.data)) {
                        router.tab = .milhas
                    }
                    quickActions
                    if needsSetup {
                        SetupCard { router.tab = .milhas }
                    }
                    insightsSection(visible)
                    upcomingSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 28)
            }
            .background(Theme.background)
            .navigationTitle(greeting)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { sheet = .settings } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Ajustes")
                }
            }
            .sheet(item: $sheet) { item in
                sheetContent(item)
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let base = hour < 5 ? "Boa madrugada" : hour < 12 ? "Bom dia" : hour < 18 ? "Boa tarde" : "Boa noite"
        let first = store.data.name.split(separator: " ").first.map(String.init) ?? ""
        return first.isEmpty ? base : "\(base), \(first)"
    }

    private var needsSetup: Bool {
        if store.data.example { return false }
        let walletMissing = store.data.wallet.contains(where: { $0.balance == 0 })
        let spendMissing = store.data.cards.contains(where: { $0.monthlySpend == 0 })
        return walletMissing || spendMissing
    }

    private var quickActions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                QuickActionButton(title: "Qual cartão usar?", symbol: "creditcard") { router.tab = .comprar }
                QuickActionButton(title: "Vale o resgate?", symbol: "star.circle") { sheet = .redeem }
                QuickActionButton(title: "Nova assinatura", symbol: "plus.circle") { sheet = .addSub }
                QuickActionButton(title: "Medir uso dos apps", symbol: "hand.tap") { sheet = .automation }
                QuickActionButton(title: "Lembretes no Calendário", symbol: "calendar.badge.plus") {
                    exportCalendar(subscriptionsOnly: false)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.horizontal, -16)
    }

    private func insightsSection(_ insights: [Insight]) -> some View {
        let actionable = insights.filter { $0.saving > 0 || $0.risk > 0 }.count
        return VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "O que fazer agora", trailing: Fmt.plural(actionable, "ação", "ações"))
            if insights.isEmpty {
                EmptyState(symbol: "checkmark.seal.fill",
                           text: "Tudo otimizado por aqui. Cadastre mais assinaturas e cartões para encontrar novas economias.")
            } else {
                ForEach(insights) { insight in
                    InsightCard(insight: insight,
                                onAction: { action in perform(action) },
                                onDismiss: { withAnimation { store.dismiss(insight.id) } })
                }
            }
            if !store.data.dismissed.isEmpty {
                Button("Mostrar dicas dispensadas") { store.restoreDismissed() }
                    .font(.subheadline.weight(.semibold))
            }
        }
    }

    private var upcomingSection: some View {
        let events = Array(Engine.upcoming(store.data, horizon: 45).prefix(6))
        let firstId = events.first?.id
        return VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Próximos 45 dias", trailing: "Pôr no Calendário") {
                exportCalendar(subscriptionsOnly: false)
            }
            if events.isEmpty {
                EmptyState(symbol: "calendar",
                           text: "Nenhuma renovação ou vencimento à vista. Informe o dia de renovação das assinaturas para acompanhar aqui.")
            } else {
                VStack(spacing: 0) {
                    ForEach(events) { event in
                        if event.id != firstId { Divider().padding(.leading, 72) }
                        UpcomingRow(event: event)
                    }
                }
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    @ViewBuilder
    private func sheetContent(_ item: HomeSheet) -> some View {
        switch item {
        case .settings:
            SettingsView()
        case .redeem:
            NavigationStack {
                ScrollView { RedemptionTool().padding(16) }
                    .background(Theme.background)
                    .navigationTitle("Vale o resgate?")
                    .navigationBarTitleDisplayMode(.inline)
                    .keyboardDoneButton()
            }
            .presentationDetents([.medium, .large])
        case .addSub:
            AddSubscriptionView { svc in
                sheet = .editSub(Subscription.new(for: svc, data: store.data), isNew: true)
            }
        case .automation:
            NavigationStack { AutomationGuideView() }
        case .editSub(let sub, let isNew):
            SubscriptionEditor(sub: sub, isNew: isNew)
        }
    }

    private func exportCalendar(subscriptionsOnly: Bool) {
        Task { @MainActor in
            let message = await store.exportCalendar(subscriptionsOnly: subscriptionsOnly)
            toast.show(message)
        }
    }

    private func perform(_ action: InsightAction) {
        switch action {
        case .editSub(let id):
            if let sub = store.data.subs.first(where: { $0.id == id }) { sheet = .editSub(sub, isNew: false) }
        case .launchSub(let id):
            if let sub = store.data.subs.first(where: { $0.id == id }) { AppLauncher.open(Engine.service(sub).link) }
        case .launchBank(let id):
            AppLauncher.open(Catalog.bank(id)?.link)
        case .launchProgram(let id):
            AppLauncher.open(Catalog.program(id)?.link)
        case .goMiles:
            router.tab = .milhas
        case .calendarSubs:
            exportCalendar(subscriptionsOnly: true)
        case .automation:
            sheet = .automation
        }
    }
}

// MARK: Peças da tela inicial

struct HeroCard: View {
    let analysis: Analysis
    let wallet: WalletSummary
    let onWallet: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 18) {
                ScoreRing(score: analysis.score)
                VStack(alignment: .leading, spacing: 12) {
                    stat(label: "Você paga em assinaturas", value: Fmt.brl(analysis.monthlyTotal), note: "por mês", highlight: false)
                    stat(label: "Dá para economizar", value: Fmt.brl(analysis.savings),
                         note: "\(Fmt.brl0(analysis.savings * 12)) por ano", highlight: true)
                }
            }
            Button(action: onWallet) {
                HStack(spacing: 10) {
                    Image(systemName: "star.circle.fill").foregroundStyle(Theme.gold)
                    Text("\(Fmt.int(wallet.points)) pontos e milhas")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                    Spacer()
                    Text("≈ \(Fmt.brl0(wallet.value))").font(.subheadline).opacity(0.75)
                    Image(systemName: "chevron.right").font(.caption.weight(.semibold)).opacity(0.6)
                }
                .padding(12)
                .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            if analysis.companyValue > 0 {
                Label {
                    Text("Sua empresa paga \(Fmt.brl(analysis.companyValue))/mês em benefícios. Use antes de pagar algo parecido.")
                } icon: {
                    Image(systemName: "sparkles").foregroundStyle(Theme.gold)
                }
                .font(.footnote)
            }
        }
        .padding(18)
        .foregroundStyle(Theme.onInk)
        .background(Theme.heroGradient)
        .overlay(alignment: .topTrailing) {
            Circle()
                .stroke(Theme.gold.opacity(0.16), lineWidth: 28)
                .frame(width: 200, height: 200)
                .offset(x: 70, y: -80)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private func stat(label: String, value: String, note: String, highlight: Bool) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label).font(.caption).opacity(0.75)
            Text(value)
                .font(.title3.weight(.semibold).monospacedDigit())
                .foregroundStyle(highlight ? Theme.gold : Theme.onInk)
                .contentTransition(.numericText())
            Text(note).font(.caption2).opacity(0.65)
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(Theme.accent)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2, reservesSpace: true)
            }
            .frame(width: 112, alignment: .leading)
            .padding(14)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct InsightCard: View {
    let insight: Insight
    let onAction: (InsightAction) -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(insight.kind.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(0.8)
                    .foregroundStyle(.secondary)
                if insight.saving > 0 {
                    Pill(text: "−\(Fmt.brl(insight.saving))/mês", style: .good)
                } else if insight.risk > 0 {
                    Pill(text: "\(Fmt.brl0(insight.risk)) em risco", style: .bad)
                }
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .padding(6)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Dispensar dica")
            }
            Text(insight.title).font(.headline)
            Text(insight.body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if !insight.buttons.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(insight.buttons, id: \.self) { button in
                        Button(button.label) { onAction(button.action) }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .padding(.leading, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .overlay(alignment: .leading) {
            Rectangle().fill(stripe).frame(width: 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var stripe: Color {
        switch insight.severity {
        case .high: return Theme.bad
        case .med: return Theme.warn
        case .low: return Theme.accent
        case .info: return Theme.gold
        case .good: return Theme.good
        }
    }
}

struct UpcomingRow: View {
    let event: UpcomingEvent

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 0) {
                Text(Fmt.day(event.date)).font(.system(.title3, design: .rounded).weight(.bold))
                Text(Fmt.month(event.date).uppercased()).font(.caption2.weight(.semibold))
            }
            .frame(width: 46, height: 46)
            .foregroundStyle(kindColor)
            .background(kindColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title).font(.subheadline.weight(.semibold)).lineLimit(1)
                Text(Fmt.relative(event.date)).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            if event.amount > 0 {
                Text(Fmt.brl(event.amount)).font(.subheadline.monospacedDigit())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var kindColor: Color {
        switch event.kind {
        case .renew: return Color.primary
        case .expire: return Theme.bad
        case .trip: return Theme.accent
        }
    }
}

struct SetupCard: View {
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wand.and.stars").font(.title3).foregroundStyle(Theme.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text("Complete seus dados").font(.subheadline.weight(.semibold))
                Text("Informe saldos de pontos e quanto gasta por mês em cada cartão. As sugestões ficam bem mais precisas.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            Button("Completar", action: action)
                .buttonStyle(.borderedProminent)
                .tint(Theme.ink)
                .controlSize(.small)
        }
        .padding(14)
        .background(Theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct EmptyState: View {
    let symbol: String
    let text: String
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: symbol).font(.title2).foregroundStyle(Theme.accent)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let title = buttonTitle, let action = action {
                Button(title, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.ink)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                .foregroundStyle(Color.secondary.opacity(0.35))
        )
    }
}
