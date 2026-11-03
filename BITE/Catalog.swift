import Foundation

/// Adapts the World Table database (`DatabaseData`) to the app's own recipe model.
enum Catalog {
    private static let countriesById: [String: WTCountry] =
        Dictionary(DatabaseData.countries.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
    private static let areasById: [String: WTArea] =
        Dictionary(DatabaseData.areas.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })

    static let recipes: [Recipe] = DatabaseData.recipes.map(make)

    // MARK: Structured tags and drafts (DraftData.swift)

    private struct Tags {
        var allergens: Set<String>
        var intolerances: Set<String>
        var diets: Set<String>
        var cost: Double
        var goals: Set<String>
    }

    private static let allergenNames = ["milk": "Milk", "eggs": "Eggs", "wheat": "Wheat", "peanuts": "Peanuts",
                                        "treenuts": "Tree Nuts", "soy": "Soy", "fish": "Fish",
                                        "shellfish": "Shellfish", "sesame": "Sesame"]
    private static let intoleranceNames = ["gluten": "Gluten", "lactose": "Lactose", "histamine": "Histamine",
                                           "fructose": "Fructose", "sorbitol": "Sorbitol", "caffeine": "Caffeine",
                                           "sulfites": "Sulfites"]
    private static let dietNames = ["veg": "Vegetarian", "vegan": "Vegan", "halal": "Halal"]
    private static let goalNames = ["H": "High Protein", "L": "Low Carb", "E": "Eat Healthier", "B": "Budget Friendly"]

    private static func list(_ field: String, _ names: [String: String]) -> Set<String> {
        Set(field.split(separator: ",").compactMap { names[String($0).trimmingCharacters(in: .whitespaces)] })
    }

    private static let tagTable: [String: Tags] = {
        var out: [String: Tags] = [:]
        for line in DraftData.tags.split(separator: "\n") {
            let f = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            guard f.count == 6 else { continue }
            var diets = list(f[3], dietNames)
            if diets.contains("Vegan") { diets.insert("Vegetarian") }
            out[f[0]] = Tags(allergens: list(f[1], allergenNames), intolerances: list(f[2], intoleranceNames),
                             diets: diets, cost: Double(f[4]) ?? 3, goals: list(f[5], goalNames))
        }
        return out
    }()

    private struct Draft {
        var minutes: Int
        var servings: Int
        var ingredients: [Ingredient]
        var steps: [String]
    }

    private static let draftTable: [String: Draft] = {
        var out: [String: Draft] = [:]
        let cats = ["p": Category.produce, "d": Category.dairy, "g": Category.grains, "m": Category.meat, "x": Category.misc]
        for line in DraftData.drafts.split(separator: "\n") {
            let f = line.split(separator: "|", maxSplits: 4, omittingEmptySubsequences: false).map(String.init)
            guard f.count == 5 else { continue }
            let ingredients: [Ingredient] = f[3].split(separator: ";").compactMap { raw in
                var text = raw.trimmingCharacters(in: .whitespaces)
                guard !text.isEmpty else { return nil }
                var cat = Category.misc
                if let tilde = text.lastIndex(of: "~") {
                    cat = cats[String(text[text.index(after: tilde)...])] ?? Category.misc
                    text = String(text[..<tilde])
                }
                var amount = ""
                var name = text
                if let colon = text.firstIndex(of: ":") {
                    amount = String(text[..<colon]).trimmingCharacters(in: .whitespaces)
                    name = String(text[text.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
                }
                return Ingredient(name: name, quantity: 1, amount: amount, category: cat)
            }
            let steps = f[4].components(separatedBy: " // ").map { $0.trimmingCharacters(in: .whitespaces) }
            out[f[0]] = Draft(minutes: Int(f[1]) ?? 0, servings: Int(f[2]) ?? 1, ingredients: ingredients, steps: steps)
        }
        return out
    }()

    static func flag(for countryName: String) -> String {
        guard let c = DatabaseData.countries.first(where: { $0.name == countryName }) else { return "🌍" }
        return c.emojiFlag ?? c.imageEmoji
    }

    // MARK: Keyword tables

    private static let meatWords = ["chicken", "beef", "pork", "lamb", "mutton", "duck", "fish", "salmon", "tuna", "shrimp",
                                    "prawn", "squid", "octopus", "crab", "mince", "sausage", "bacon", "ham", "anchov",
                                    "turkey", "veal", "sardine", "cod", "bonito", "chorizo", "prosciutto", "pancetta",
                                    "guanciale", "goat", "oxtail", "liver", "mussel", "clam", "lobster", "steak", "brisket"]
    private static let dairyWords = ["milk", "cheese", "mozzarella", "parmesan", "parmigiano", "pecorino", "butter", "cream",
                                     "yogurt", "yoghurt", "egg", "ricotta", "mascarpone", "feta", "ghee", "paneer", "custard"]
    private static let grainWords = ["flour", "rice", "pasta", "spaghetti", "noodle", "bread", "oats", "quinoa", "couscous",
                                     "lentil", "chickpea", "bean", "semolina", "cornmeal", "masa", "tortilla", "bulgur",
                                     "dough", "macaroni", "lasagne", "breadcrumb", "panko", "polenta", "barley", "millet",
                                     "pea", "bun", "pita", "wrapper"]
    private static let produceWords = ["tomato", "onion", "garlic", "potato", "carrot", "pepper", "chilli", "chili", "lemon",
                                       "lime", "basil", "parsley", "herb", "cabbage", "spinach", "cucumber", "aubergine",
                                       "eggplant", "zucchini", "courgette", "mushroom", "apple", "banana", "mango", "avocado",
                                       "ginger", "coriander", "cilantro", "mint", "leek", "celery", "pumpkin", "cassava",
                                       "plantain", "corn", "lettuce", "scallion", "shallot", "radish", "beet", "squash",
                                       "pineapple", "orange", "berry", "dill", "thyme", "rosemary", "oregano", "sage", "okra",
                                       "kale", "broccoli", "cauliflower", "turnip", "yam", "taro", "papaya", "guava", "sprout"]
    private static let miscOverrides = ["peanut", "coconut", "almond milk", "soy", "sesame", "stock", "broth", "sauce", "paste"]

    private static let porkWords = ["pork", "bacon", "ham", "prosciutto", "pancetta", "guanciale", "lard", "chorizo",
                                    "salami", "speck", "sausage"]
    private static let alcoholWords = ["wine", "beer", "rum", "sake", "mirin", "brandy", "whisky", "whiskey", "vodka",
                                       "liqueur", "sherry", "cider", "marsala", "cachaça", "pisco"]
    private static let histamineWords = ["tomato", "vinegar", "wine", "soy sauce", "miso", "kimchi", "parmesan", "parmigiano",
                                         "pecorino", "anchov", "bacon", "ham", "prosciutto", "salami", "sauerkraut",
                                         "fish sauce", "pickle", "fermented", "beer"]
    private static let fructoseWords = ["honey", "apple", "pear", "mango", "agave", "raisin", "fig", "date", "grape"]
    private static let sorbitolWords = ["plum", "prune", "apricot", "peach", "cherry", "nectarine"]
    private static let caffeineWords = ["coffee", "espresso", "cocoa", "chocolate", "matcha", "tea leaves"]

    private static func has(_ text: String, _ words: [String]) -> Bool { words.contains { text.contains($0) } }

    private static func shoppingCategory(_ name: String) -> String {
        let n = name.lowercased()
        if has(n, miscOverrides) && !has(n, ["chicken stock", "beef stock"]) { return Category.misc }
        if has(n, meatWords) { return Category.meat }
        if has(n, dairyWords) { return Category.dairy }
        if has(n, grainWords) { return Category.grains }
        if has(n, produceWords) { return Category.produce }
        return Category.misc
    }

    private static func mealTypes(_ category: String) -> [MealType] {
        switch category {
        case "breakfast": return [.breakfast]
        case "bread": return [.breakfast, .snack]
        case "dessert", "snack": return [.snack]
        default: return [.lunch, .dinner]
        }
    }

    private static func amountText(_ i: WTIngredient) -> String {
        guard let q = i.quantity else { return i.notes ?? "" }
        let number = q == q.rounded() ? String(Int(q)) : String(format: "%g", q)
        let unit = (i.unit ?? "").trimmingCharacters(in: .whitespaces)
        return unit.isEmpty ? number : "\(number) \(unit)"
    }

    private static func label(_ category: String) -> String {
        let t = category.replacingOccurrences(of: "-", with: " ")
        return t.prefix(1).uppercased() + t.dropFirst()
    }

    // MARK: Mapping

    private static func make(_ r: WTRecipe) -> Recipe {
        let country = countriesById[r.countryId]
        let area = country.flatMap { areasById[$0.areaId] }
        let verified = r.isComplete
        let tags = tagTable[r.id]
        let draft = verified ? nil : draftTable[r.id]

        var ingredients: [Ingredient] = (r.ingredients ?? [])
            .sorted { ($0.displayOrder ?? 0) < ($1.displayOrder ?? 0) }
            .map { Ingredient(name: $0.name, quantity: 1, amount: amountText($0), category: shoppingCategory($0.name)) }
        var steps = (r.steps ?? []).sorted { $0.stepNumber < $1.stepNumber }.map(\.instruction)
        var minutes = r.totalTimeMinutes ?? ((r.prepTimeMinutes ?? 0) + (r.cookingTimeMinutes ?? 0))
        var servings = r.servings
        if let draft {
            ingredients = draft.ingredients
            steps = draft.steps
            minutes = draft.minutes
            servings = draft.servings
        }
        let hasContent = verified || draft != nil

        let names = ingredients.map { $0.name.lowercased() }.joined(separator: " | ")
        let allergyText = (r.allergens ?? []).joined(separator: " ").lowercased()
        let title = r.name.lowercased()

        var allergens = tags?.allergens ?? []
        var intolerances = tags?.intolerances ?? []
        var diets = tags?.diets ?? []
        var goals = tags?.goals ?? []
        var vibes = Set<String>()

        if verified {
            // Safety net: never lose an allergen the database itself mentions.
            if has(allergyText, ["gluten", "wheat"]) { allergens.insert("Wheat"); intolerances.insert("Gluten") }
            if has(allergyText, ["dairy", "milk", "butter", "cheese", "cream", "yogurt", "parmigiano", "mozzarella"]) {
                allergens.insert("Milk"); intolerances.insert("Lactose")
            }
            if allergyText.contains("egg") { allergens.insert("Eggs") }
            if allergyText.contains("peanut") { allergens.insert("Peanuts") }
            if has(allergyText, ["tree nut", "almond", "walnut", "hazelnut", "cashew", "pistachio", "pecan"]) { allergens.insert("Tree Nuts") }
            if allergyText.contains("soy") { allergens.insert("Soy") }
            if has(allergyText, ["fish", "anchov", "bonito"]) { allergens.insert("Fish") }
            if has(allergyText, ["shellfish", "shrimp", "prawn", "crab", "crustacean", "mollus"]) { allergens.insert("Shellfish") }
            if allergyText.contains("sesame") { allergens.insert("Sesame") }
            if has(allergyText, ["sulphite", "sulfite"]) { intolerances.insert("Sulfites") }
            let labels = r.dietaryLabels ?? []
            if labels.contains("vegan") { diets.formUnion(["Vegan", "Vegetarian"]) }
            if labels.contains("vegetarian") { diets.insert("Vegetarian") }
        }
        if hasContent {
            if tags == nil {
                if has(names, histamineWords) { intolerances.insert("Histamine") }
                if has(names, fructoseWords) { intolerances.insert("Fructose") }
                if has(names, sorbitolWords) { intolerances.insert("Sorbitol") }
                if has(names, caffeineWords) { intolerances.insert("Caffeine") }
                if !has(names + " " + title, porkWords) && !has(names + " " + title, alcoholWords) { diets.insert("Halal") }
            }
            if minutes > 0 && minutes <= 30 { goals.insert("Save Time") }
            goals.insert("Try News")
            if goals.contains("Eat Healthier") { vibes.insert("Healthy") }
            if r.category == "soup" || has(title, ["stew", "lasagne", "bourguignon", "coq", "pie", "curry", "risotto", "carbonara", "chowder", "feijoada", "locro"]) {
                vibes.insert("Comfort food")
            }
            if servings >= 4 { vibes.insert("Family Friendly") }
        }

        var hash = 0
        for u in r.countryId.unicodeScalars { hash = (hash &* 31 &+ Int(u.value)) % 1000 }

        var recipe = Recipe(id: r.id, name: r.name, minutes: hasContent ? minutes : 0, tag: label(r.category),
                            servings: servings, emoji: r.imageEmoji, hue: Double(hash % 100) / 100,
                            blurb: r.description, verified: verified, sourceUrl: r.sourceUrl,
                            meals: mealTypes(r.category), ingredients: ingredients, steps: steps)
        recipe.draft = draft != nil
        recipe.allergens = allergens
        recipe.intolerances = intolerances
        recipe.diets = diets
        recipe.goals = goals
        recipe.vibes = vibes
        recipe.costPerServing = tags?.cost ?? 3
        recipe.region = area?.name ?? ""
        recipe.country = country?.name ?? ""
        return recipe
    }
}
