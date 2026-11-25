import XCTest
@testable import MilheiroCore

final class EngineTests: XCTestCase {
    private var example: AppData { SampleData.example() }

    func testDetectsServiceAlreadyIncludedInAnotherPlan() {
        let analysis = Engine.analyze(example)
        let bundle = analysis.insights.first { $0.id.hasPrefix("bundle-") }
        XCTAssertNotNil(bundle)
        XCTAssertTrue(bundle?.title.contains("Disney+") ?? false)
        XCTAssertEqual(bundle?.saving ?? 0, 46.90, accuracy: 0.001)
    }

    func testCompanyGymMakesPersonalGymRedundant() {
        let gym = Engine.analyze(example).insights.first { $0.id == "dup-gym" }
        XCTAssertEqual(gym?.title, "TotalPass já é pago pela empresa")
        XCTAssertEqual(gym?.saving ?? 0, 129.90, accuracy: 0.001)
    }

    func testTooManyVideoServicesSuggestsRotation() {
        let rotation = Engine.analyze(example).insights.first { $0.id == "video-rotation" }
        XCTAssertNotNil(rotation)
        XCTAssertTrue(rotation?.body.contains("HBO Max") ?? false)
    }

    func testAnnualFeeHigherThanReturn() {
        let fee = Engine.analyze(example).insights.first { $0.id.hasPrefix("fee-") }
        XCTAssertNotNil(fee)
        XCTAssertTrue(fee?.title.contains("Itaú Platinum") ?? false)
    }

    func testExpiringPointsAreFlaggedAsRisk() {
        let expiring = Engine.analyze(example).insights.first { $0.kind == "Vencendo" }
        XCTAssertNotNil(expiring)
        XCTAssertEqual(expiring?.severity, .high)
        XCTAssertEqual(expiring?.risk ?? 0, 48_000 / 1000 * 30, accuracy: 0.001)
    }

    func testScoreStaysInRange() {
        let score = Engine.analyze(example).score
        XCTAssertGreaterThanOrEqual(score, 5)
        XCTAssertLessThanOrEqual(score, 100)
        XCTAssertEqual(Engine.analyze(AppData()).score, 92) // sem cartões que acumulam: −8
    }

    func testRedemptionValuePerThousandMiles() {
        let r = Engine.redemption(AppData(), cash: 4890, miles: 95_000, taxes: 380, programId: "smiles")
        XCTAssertEqual(r?.cpm ?? 0, 47.47, accuracy: 0.01)
        XCTAssertEqual(r?.tone, .good)
        let bad = Engine.redemption(AppData(), cash: 2400, miles: 200_000, taxes: 180, programId: "smiles")
        XCTAssertEqual(bad?.verdict, "Pague em dinheiro")
    }

    func testTransferWithBonus() {
        let t = Engine.transfer(AppData(), from: "livelo", to: "smiles", points: 10_000, bonusPct: 100)
        XCTAssertEqual(t.out, 20_000)
        XCTAssertEqual(t.before, 300, accuracy: 0.001)
        XCTAssertEqual(t.after, 340, accuracy: 0.001)
    }

    func testTripPicksMilesAndPlansTransfer() {
        let data = example
        let analysis = Engine.tripOptions(data, data.trips[0])
        let winner = analysis.options.first { $0.id == analysis.winnerId }
        XCTAssertEqual(winner?.label, "Smiles")
        XCTAssertEqual(winner?.transferFrom?.id, "livelo")
        XCTAssertEqual(winner?.transferNeed ?? 0, 36_250, accuracy: 0.001)
        let latam = analysis.options.first { $0.label == "LATAM Pass" }
        XCTAssertEqual(latam?.feasible, false)
    }

    func testPurchaseRanksBestCardAndChargesIOF() {
        let data = example
        let local = Engine.purchase(data, amount: 1000, merchantId: "mercadolivre")
        XCTAssertEqual(local.ranking.first?.card.name, "Cartão Mercado Pago") // 5% no Mercado Livre
        XCTAssertNotNil(local.perk) // tem Meli+
        let abroad = Engine.purchase(data, amount: 1000, merchantId: "internacional")
        XCTAssertEqual(abroad.iof, 0.035, accuracy: 0.0001)
        XCTAssertEqual(abroad.ranking.first?.card.name, "Nubank Ultravioleta")
        XCTAssertEqual(abroad.ranking.first?.net ?? 0, 10 - 35, accuracy: 0.001)
    }

    func testInstallmentYield() {
        var data = AppData()
        data.cards = [PaymentCard(bankId: "nubank", name: "Nu", earn: .cashback, cashbackPct: 1)]
        let r = Engine.purchase(data, amount: 1200, merchantId: "outro", installments: 3)
        // 400 × (1 + 2) × 1% × 0,8
        XCTAssertEqual(r.yieldGain, 9.6, accuracy: 0.001)
    }

    func testNextRenewalClampsToEndOfMonth() {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 2; comps.day = 10; comps.hour = 12
        let now = Engine.calendar.date(from: comps)!
        let sub = Subscription(serviceId: "netflix", name: "Netflix", price: 44.9, renewDay: 31)
        let next = Engine.nextRenewal(sub, now: now)!
        XCTAssertEqual(Engine.calendar.component(.day, from: next), 28)
        XCTAssertEqual(Engine.calendar.component(.month, from: next), 2)
    }

    func testMeasuredUsageOverridesManualAfterTwoWeeks() {
        let now = Date()
        var sub = Subscription(serviceId: "max", name: "HBO Max", price: 39.9)
        sub.usage = .daily
        sub.autoTrack = true
        sub.autoTrackSince = now.addingTimeInterval(-20 * Engine.day)
        XCTAssertEqual(Engine.effectiveUsage(sub, log: [:], now: now), .rarely)
        let log = ["max": (0..<25).map { now.addingTimeInterval(-Double($0) * 3600) }]
        XCTAssertEqual(Engine.effectiveUsage(sub, log: log, now: now), .daily)
        sub.autoTrackSince = now.addingTimeInterval(-3 * Engine.day)
        XCTAssertEqual(Engine.effectiveUsage(sub, log: [:], now: now), .daily) // ainda não vale
    }

    func testParsesBrazilianNumbers() {
        XCTAssertEqual(Fmt.parse("1.234,56"), 1234.56, accuracy: 0.0001)
        XCTAssertEqual(Fmt.parse("95.000"), 95_000, accuracy: 0.0001)
        XCTAssertEqual(Fmt.parse("44,9"), 44.9, accuracy: 0.0001)
        XCTAssertEqual(Fmt.parse("R$ 12.5"), 12.5, accuracy: 0.0001)
        XCTAssertEqual(Fmt.parse(""), 0)
    }

    func testShareParserFindsPriceAndStore() {
        let r = ShareParser.parse("Olha esse fone na Amazon por R$ 1.499,90 https://www.amazon.com.br/dp/X")
        XCTAssertEqual(r.amount ?? 0, 1499.90, accuracy: 0.001)
        XCTAssertEqual(r.merchantId, "amazon")
        let ml = ShareParser.parse("https://produto.mercadolivre.com.br/MLB-123")
        XCTAssertNil(ml.amount)
        XCTAssertEqual(ml.merchantId, "mercadolivre")
    }

    func testDataSurvivesEncoding() throws {
        let original = example
        let raw = try XCTUnwrap(SharedStore.encode(original))
        let decoded = try XCTUnwrap(SharedStore.decode(raw))
        XCTAssertEqual(decoded.subs.count, original.subs.count)
        XCTAssertEqual(decoded.wallet.first?.balance, 48_000)
        XCTAssertEqual(decoded.trips.first?.offers.count, 4)
    }

    func testOnboardingBuildsDefaults() {
        let data = SampleData.fromOnboarding(name: " Ana ", banks: ["nubank"], programs: ["livelo"],
                                             services: ["melimais": .me, "totalpass": .company])
        XCTAssertEqual(data.name, "Ana")
        XCTAssertEqual(data.cards.first?.name, "Nubank (básico)")
        XCTAssertEqual(data.subs.first { $0.serviceId == "melimais" }?.plan, "Total")
        XCTAssertEqual(data.subs.first { $0.serviceId == "totalpass" }?.payer, .company)
    }
}
