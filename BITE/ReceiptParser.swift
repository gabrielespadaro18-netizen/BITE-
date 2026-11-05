import Foundation

/// OCR suggestions are NEVER committed automatically: the user reviews each row first.
struct ReceiptCandidate: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var quantity: Int = 1
    var selected: Bool = true
}

enum ReceiptParser {
    private static let receiptHeadings = [
        "totale", "subtotale", "tot.", "pagamento", "contanti", "bancomat",
        "iva ", "p.iva", "cf:", "resto", "sconto", "cassiere", "cassa ",
        "orario", "transazione", "scontrino", "documento commerciale", "importo",
        "grazie", "arrivederci", "pos ", "operazione", "pagato"
    ]
    private static let price = try! NSRegularExpression(pattern: #"\s+\d{1,5}[,.]\d{2}\s*(?:€|EUR)?\s*$"#, options: [.caseInsensitive])
    private static let standalone = try! NSRegularExpression(pattern: #"^[\d\s.,€:/-]+$"#)
    private static let productPrefix = try! NSRegularExpression(pattern: #"^\s*(?:\d+\s*[xX]\s*|[A-Z]?\d{7,14}\s+)"#)

    static func parse(_ lines: [String]) -> [ReceiptCandidate] {
        var result: [ReceiptCandidate] = []
        var seen: Set<String> = []
        for raw in lines {
            var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard s.count >= 3, s.count <= 100 else { continue }
            let lower = s.lowercased()
            guard !receiptHeadings.contains(where: { lower.hasPrefix($0) }),
                  standalone.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)) == nil else { continue }
            let n = NSRange(s.startIndex..., in: s)
            s = price.stringByReplacingMatches(in: s, range: n, withTemplate: "")
            s = productPrefix.stringByReplacingMatches(in: s,
                   range: NSRange(s.startIndex..., in: s), withTemplate: "")
            s = s.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
            guard s.count >= 3, s.unicodeScalars.contains(where: { CharacterSet.letters.contains($0) }) else { continue }
            // Very long free-text lines tend to be addresses and store disclosures, not foods.
            guard s.split(separator: " ").count <= 7 else { continue }
            let key = s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            guard seen.insert(key).inserted else { continue }
            result.append(ReceiptCandidate(name: s.localizedCapitalized))
        }
        return result
    }
}
