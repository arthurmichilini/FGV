import Foundation

// Motor de otimização do Milheiro: funções puras sobre os dados do usuário.

enum Severity: Int, Comparable {
    case high = 0, med, low, info, good

    static func < (lhs: Severity, rhs: Severity) -> Bool { lhs.rawValue < rhs.rawValue }
}

enum InsightAction: Hashable {
    case editSub(String)
    case launchSub(String)
    case launchBank(String)
    case launchProgram(String)
    case goMiles
    case calendarSubs
    case automation
}

struct InsightButton: Hashable {
    let label: String
    let action: InsightAction
}

struct Insight: Identifiable, Hashable {
    let id: String
    let severity: Severity
    let kind: String
    let title: String
    let body: String
    var saving: Double = 0
    var risk: Double = 0
    var buttons: [InsightButton] = []
}

struct Analysis {
    let insights: [Insight]
    let score: Int
    let monthlyTotal: Double
    let savings: Double
    let companyValue: Double
}

enum VerdictTone {
    case good, warn, bad
}

struct RedemptionResult {
    let cpm: Double
    let ref: Double
    let verdict: String
    let tone: VerdictTone
    let ratio: Double
}

struct TransferResult {
    let out: Double
    let before: Double
    let after: Double
}

struct CardReturn: Identifiable {
    let card: PaymentCard
    let rate: Double
    let back: Double
    let iofCost: Double
    let net: Double
    let points: Double
    var id: String { card.id }
}

struct PurchaseResult {
    let ranking: [CardReturn]
    let yieldGain: Double
    let pix: Double
    let portal: Double
    let merchant: Merchant
    let perk: String?
    let iof: Double
}

struct TripOption: Identifiable {
    let offer: TripOffer
    let cost: Double
    let label: String
    let detail: String
    let feasible: Bool
    let have: Double
    let transferFrom: LoyaltyProgram?
    let transferNeed: Double
    let missing: Double
    let redemption: RedemptionResult?
    var id: String { offer.id }
}

struct TripAnalysis {
    let options: [TripOption]
    let winnerId: String?
}

enum UpcomingKind {
    case renew, expire, trip
}

struct UpcomingEvent: Identifiable {
    let id: String
    let date: Date
    let kind: UpcomingKind
    let title: String
    let amount: Double
}

struct WalletSummary {
    let points: Double
    let value: Double
}

enum Engine {
    static let day: TimeInterval = 86_400

    static var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "pt_BR")
        c.timeZone = TimeZone.current
        return c
    }

    static func startOfDay(_ date: Date) -> Date { calendar.startOfDay(for: date) }

    static func daysUntil(_ date: Date, from now: Date = Date()) -> Int {
        calendar.dateComponents([.day], from: startOfDay(now), to: startOfDay(date)).day ?? 0
    }

    static func addDays(_ n: Int, to date: Date = Date()) -> Date {
        calendar.date(byAdding: .day, value: n, to: startOfDay(date)) ?? date
    }

    // MARK: Básicos

    /// Valor de referência do milheiro (R$ por 1.000 pontos).
    static func ref(_ data: AppData, _ programId: String?) -> Double {
        guard let pid = programId, !pid.isEmpty else { return 20 }
        if let custom = data.settings.ref[pid], custom > 0 { return custom }
        return Catalog.program(pid)?.ref ?? 20
    }

    static func service(_ sub: Subscription) -> ServiceInfo {
        Catalog.service(sub.serviceId) ?? Catalog.custom
    }

    /// Custo mensal para o usuário (zero se a empresa paga ou se está pausada).
    static func monthly(_ sub: Subscription) -> Double {
        if sub.payer == .company || sub.paused { return 0 }
        return sub.cycle == .annual ? sub.price / 12 : sub.price
    }

    static func categories(_ sub: Subscription) -> [ServiceCategory] {
        let s = service(sub)
        return [s.cat] + s.also
    }

    static func includes(_ sub: Subscription) -> [String] {
        if let list = sub.includes { return list }
        let s = service(sub)
        if let planName = sub.plan, let plan = s.plans.first(where: { $0.name == planName }) { return plan.includes }
        return s.includes
    }

    /// Retorno em R$ para cada R$ 1 gasto no cartão.
    static func cardRate(_ data: AppData, _ card: PaymentCard, merchant: String? = nil) -> Double {
        var rate: Double
        switch card.earn {
        case .cashback:
            rate = card.cashbackPct / 100
        case .points:
            let usd = data.settings.usd > 0 ? data.settings.usd : 5.4
            rate = (card.ptsPerUSD / usd) * (ref(data, card.program) / 1000)
        case .noRewards:
            rate = 0
        }
        if let m = merchant, let boost = card.merchantBoost[m] { rate = max(rate, boost / 100) }
        return rate
    }

    static func bestCard(_ data: AppData, merchant: String? = nil) -> (card: PaymentCard, rate: Double)? {
        var best: (card: PaymentCard, rate: Double)? = nil
        for card in data.cards {
            let rate = cardRate(data, card, merchant: merchant)
            if let current = best, current.rate >= rate { continue }
            best = (card: card, rate: rate)
        }
        return best
    }

    static func nextRenewal(_ sub: Subscription, now: Date = Date()) -> Date? {
        guard let day = sub.renewDay, day >= 1, day <= 31 else { return nil }
        let cal = calendar
        let today = startOfDay(now)
        let comps = cal.dateComponents([.year, .month], from: today)
        guard let year = comps.year, let month = comps.month else { return nil }

        func clamped(_ y: Int, _ m: Int) -> Date? {
            var c = DateComponents()
            c.year = y
            c.month = m
            c.day = 1
            guard let first = cal.date(from: c), let range = cal.range(of: .day, in: .month, for: first) else { return nil }
            c.day = min(day, range.count)
            return cal.date(from: c)
        }

        if sub.cycle == .annual, let renewMonth = sub.renewMonth {
            if let d = clamped(year, renewMonth), d >= today { return d }
            return clamped(year + 1, renewMonth)
        }
        if let d = clamped(year, month), d >= today { return d }
        return month == 12 ? clamped(year + 1, 1) : clamped(year, month + 1)
    }

    // MARK: Uso medido pelo app Atalhos

    static func opens(_ log: [String: [Date]], serviceId: String, days: Int = 30, now: Date = Date()) -> Int {
        let limit = now.addingTimeInterval(-Double(days) * day)
        return (log[serviceId] ?? []).filter { $0 >= limit }.count
    }

    /// A medição só vale depois de 14 dias, para não acusar pouco uso cedo demais.
    static func isTracking(_ sub: Subscription, now: Date = Date()) -> Bool {
        guard sub.autoTrack, let since = sub.autoTrackSince else { return false }
        return now.timeIntervalSince(since) >= 14 * day
    }

    static func effectiveUsage(_ sub: Subscription, log: [String: [Date]], now: Date = Date()) -> UsageLevel {
        guard isTracking(sub, now: now) else { return sub.usage }
        let n = opens(log, serviceId: sub.serviceId, now: now)
        if n >= 20 { return .daily }
        if n >= 4 { return .weekly }
        if n >= 1 { return .monthly }
        return .rarely
    }

    // MARK: Análise

    static func analyze(_ data: AppData, log: [String: [Date]] = [:], now: Date = Date()) -> Analysis {
        var insights: [Insight] = []
        var flagged = Set<String>()
        let subs = data.subs.filter { !$0.paused }

        func level(_ s: Subscription) -> UsageLevel { effectiveUsage(s, log: log, now: now) }

        // 1. Pagando à parte algo que já vem incluído em outro plano
        for a in subs {
            let inc = includes(a)
            if inc.isEmpty { continue }
            for b in subs {
                if b.id == a.id || b.payer == .company || flagged.contains(b.id) || !inc.contains(b.serviceId) { continue }
                flagged.insert(b.id)
                var body = "Você paga \(Fmt.brl(monthly(b)))/mês à parte. Ative o \(b.name) pelo \(a.name) e cancele a assinatura avulsa."
                if let note = service(a).note { body += " " + note }
                let planText = a.plan.map { " " + $0 } ?? ""
                insights.append(Insight(
                    id: "bundle-\(a.id)-\(b.id)", severity: .high, kind: "Duplicado",
                    title: "\(b.name) já vem no seu \(a.name)\(planText)",
                    body: body, saving: monthly(b),
                    buttons: [InsightButton(label: "Ver \(a.name)", action: .editSub(a.id)),
                              InsightButton(label: "Abrir \(b.name)", action: .launchSub(b.id))]))
            }
        }

        // 2. Mais de um serviço numa categoria em que um basta
        var byCat: [ServiceCategory: [Subscription]] = [:]
        for s in subs {
            for c in categories(s) { byCat[c, default: []].append(s) }
        }
        for cat in ServiceCategory.allCases where cat.exclusive {
            guard let list = byCat[cat], list.count >= 2 else { continue }
            let keep: Subscription
            let extra: [Subscription]
            if let company = list.first(where: { $0.payer == .company }) {
                keep = company
                extra = list.filter { $0.id != company.id && $0.payer != .company && !flagged.contains($0.id) }
            } else {
                let sorted = list.sorted { (level($0).rank, monthly($0)) < (level($1).rank, monthly($1)) }
                keep = sorted[0]
                extra = sorted.dropFirst().filter { $0.payer != .company && !flagged.contains($0.id) }
            }
            if extra.isEmpty { continue }
            for s in extra { flagged.insert(s.id) }
            let saving = extra.reduce(0.0) { $0 + monthly($1) }
            let names = extra.map { $0.name }.joined(separator: " e ")
            let title: String
            var body: String
            if keep.payer == .company {
                title = "\(keep.name) já é pago pela empresa"
                body = "Use o \(keep.name) do benefício corporativo e cancele \(names)."
                if cat == .gym { body += " Antes, confira se as academias que você frequenta estão no plano da empresa." }
            } else {
                title = "Você tem \(list.count) serviços de \(cat.label.lowercased())"
                body = "Fique com \(keep.name), o que você mais usa, e cancele \(names)."
            }
            insights.append(Insight(
                id: "dup-\(cat.rawValue)", severity: .high, kind: "Sobreposição",
                title: title, body: body, saving: saving,
                buttons: extra.map { InsightButton(label: "Ver \($0.name)", action: .editSub($0.id)) }))
        }

        // 3. Streamings de vídeo demais: rodízio
        let video = (byCat[.video] ?? []).filter { $0.payer != .company && !flagged.contains($0.id) && monthly($0) > 0 }
        if video.count > 2 {
            let sorted = video.sorted { level($0).rank < level($1).rank }
            let keptNames = sorted.prefix(2).map { $0.name }.joined(separator: " e ")
            let rest = Array(sorted.dropFirst(2))
            let restNames = rest.map { $0.name }.joined(separator: ", ")
            for s in rest { flagged.insert(s.id) }
            insights.append(Insight(
                id: "video-rotation", severity: .med, kind: "Rodízio",
                title: "\(video.count) streamings de vídeo ao mesmo tempo",
                body: "Mantenha \(keptNames) e faça rodízio com \(restNames): assine um por mês, maratone e cancele.",
                saving: rest.reduce(0.0) { $0 + monthly($1) },
                buttons: [InsightButton(label: "Lembretes no Calendário", action: .calendarSubs)]))
        }

        // 4. Pouco uso (informado por você ou medido pelo app Atalhos)
        for s in subs {
            if flagged.contains(s.id) || s.payer == .company || monthly(s) <= 0 || level(s) != .rarely { continue }
            flagged.insert(s.id)
            var lead = ""
            if isTracking(s, now: now) {
                let n = opens(log, serviceId: s.serviceId, now: now)
                lead = "Você abriu o app \(Fmt.plural(n, "vez", "vezes")) nos últimos 30 dias. "
            }
            insights.append(Insight(
                id: "unused-\(s.id)", severity: monthly(s) >= 30 ? .high : .med, kind: "Pouco uso",
                title: "Você quase não usa \(s.name)",
                body: lead + "São \(Fmt.brl(monthly(s) * 12)) por ano. Cancele ou pause e assine de novo só quando precisar.",
                saving: monthly(s),
                buttons: [InsightButton(label: "Abrir \(s.name)", action: .launchSub(s.id))]))
        }

        // 5. Plano anual mais barato para o que você usa sempre
        for s in subs {
            let svc = service(s)
            guard !flagged.contains(s.id), s.payer != .company, s.cycle == .monthly, let annual = svc.annual else { continue }
            let lv = level(s)
            guard lv == .daily || lv == .weekly else { continue }
            let diff = (s.price * 12 - annual) / 12
            if diff > 1 {
                insights.append(Insight(
                    id: "annual-\(s.id)", severity: .low, kind: "Plano anual",
                    title: "\(s.name) sai mais barato no plano anual",
                    body: "Anual por cerca de \(Fmt.brl(annual)) contra \(Fmt.brl(s.price * 12)) pagando mês a mês. Vale para o que você usa toda semana.",
                    saving: diff,
                    buttons: [InsightButton(label: "Editar", action: .editSub(s.id))]))
            }
        }

        // 6. Clubes de pontos: quanto custa cada milheiro
        for s in subs {
            let svc = service(s)
            guard svc.cat == .club, s.payer != .company else { continue }
            let pts = s.pointsPerMonth ?? svc.pointsPerMonth ?? 0
            guard pts > 0 else { continue }
            let program = s.program ?? svc.program
            let cpm = monthly(s) / pts * 1000
            let r = ref(data, program)
            if cpm > r * 0.9 {
                insights.append(Insight(
                    id: "club-\(s.id)", severity: .med, kind: "Clube caro",
                    title: "\(s.name): milheiro a \(Fmt.brl(cpm))",
                    body: "Você paga mais pelo milheiro do que ele costuma valer em resgates (cerca de \(Fmt.brl(r))). Só mantenha se o clube der bônus que você usa, como bônus em transferências.",
                    saving: monthly(s),
                    buttons: [InsightButton(label: "Ver clube", action: .editSub(s.id))]))
            } else {
                insights.append(Insight(
                    id: "club-ok-\(s.id)", severity: .good, kind: "Bom negócio",
                    title: "\(s.name) compensa",
                    body: "Seu milheiro sai a \(Fmt.brl(cpm)), abaixo do valor de referência (\(Fmt.brl(r)))."))
            }
        }

        // 7. Anuidade maior que o retorno do cartão
        for c in data.cards where c.fee > 0 && c.monthlySpend > 0 {
            let yearly = c.monthlySpend * 12 * cardRate(data, c)
            if yearly < c.fee {
                insights.append(Insight(
                    id: "fee-\(c.id)", severity: .high, kind: "Anuidade",
                    title: "\(c.name): anuidade maior que o retorno",
                    body: "Você paga \(Fmt.brl(c.fee))/ano e recebe cerca de \(Fmt.brl(yearly)) em pontos ou cashback. Peça isenção no app do banco (muitos isentam com gasto mínimo ou investimento) ou troque por um cartão sem anuidade.",
                    saving: (c.fee - yearly) / 12,
                    buttons: [InsightButton(label: "Abrir app do banco", action: .launchBank(c.bankId))]))
            }
        }

        // 8. Assinaturas cobradas no cartão que rende menos
        if let best = bestCard(data), best.rate > 0 {
            var gain = 0.0
            var moved: [String] = []
            for s in subs where s.payer != .company && monthly(s) > 0 {
                var current = 0.0
                if let card = data.cards.first(where: { $0.id == s.cardId }) { current = cardRate(data, card) }
                if best.rate - current > 0.001 {
                    gain += monthly(s) * (best.rate - current)
                    moved.append(s.name)
                }
            }
            if gain >= 1 {
                let list = moved.prefix(4).joined(separator: ", ") + (moved.count > 4 ? "…" : "")
                insights.append(Insight(
                    id: "move-subs", severity: .low, kind: "Pontos",
                    title: "Passe \(Fmt.plural(moved.count, "assinatura", "assinaturas")) para o \(best.card.name)",
                    body: "\(list) estão em um cartão que rende menos. Trocando, você ganha cerca de \(Fmt.brl(gain * 12)) por ano em pontos ou cashback.",
                    saving: gain))
            }
        }

        // 9. Pontos perto de vencer
        for w in data.wallet {
            guard let exp = w.expiry, w.balance > 0 else { continue }
            let days = daysUntil(exp, from: now)
            if days > 180 { continue }
            let p = Catalog.program(w.programId)
            let name = p?.name ?? w.programId
            let value = w.balance / 1000 * ref(data, w.programId)
            let title = days < 0
                ? "Pontos \(name) vencidos"
                : "\(Fmt.int(w.balance)) pontos \(name) vencem em \(Fmt.plural(days, "dia", "dias"))"
            let body = p?.kind == .bank
                ? "Cerca de \(Fmt.brl(value)) em risco. Transfira para uma companhia aérea, de preferência numa campanha com bônus. Lá a validade costuma ser maior."
                : "Cerca de \(Fmt.brl(value)) em risco. Emita uma passagem ou faça uma movimentação no programa para renovar a validade, se ele permitir."
            insights.append(Insight(
                id: "exp-\(w.id)", severity: days <= 90 ? .high : .med, kind: "Vencendo",
                title: title, body: body, risk: value,
                buttons: [InsightButton(label: "Abrir \(name)", action: .launchProgram(w.programId)),
                          InsightButton(label: "Simular transferência", action: .goMiles)]))
        }

        // 10. Pontos de banco parados: esperar campanha de bônus
        for w in data.wallet where w.balance >= 10_000 {
            guard let p = Catalog.program(w.programId), p.kind == .bank else { continue }
            if let exp = w.expiry, daysUntil(exp, from: now) <= 90 { continue }
            insights.append(Insight(
                id: "bonus-\(w.id)", severity: .info, kind: "Estratégia",
                title: "\(Fmt.int(w.balance)) pontos \(p.name): espere o bônus",
                body: "Campanhas de transferência com 80% a 100% de bônus aparecem várias vezes por ano. Com 100%, viram \(Fmt.int(w.balance * 2)) milhas. Não transfira sem bônus, a menos que vá emitir já.",
                buttons: [InsightButton(label: "Simular", action: .goMiles)]))
        }

        // Pontuação de 0 a 100
        var score = 100
        for i in insights {
            switch i.severity {
            case .high: score -= 12
            case .med: score -= 6
            case .low: score -= 3
            default: break
            }
        }
        if !data.cards.contains(where: { $0.earn != .noRewards }) { score -= 8 }
        score = max(5, min(100, score))

        insights.sort { lhs, rhs in
            if lhs.severity != rhs.severity { return lhs.severity < rhs.severity }
            return lhs.saving > rhs.saving
        }

        let monthlyTotal = data.subs.reduce(0.0) { $0 + monthly($1) }
        let companyValue = data.subs.filter { $0.payer == .company }.reduce(0.0) { $0 + $1.price }
        let savings = insights.reduce(0.0) { $0 + $1.saving }
        return Analysis(insights: insights, score: score, monthlyTotal: monthlyTotal, savings: savings, companyValue: companyValue)
    }

    // MARK: Carteira

    static func walletSummary(_ data: AppData) -> WalletSummary {
        var points = 0.0
        var value = 0.0
        for w in data.wallet {
            points += w.balance
            value += w.balance / 1000 * ref(data, w.programId)
        }
        return WalletSummary(points: points, value: value)
    }

    static func transfer(_ data: AppData, from: String, to: String, points: Double, bonusPct: Double, ratio: Double = 1) -> TransferResult {
        let out = (points * ratio * (1 + bonusPct / 100)).rounded(.down)
        return TransferResult(out: out, before: points / 1000 * ref(data, from), after: out / 1000 * ref(data, to))
    }

    /// Quanto vale cada milheiro num resgate: (preço em dinheiro − taxas) ÷ milhas × 1.000.
    static func redemption(_ data: AppData, cash: Double, miles: Double, taxes: Double, programId: String) -> RedemptionResult? {
        guard miles > 0, cash > 0 else { return nil }
        let cpm = (cash - taxes) / miles * 1000
        let r = ref(data, programId)
        let verdict: String
        let tone: VerdictTone
        if cpm >= r * 1.2 {
            verdict = "Excelente resgate"; tone = .good
        } else if cpm >= r {
            verdict = "Bom resgate"; tone = .good
        } else if cpm >= r * 0.7 {
            verdict = "Razoável"; tone = .warn
        } else {
            verdict = "Pague em dinheiro"; tone = .bad
        }
        return RedemptionResult(cpm: cpm, ref: r, verdict: verdict, tone: tone, ratio: cpm / r)
    }

    // MARK: Compras

    static func purchase(_ data: AppData, amount: Double, merchantId: String, installments: Int = 1,
                         pixPct: Double = 0, portalPts: Double = 0, portalProgram: String = "livelo") -> PurchaseResult {
        let merchant = Catalog.merchant(merchantId) ?? Catalog.outroMerchant
        let iof = merchant.intl ? (data.settings.iof > 0 ? data.settings.iof : 3.5) / 100 : 0
        let usd = data.settings.usd > 0 ? data.settings.usd : 5.4
        var ranking: [CardReturn] = []
        for card in data.cards {
            let rate = cardRate(data, card, merchant: merchant.id)
            let back = amount * rate
            let iofCost = amount * iof
            let pts = card.earn == .points ? (amount / usd * card.ptsPerUSD).rounded() : 0
            ranking.append(CardReturn(card: card, rate: rate, back: back, iofCost: iofCost, net: back - iofCost, points: pts))
        }
        ranking.sort { $0.net > $1.net }

        let n = max(1, installments)
        let cdi = (data.settings.cdiMonthly > 0 ? data.settings.cdiMonthly : 1) / 100
        var gain = 0.0
        if n > 1 {
            for k in 1..<n { gain += amount / Double(n) * Double(k) * cdi }
        }
        gain *= 0.8 // depois do imposto de renda, aproximado

        let pix = amount * pixPct / 100
        let portal = portalPts > 0 ? amount * portalPts * ref(data, portalProgram) / 1000 : 0
        var perk: String? = nil
        if let perkId = merchant.perk, data.subs.contains(where: { $0.serviceId == perkId && !$0.paused }) {
            perk = merchant.perkText
        }
        return PurchaseResult(ranking: ranking, yieldGain: gain, pix: pix, portal: portal, merchant: merchant, perk: perk, iof: iof)
    }

    // MARK: Viagens

    static func tripOptions(_ data: AppData, _ trip: Trip) -> TripAnalysis {
        let best = bestCard(data, merchant: "aereo")
        var balances: [String: Double] = [:]
        for w in data.wallet { balances[w.programId, default: 0] += w.balance }
        let bonus = trip.bonusPct
        let cashOffer = trip.offers.first { $0.type == .cash && $0.cash > 0 }

        var options: [TripOption] = []
        for o in trip.offers {
            if o.type == .cash {
                var back = 0.0
                var detail = ""
                if let b = best {
                    back = o.cash * b.rate
                    detail = "Volta ~\(Fmt.brl(back)) no \(b.card.name)"
                }
                options.append(TripOption(offer: o, cost: o.cash - back, label: "Dinheiro", detail: detail,
                                          feasible: o.cash > 0, have: 0, transferFrom: nil, transferNeed: 0,
                                          missing: 0, redemption: nil))
                continue
            }
            let program = Catalog.program(o.program)
            let cost = o.miles / 1000 * ref(data, o.program) + o.taxes
            let have = balances[o.program] ?? 0
            var feasible = o.miles > 0 && have >= o.miles
            var source: LoyaltyProgram? = nil
            var need = 0.0
            let missing = max(0, o.miles - have)
            if !feasible && o.miles > 0 {
                for src in Catalog.programs where src.partners.contains(o.program) {
                    let balance = balances[src.id] ?? 0
                    let required = (missing / (1 + bonus / 100)).rounded(.up)
                    if balance > 0 && balance >= required {
                        source = src
                        need = required
                        feasible = true
                        break
                    }
                }
            }
            var value: RedemptionResult? = nil
            if let c = cashOffer {
                value = Engine.redemption(data, cash: c.cash, miles: o.miles, taxes: o.taxes, programId: o.program)
            }
            options.append(TripOption(offer: o, cost: cost, label: program?.name ?? "Milhas", detail: "",
                                      feasible: feasible, have: have, transferFrom: source, transferNeed: need,
                                      missing: missing, redemption: value))
        }
        let feasibleOnes = options.filter { $0.feasible && $0.cost > 0 }
        let candidates = feasibleOnes.isEmpty ? options.filter { $0.cost > 0 } : feasibleOnes
        let winner = candidates.min { $0.cost < $1.cost }
        return TripAnalysis(options: options, winnerId: winner?.id)
    }

    // MARK: Agenda

    static func upcoming(_ data: AppData, horizon: Int = 45, now: Date = Date()) -> [UpcomingEvent] {
        var events: [UpcomingEvent] = []
        for s in data.subs where !s.paused {
            guard let d = nextRenewal(s, now: now), daysUntil(d, from: now) <= horizon else { continue }
            events.append(UpcomingEvent(id: "renew-\(s.id)", date: d, kind: .renew, title: "Renova \(s.name)",
                                        amount: s.payer == .company ? 0 : s.price))
        }
        for w in data.wallet {
            guard let d = w.expiry, daysUntil(d, from: now) <= max(horizon, 120) else { continue }
            let name = Catalog.program(w.programId)?.name ?? w.programId
            events.append(UpcomingEvent(id: "exp-\(w.id)", date: d, kind: .expire,
                                        title: "Vencem \(Fmt.int(w.balance)) pts \(name)", amount: 0))
        }
        for t in data.trips {
            guard let d = t.date else { continue }
            let n = daysUntil(d, from: now)
            if n < 0 || n > 120 { continue }
            events.append(UpcomingEvent(id: "trip-\(t.id)", date: d, kind: .trip,
                                        title: "Viagem \(t.origin) → \(t.dest)", amount: 0))
        }
        return events.sorted { $0.date < $1.date }
    }
}
