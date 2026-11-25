import Foundation

enum SampleData {
    /// Dados de exemplo para explorar o app. Ficam marcados como exemplo na interface.
    static func example(now: Date = Date()) -> AppData {
        var d = AppData()
        d.onboarded = true
        d.example = true
        d.name = "Arthur"

        let nu = PaymentCard(bankId: "nubank", name: "Nubank Ultravioleta", earn: .cashback, cashbackPct: 1, ptsPerUSD: 0,
                             program: "", fee: 0, monthlySpend: 3500, lounge: true, insurance: true)
        let itau = PaymentCard(bankId: "itau", name: "Itaú Platinum", earn: .points, cashbackPct: 0, ptsPerUSD: 1.5,
                               program: "itau", fee: 500, monthlySpend: 1200)
        let mp = PaymentCard(bankId: "mercadopago", name: "Cartão Mercado Pago", earn: .cashback, cashbackPct: 0, ptsPerUSD: 0,
                             program: "", fee: 0, monthlySpend: 400, merchantBoost: ["mercadolivre": 5])
        d.cards = [nu, itau, mp]

        d.wallet = [
            WalletEntry(programId: "livelo", balance: 48_000, expiry: Engine.addDays(74, to: now)),
            WalletEntry(programId: "itau", balance: 15_200, expiry: Engine.addDays(400, to: now)),
            WalletEntry(programId: "smiles", balance: 22_500, expiry: Engine.addDays(800, to: now)),
            WalletEntry(programId: "latam", balance: 8_300, expiry: Engine.addDays(500, to: now)),
        ]

        let today = Engine.calendar.component(.day, from: now)
        let month = Engine.calendar.component(.month, from: now)
        func day(_ k: Int) -> Int { ((today + k - 1) % 28) + 1 }
        func sub(_ id: String, usage: UsageLevel = .weekly, card: PaymentCard? = nil, renew: Int) -> Subscription {
            let svc = Catalog.service(id) ?? Catalog.custom
            return Subscription(serviceId: id, name: svc.name, price: svc.price, usage: usage,
                                renewDay: renew, cardId: (card ?? itau).id)
        }

        var totalpass = sub("totalpass", renew: 1)
        totalpass.payer = .company
        totalpass.cardId = nil

        var meli = sub("melimais", card: mp, renew: day(9))
        meli.plan = "Total"
        meli.price = 24.90
        meli.includes = ["disney", "deezer"]

        var prime = sub("amazonprime", renew: 14)
        prime.cycle = .annual
        prime.price = 166.80
        prime.renewMonth = ((month + 2) % 12) + 1

        var club = sub("clubesmiles", usage: .monthly, renew: day(25))
        club.pointsPerMonth = 1000
        club.program = "smiles"

        d.subs = [
            totalpass,
            sub("wellhub", card: nu, renew: day(3)),
            meli,
            sub("disney", renew: day(2)),
            sub("netflix", usage: .daily, renew: day(12)),
            sub("max", usage: .rarely, renew: day(6)),
            sub("globoplay", usage: .monthly, renew: day(17)),
            sub("spotify", usage: .daily, card: nu, renew: day(20)),
            prime,
            sub("ifood", renew: day(8)),
            sub("uberone", usage: .monthly, renew: day(22)),
            club,
        ]

        d.trips = [
            Trip(origin: "GRU", dest: "LIS", destName: "Lisboa", date: Engine.addDays(96, to: now),
                 back: Engine.addDays(110, to: now), pax: 1, bonusPct: 100,
                 offers: [
                    TripOffer(type: .cash, cash: 4890),
                    TripOffer(type: .miles, program: "smiles", miles: 95_000, taxes: 380),
                    TripOffer(type: .miles, program: "latam", miles: 120_000, taxes: 290),
                    TripOffer(type: .miles, program: "tap", miles: 70_000, taxes: 520),
                 ]),
        ]
        return d
    }

    /// Dados iniciais a partir do que a pessoa marcou no primeiro acesso.
    static func fromOnboarding(name: String, banks: [String], programs: [String], services: [String: Payer]) -> AppData {
        var d = AppData()
        d.onboarded = true
        d.name = name.trimmingCharacters(in: .whitespaces)
        for id in banks {
            guard let bank = Catalog.bank(id), let p = bank.products.first else { continue }
            d.cards.append(PaymentCard(bankId: id, name: p.name, earn: p.earn, cashbackPct: p.cashbackPct, ptsPerUSD: p.ptsPerUSD,
                                       program: p.program, fee: p.fee, monthlySpend: 0, lounge: p.lounge,
                                       insurance: p.insurance, merchantBoost: p.merchantBoost))
        }
        for id in programs { d.wallet.append(WalletEntry(programId: id, balance: 0, expiry: nil)) }
        for svc in Catalog.services where services[svc.id] != nil {
            let plan = svc.plans.count > 1 ? svc.plans[1] : svc.plans.first
            var s = Subscription(serviceId: svc.id, name: svc.name, price: plan?.price ?? svc.price)
            s.payer = services[svc.id] ?? .me
            s.plan = plan?.name
            s.includes = plan?.includes
            s.cardId = d.cards.first?.id
            s.pointsPerMonth = svc.pointsPerMonth
            s.program = svc.program
            d.subs.append(s)
        }
        return d
    }
}
