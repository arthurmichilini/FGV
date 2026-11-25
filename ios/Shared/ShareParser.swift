import Foundation

/// Lê preço e loja de um texto ou link compartilhado por outro app (Safari, Amazon, Mercado Livre…).
enum ShareParser {
    struct Result {
        var amount: Double?
        var merchantId: String?
    }

    private static let rules: [(id: String, keys: [String])] = [
        ("mercadolivre", ["mercadolivre", "mercado livre", "mercadolibre", "meli.la"]),
        ("amazon", ["amazon.", "amzn.", "a.co/"]),
        ("magalu", ["magazineluiza", "magalu"]),
        ("ifood", ["ifood"]),
        ("uber", ["uber.com", "ubereats"]),
        ("aereo", ["latam", "voegol", "voeazul", "smiles", "booking.com", "decolar", "hotel", "passagem", "airbnb"]),
        ("internacional", ["aliexpress", "shein", "temu", "us$", "usd"]),
    ]

    static func parse(_ text: String) -> Result {
        var result = Result()
        let ns = NSString(string: text)
        if let regex = try? NSRegularExpression(pattern: #"R\$\s?([\d.]+,\d{2}|[\d.]+)"#, options: [.caseInsensitive]),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: ns.length)),
           match.numberOfRanges > 1 {
            let value = Fmt.parse(ns.substring(with: match.range(at: 1)))
            if value > 0 { result.amount = value }
        }
        let lower = text.lowercased()
        for rule in rules where rule.keys.contains(where: { lower.contains($0) }) {
            result.merchantId = rule.id
            break
        }
        return result
    }
}
