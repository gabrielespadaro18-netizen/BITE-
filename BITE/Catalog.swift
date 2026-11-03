import Foundation

/// Adapts the World Table database (`DatabaseData`) to the app's own recipe model.
enum Catalog {
    private static let countriesById: [String: WTCountry] =
        Dictionary(DatabaseData.countries.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
    private static let areasById: [String: WTArea] =
        Dictionary(DatabaseData.areas.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })

    static let recipes: [Recipe] = DatabaseData.recipes.map(make)

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

        let ingredients: [Ingredient] = (r.ingredients ?? [])
            .sorted { ($0.displayOrder ?? 0) < ($1.displayOrder ?? 0) }
            .map { Ingredient(name: $0.name, quantity: 1, amount: amountText($0), category: shoppingCategory($0.name)) }
        let steps = (r.steps ?? []).sorted { $0.stepNumber < $1.stepNumber }.map(\.instruction)

        let minutes = r.totalTimeMinutes ?? ((r.prepTimeMinutes ?? 0) + (r.cookingTimeMinutes ?? 0))
        let names = ingredients.map { $0.name.lowercased() }.joined(separator: " | ")
        let allergyText = (r.allergens ?? []).joined(separator: " ").lowercased()
        let title = r.name.lowercased()

        var allergens = Set<String>()
        var intolerances = Set<String>()
        var diets = Set<String>()
        var goals = Set<String>()
        var vibes = Set<String>()

        if verified {
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
            if has(allergyText, ["sulphite", "sulfite"]) || has(names, ["wine"]) { intolerances.insert("Sulfites") }
            if has(names, histamineWords) { intolerances.insert("Histamine") }
            if has(names, fructoseWords) { intolerances.insert("Fructose") }
            if has(names, sorbitolWords) { intolerances.insert("Sorbitol") }
            if has(names, caffeineWords) { intolerances.insert("Caffeine") }

            let labels = r.dietaryLabels ?? []
            if labels.contains("vegan") { diets.formUnion(["Vegan", "Vegetarian"]) }
            if labels.contains("vegetarian") { diets.insert("Vegetarian") }
            if !has(names + " " + title, porkWords) && !has(names + " " + title, alcoholWords) { diets.insert("Halal") }

            let meatCount = ingredients.filter { $0.category == Category.meat }.count
            let produceCount = ingredients.filter { $0.category == Category.produce }.count
            let hasGrain = ingredients.contains { $0.category == Category.grains } || names.contains("potato")
            if minutes > 0 && minutes <= 30 { goals.insert("Save Time") }
            goals.insert("Try News")
            if meatCount > 0 || has(names, ["egg", "tofu", "lentil", "chickpea", "bean"]) { goals.insert("High Protein") }
            if !hasGrain { goals.insert("Low Carb") }
            if produceCount >= 3 && r.category != "dessert" { goals.insert("Eat Healthier") }
            if meatCount == 0 { goals.insert("Budget Friendly") }

            if goals.contains("Eat Healthier") { vibes.insert("Healthy") }
            if r.category == "soup" || has(title, ["stew", "lasagne", "bourguignon", "coq", "pie", "curry", "risotto", "carbonara"]) {
                vibes.insert("Comfort food")
            }
            if (r.defaultServings ?? 1) >= 4 { vibes.insert("Family Friendly") }
        }

        var hash = 0
        for u in r.countryId.unicodeScalars { hash = (hash &* 31 &+ Int(u.value)) % 1000 }

        var recipe = Recipe(id: r.id, name: r.name, minutes: verified ? minutes : 0, tag: label(r.category),
                            servings: r.servings, emoji: r.imageEmoji, hue: Double(hash % 100) / 100,
                            blurb: r.description, verified: verified, sourceUrl: r.sourceUrl,
                            meals: mealTypes(r.category), ingredients: ingredients, steps: steps)
        recipe.allergens = allergens
        recipe.intolerances = intolerances
        recipe.diets = diets
        recipe.goals = goals
        recipe.vibes = vibes
        recipe.region = area?.name ?? ""
        recipe.country = country?.name ?? ""
        return recipe
    }
}
