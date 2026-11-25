import WidgetKit
import SwiftUI

// Widget da tela inicial e da tela bloqueada: aproveitamento, economia possível
// e as próximas renovações. Lê os dados do App Group compartilhado com o app.

struct SummaryEntry: TimelineEntry {
    let date: Date
    let hasData: Bool
    let score: Int
    let monthly: Double
    let savings: Double
    let next: [UpcomingEvent]

    static var sample: SummaryEntry {
        let now = Date()
        return SummaryEntry(
            date: now, hasData: true, score: 52, monthly: 435, savings: 316.93,
            next: [
                UpcomingEvent(id: "a", date: Engine.addDays(1, to: now), kind: .renew, title: "Renova Netflix", amount: 44.90),
                UpcomingEvent(id: "b", date: Engine.addDays(4, to: now), kind: .renew, title: "Renova Wellhub", amount: 129.90),
            ])
    }
}

struct SummaryProvider: TimelineProvider {
    func placeholder(in context: Context) -> SummaryEntry { .sample }

    func getSnapshot(in context: Context, completion: @escaping (SummaryEntry) -> Void) {
        completion(context.isPreview ? .sample : load())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SummaryEntry>) -> Void) {
        let entry = load()
        // Atualiza logo depois da meia-noite, quando as datas mudam.
        let tomorrow = Engine.addDays(1)
        let refresh = Calendar.current.date(byAdding: .minute, value: 5, to: tomorrow) ?? tomorrow
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }

    private func load() -> SummaryEntry {
        let data = SharedStore.load()
        guard data.onboarded else {
            return SummaryEntry(date: Date(), hasData: false, score: 0, monthly: 0, savings: 0, next: [])
        }
        let analysis = Engine.analyze(data, log: SharedStore.usageLog())
        let next = Engine.upcoming(data, horizon: 30).filter { $0.kind == .renew || $0.kind == .expire }
        return SummaryEntry(date: Date(), hasData: true, score: analysis.score, monthly: analysis.monthlyTotal,
                            savings: analysis.savings, next: Array(next.prefix(3)))
    }
}

struct MilheiroWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SummaryEntry

    var body: some View {
        content
            .widgetURL(URL(string: "milheiro://inicio"))
            .containerBackground(for: .widget) { background }
    }

    @ViewBuilder
    private var content: some View {
        if !entry.hasData {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "star.circle.fill").font(.title2).foregroundStyle(Theme.gold)
                Text("Abra o Milheiro para começar").font(.caption.weight(.semibold))
            }
            .foregroundStyle(Theme.onInk)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        } else {
            switch family {
            case .accessoryCircular:
                Gauge(value: Double(entry.score), in: 0...100) {
                    Text("Milheiro")
                } currentValueLabel: {
                    Text("\(entry.score)")
                }
                .gaugeStyle(.accessoryCircular)
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 1) {
                    Text("Milheiro · \(entry.score)/100").font(.caption2.weight(.semibold))
                    if let first = entry.next.first {
                        Text(first.title).font(.headline).lineLimit(1)
                        Text(Fmt.relative(first.date)).font(.caption)
                    } else {
                        Text("Economize \(Fmt.brl0(entry.savings))/mês").font(.headline).lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            case .accessoryInline:
                Text("Milheiro: economize \(Fmt.brl0(entry.savings))/mês")
            case .systemMedium:
                HStack(spacing: 14) {
                    summary
                    Divider().overlay(Color.white.opacity(0.2))
                    upcomingList
                }
                .foregroundStyle(Theme.onInk)
            default:
                summary.foregroundStyle(Theme.onInk)
            }
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                ZStack {
                    Circle().stroke(Color.white.opacity(0.18), lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: Double(entry.score) / 100)
                        .stroke(Theme.scoreColor(entry.score), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(entry.score)").font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .frame(width: 42, height: 42)
                Text("aproveitamento").font(.caption2).opacity(0.75)
            }
            Spacer(minLength: 0)
            Text("Dá para economizar").font(.caption2).opacity(0.75)
            Text(Fmt.brl0(entry.savings))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.gold)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text("por mês").font(.caption2).opacity(0.65)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var upcomingList: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PRÓXIMOS").font(.system(size: 10, weight: .bold)).tracking(0.8).opacity(0.7)
            if entry.next.isEmpty {
                Text("Nenhuma renovação nos próximos 30 dias.").font(.caption).opacity(0.8)
            } else {
                ForEach(entry.next) { event in
                    VStack(alignment: .leading, spacing: 0) {
                        Text(event.title).font(.caption.weight(.semibold)).lineLimit(1)
                        Text(event.amount > 0 ? "\(Fmt.relative(event.date)) · \(Fmt.brl(event.amount))" : Fmt.relative(event.date))
                            .font(.caption2)
                            .opacity(0.7)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var background: some View {
        switch family {
        case .accessoryCircular, .accessoryRectangular, .accessoryInline:
            AccessoryWidgetBackground()
        default:
            Theme.heroGradient
        }
    }
}

struct MilheiroWidget: Widget {
    let kind = "MilheiroResumo"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SummaryProvider()) { entry in
            MilheiroWidgetView(entry: entry)
        }
        .configurationDisplayName("Resumo Milheiro")
        .description("Seu aproveitamento, quanto dá para economizar e as próximas renovações.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

@main
struct MilheiroWidgetBundle: WidgetBundle {
    var body: some Widget {
        MilheiroWidget()
    }
}
