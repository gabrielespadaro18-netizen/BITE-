import Foundation

// Runs with: swiftc BITE/ReceiptParser.swift Tests/ReceiptParserTests.swift -o /tmp/receipt-tests && /tmp/receipt-tests
@main struct ReceiptParserTests {
    static func main() {
        let sample = [
            "COOP SUPERMERCATO", "LATTE INTERO 1L        1,49", "BANANE BIO       2,99",
            "PANE INTEGRALE 2,15", "TOTALE 6,63", "P.IVA 1234567890", "BANANE BIO 2,99"
        ]
        let foods = ReceiptParser.parse(sample)
        let names = foods.map(\.name)
        precondition(names.contains { $0.localizedCaseInsensitiveContains("latte intero") }, "Milk must be recognized")
        precondition(names.contains { $0.localizedCaseInsensitiveContains("banane bio") }, "Bananas must be recognized")
        precondition(names.contains { $0.localizedCaseInsensitiveContains("pane integrale") }, "Bread must be recognized")
        precondition(!names.contains { $0.localizedCaseInsensitiveContains("totale") }, "No subtotal rows")
        precondition(names.filter { $0 == "Banane Bio" }.count == 1, "No duplicate products")
        print("PASS: receipt parser · \(foods.count) candidates")
    }
}
