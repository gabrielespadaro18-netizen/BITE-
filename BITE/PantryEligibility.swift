import Foundation

/// Conservative ingredient comparison: a pantry item is not substituted for a
/// different variety or preparation. No partial/substring matching is allowed.
enum PantryEligibility {
    static func key(_ input: String) -> String {
        var s = input.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.replacingOccurrences(of: "-", with: " ")
        s = s.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        let aliases: [String: String] = [
            "eggs": "egg", "tomatoes": "tomato", "potatoes": "potato",
            "apples": "apple", "carrots": "carrot", "onions": "onion",
            "bananas": "banana", "cucumbers": "cucumber", "zucchinis": "zucchini",
            "chicken breasts": "chicken breast", "bell peppers": "bell pepper"
        ]
        return aliases[s] ?? s
    }

    static func canCook(ingredients: [String], available: [String]) -> Bool {
        guard !ingredients.isEmpty else { return false }
        let inventory = Set(available.map(key).filter { !$0.isEmpty })
        return ingredients.allSatisfy { inventory.contains(key($0)) }
    }
}
