import Foundation

/// Formatação em português do Brasil (moeda, números e datas).
enum Fmt {
    static let locale = Locale(identifier: "pt_BR")

    private static func numberFormatter(style: NumberFormatter.Style, decimals: Int?) -> NumberFormatter {
        let f = NumberFormatter()
        f.locale = locale
        f.numberStyle = style
        if style == .currency { f.currencyCode = "BRL" }
        if let decimals = decimals {
            f.minimumFractionDigits = 0
            f.maximumFractionDigits = decimals
            if style == .currency { f.minimumFractionDigits = decimals }
        }
        return f
    }

    private static let currencyFormatter = numberFormatter(style: .currency, decimals: 2)
    private static let currencyRoundFormatter = numberFormatter(style: .currency, decimals: 0)
    private static let integerFormatter = numberFormatter(style: .decimal, decimals: 0)

    /// R$ 1.234,56
    static func brl(_ value: Double) -> String {
        currencyFormatter.string(from: NSNumber(value: value)) ?? "R$ 0,00"
    }

    /// R$ 1.235
    static func brl0(_ value: Double) -> String {
        currencyRoundFormatter.string(from: NSNumber(value: value.rounded())) ?? "R$ 0"
    }

    /// 48.000
    static func int(_ value: Double) -> String {
        integerFormatter.string(from: NSNumber(value: value.rounded())) ?? "0"
    }

    /// 1,25 (até `decimals` casas)
    static func number(_ value: Double, decimals: Int = 2) -> String {
        numberFormatter(style: .decimal, decimals: decimals).string(from: NSNumber(value: value)) ?? "0"
    }

    /// 0.0114 -> "1,14%"
    static func pct(_ fraction: Double, decimals: Int = 2) -> String {
        number(fraction * 100, decimals: decimals) + "%"
    }

    /// Lê números digitados em pt-BR: "1.234,56", "95.000", "44,9", "12.5".
    static func parse(_ raw: String) -> Double {
        var s = raw.filter { "0123456789,.-".contains($0) }
        if s.isEmpty { return 0 }
        if s.contains(",") {
            s = s.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
        } else if s.range(of: #"^-?\d{1,3}(\.\d{3})+$"#, options: .regularExpression) != nil {
            s = s.replacingOccurrences(of: ".", with: "")
        }
        return Double(s) ?? 0
    }

    private static func dateFormatter(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = locale
        f.timeZone = TimeZone.current
        f.dateFormat = format
        return f
    }

    private static let dayFormatter = dateFormatter("dd")
    private static let monthFormatter = dateFormatter("MMM")
    private static let longFormatter = dateFormatter("d 'de' MMM 'de' yyyy")
    private static let monthNameFormatter = dateFormatter("LLLL")

    static func day(_ date: Date) -> String { dayFormatter.string(from: date) }

    static func month(_ date: Date) -> String {
        monthFormatter.string(from: date).replacingOccurrences(of: ".", with: "")
    }

    static func date(_ date: Date) -> String {
        longFormatter.string(from: date).replacingOccurrences(of: ".", with: "")
    }

    /// Nome do mês (1 = janeiro).
    static func monthName(_ month: Int) -> String {
        var comps = DateComponents()
        comps.year = 2026
        comps.month = min(12, max(1, month))
        comps.day = 1
        guard let d = Engine.calendar.date(from: comps) else { return "\(month)" }
        return monthNameFormatter.string(from: d)
    }

    /// "hoje", "amanhã", "em 5 dias", "há 2 dias"
    static func relative(_ date: Date, now: Date = Date()) -> String {
        let n = Engine.daysUntil(date, from: now)
        if n < 0 { return n == -1 ? "há 1 dia" : "há \(-n) dias" }
        if n == 0 { return "hoje" }
        if n == 1 { return "amanhã" }
        return "em \(n) dias"
    }

    static func plural(_ n: Int, _ singular: String, _ pluralForm: String) -> String {
        n == 1 ? "\(n) \(singular)" : "\(n) \(pluralForm)"
    }
}
