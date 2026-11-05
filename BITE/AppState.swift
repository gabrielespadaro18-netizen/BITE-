import SwiftUI
import Combine

final class AppState: ObservableObject {
    @Published var profile: UserProfile { didSet { save() } }
    @Published var pantry: [PantryItem] { didSet { save() } }
    @Published var shopping: [ShoppingItem] { didSet { save() } }
    /// dayKey -> meal name -> recipe ids
    @Published var plan: [String: [String: [String]]] { didSet { save() } }
    @Published var recent: [String] { didSet { save() } }
    @Published var saved: [String] { didSet { save() } }
    @Published var personalRecipes: [Recipe] { didSet { save() } }
    @Published private(set) var remoteRecipes: [Recipe] = []
    @Published private(set) var syncMessage = "Offline catalog"

    /// Recipes from Airtable take precedence; user-created recipes remain local to this device.
    var allRecipes: [Recipe] {
        var index = Dictionary(uniqueKeysWithValues: Recipe.all.map { ($0.id, $0) })
        for recipe in remoteRecipes {
            if recipe.hasContent && !recipe.ingredients.isEmpty && !recipe.steps.isEmpty {
                index[recipe.id] = recipe
            }
        }
        for recipe in personalRecipes { index[recipe.id] = recipe }
        return index.values.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func findRecipe(_ id: String) -> Recipe? { allRecipes.first { $0.id == id } }

    @MainActor
    func refreshRecipes() async {
        guard RecipeAPI.isConfigured else {
            syncMessage = "Local catalog · configure BITE_API_URL for Airtable"
            return
        }
        do {
            let recipes = try await RecipeAPI.fetch()
            remoteRecipes = recipes
            syncMessage = "Airtable synchronized · \(recipes.count) recipes"
        } catch {
            syncMessage = "Offline catalog · \(error.localizedDescription)"
        }
    }

    private static let storeKey = "bite.state.v1"

    private struct Snapshot: Codable {
        var profile: UserProfile
        var pantry: [PantryItem]
        var shopping: [ShoppingItem]
        var plan: [String: [String: [String]]]
        var recent: [String]?
        var saved: [String]?
        var personalRecipes: [Recipe]?
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storeKey),
           let s = try? JSONDecoder().decode(Snapshot.self, from: data) {
            profile = s.profile
            // One-time migration: discard only the exact former demo inventory.
            let legacyDemoPantry = ["Apples", "Chicken breast", "Eggs", "Rice", "Milk", "Tomatoes"]
            let legacyDemoShopping = ["Pears", "Salad", "Eggs", "Rice", "Spaghetti"]
            let wasUntouchedDemo = s.pantry.map(\.name) == legacyDemoPantry
                && s.shopping.map(\.name) == legacyDemoShopping
                && s.plan.isEmpty && (s.recent ?? []).isEmpty
            pantry = wasUntouchedDemo ? [] : s.pantry
            shopping = wasUntouchedDemo ? [] : s.shopping
            plan = s.plan
            recent = s.recent ?? []
            saved = s.saved ?? []
            personalRecipes = s.personalRecipes ?? []
        } else {
            profile = UserProfile()
            pantry = []
            shopping = []
            plan = [:]
            recent = []
            saved = []
            personalRecipes = []
        }
    }

    private func save() {
        let snap = Snapshot(profile: profile, pantry: pantry, shopping: shopping, plan: plan, recent: recent,
                            saved: saved, personalRecipes: personalRecipes)
        if let data = try? JSONEncoder().encode(snap) {
            UserDefaults.standard.set(data, forKey: Self.storeKey)
        }
    }

    func resetAll() {
        profile = UserProfile()
        pantry = []
        shopping = []
        plan = [:]
        recent = []
        saved = []
        personalRecipes = []
    }

    // MARK: Pantry

    func pantryHas(_ name: String) -> Bool {
        let n = Self.ingredientKey(name)
        guard !n.isEmpty else { return false }
        return pantry.contains { item in
            guard item.amount > 0 else { return false }
            let p = Self.ingredientKey(item.name)
            guard !p.isEmpty else { return false }
            // Do not mistake plant milks for milk or different varieties of milk.
            if (p == "milk" && (n.contains("almond") || n.contains("coconut") || n.contains("soy"))) ||
                (n == "milk" && (p.contains("almond") || p.contains("coconut") || p.contains("soy"))) { return false }
            return p == n || (p.count >= 4 && (n.contains(p) || p.contains(n)))
        }
    }

    private static func ingredientKey(_ value: String) -> String {
        var s = value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased().replacingOccurrences(of: "-", with: " ")
        // Normalize only obvious plural forms, not arbitrary words.
        for (a, b) in [("eggs", "egg"), ("tomatoes", "tomato"), ("potatoes", "potato"),
                       ("apples", "apple"), ("carrots", "carrot"), ("onions", "onion") ] {
            s = s.replacingOccurrences(of: a, with: b)
        }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func pantryCount(for recipe: Recipe) -> Int {
        recipe.ingredients.filter { pantryHas($0.name) }.count
    }

    /// Strict matching for cooking from selected pantry ingredients, not fuzzy search.
    func cookableRecipes(selectedPantryIDs: Set<UUID>) -> [Recipe] {
        let available = pantry.filter { selectedPantryIDs.contains($0.id) && $0.amount > 0 }
        guard !available.isEmpty else { return [] }
        let matching = safeRecipes(includeUnverified: true) + generatedPantryIdeas()
        var seen = Set<String>()
        return matching.filter { recipe in
            guard seen.insert(recipe.id).inserted else { return false }
            return PantryEligibility.canCook(
                ingredients: recipe.ingredients.map(\.name),
                available: available.map(\.name))
        }.sorted { $0.minutes < $1.minutes }
    }

    func addPantry(name: String, amount: Int, expiry: Date?) {
        let clean = name.trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty else { return }
        if let i = pantry.firstIndex(where: { $0.name.lowercased() == clean.lowercased() }) {
            pantry[i].amount += amount
            if let expiry { pantry[i].expiry = expiry }
        } else {
            pantry.append(PantryItem(name: clean, amount: amount, expiry: expiry))
        }
    }

    // MARK: Shopping

    func addShopping(name: String, category: String, quantity: Int = 1) {
        let clean = name.trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty else { return }
        shopping.append(ShoppingItem(name: clean, category: category, quantity: quantity))
    }

    /// Ticked off in the shopping list (bought, not yet moved to the pantry).
    func isBought(_ name: String) -> Bool {
        shopping.contains { $0.checked && $0.name.lowercased() == name.lowercased() }
    }

    func isInShopping(_ name: String) -> Bool {
        shopping.contains { !$0.checked && $0.name.lowercased() == name.lowercased() }
    }

    /// Adds the ingredient to the shopping list, or removes it again if it is already there.
    func toggleShopping(ingredient: Ingredient) {
        if let i = shopping.firstIndex(where: { !$0.checked && $0.name.lowercased() == ingredient.name.lowercased() }) {
            shopping.remove(at: i)
        } else {
            shopping.append(ShoppingItem(name: ingredient.name, category: ingredient.category, quantity: ingredient.quantity,
                                         amount: ingredient.amount.isEmpty ? nil : ingredient.amount))
        }
    }

    func toggleShopping(_ item: ShoppingItem) {
        guard let i = shopping.firstIndex(where: { $0.id == item.id }) else { return }
        shopping[i].checked.toggle()
    }

    /// Moves checked items into the pantry. Returns how many were moved.
    @discardableResult
    func finishShopping() -> Int {
        let bought = shopping.filter { $0.checked }
        for item in bought { addPantry(name: item.name, amount: item.quantity, expiry: nil) }
        shopping.removeAll { $0.checked }
        return bought.count
    }

    // MARK: Recipes

    /// Recipes that respect the profile's intolerances, allergies and diet.
    /// Draft and catalogue-only entries are not verified, so they are only offered when the profile has no restrictions.
    /// Catalogue-only entries (no ingredients) never appear in planning or suggestions.
    func safeRecipes(includeUnverified: Bool = false) -> [Recipe] {
        let p = profile
        let hasRestrictions = !p.intolerances.subtracting([Options.noIntolerances]).isEmpty
            || !p.allergies.subtracting([Options.noAllergies]).isEmpty
            || p.diet != Options.noPreferences
        return allRecipes.filter { r in
            guard r.hasContent && !r.ingredients.isEmpty else { return false }
            if !r.verified {
                // Drafts were not checked by World Table: only offer them to people with no restrictions.
                if r.draft { if hasRestrictions { return false } }
                else if !includeUnverified || hasRestrictions { return false }
            }
            return r.intolerances.isDisjoint(with: p.intolerances)
                && r.allergens.isDisjoint(with: p.allergies)
                && (p.diet == Options.noPreferences || r.diets.contains(p.diet))
        }
    }

    func recommended(for meal: MealType? = nil) -> [Recipe] {
        let p = profile
        let maxMinutes = [15, 30, 999][p.cookTime ?? 2]
        let safe = safeRecipes()
        let quick = safe.filter { $0.minutes <= maxMinutes }
        let pool = quick.count >= 3 ? quick : safe
        let perMeal = max(p.weeklyBudget / Double(max(p.people, 1)) / 14, 0)
        func score(_ r: Recipe) -> Double {
            Double(r.goals.intersection(p.goals).count) * 2
                + Double(pantryCount(for: r))
                + (r.costPerServing <= perMeal ? 1 : 0)
        }
        let sorted = pool.sorted { score($0) > score($1) }
        guard let meal else { return sorted }
        return sorted.filter { $0.meals.contains(meal) }
    }

    private func matches(_ recipe: Recipe, craving: String) -> Bool {
        switch craving {
        case "Healthy": return recipe.goals.contains("Eat Healthier")
        case "High Protein": return recipe.goals.contains("High Protein")
        case "Low Carb": return recipe.goals.contains("Low Carb")
        default: return recipe.vibes.contains(craving)
        }
    }

    /// Recipes for the "Plan Daily" sheet (also reused per meal by the weekly plan).
    func recipes(matching request: DailyRequest) -> [Recipe] {
        var pool = safeRecipes()
        if let meal = request.meal { pool = pool.filter { $0.meals.contains(meal) } }
        if let t = request.minutes {
            let limit = [15, 30, 999][t]
            pool = pool.filter { $0.minutes <= limit }
        }
        if !request.cravings.isEmpty {
            pool = pool.filter { r in request.cravings.contains { matches(r, craving: $0) } }
        }
        let ranked = pool.enumerated().map { (index: $0.offset, recipe: $0.element) }
        return ranked.sorted { a, b in
            if request.usePantry {
                let ca = pantryCount(for: a.recipe), cb = pantryCount(for: b.recipe)
                if ca != cb { return ca > cb }
            }
            return a.index < b.index
        }.map { $0.recipe }
    }

    func search(_ query: String) -> [Recipe] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }
        return safeRecipes(includeUnverified: true).filter {
            $0.name.localizedCaseInsensitiveContains(q) || $0.country.localizedCaseInsensitiveContains(q)
                || $0.tag.localizedCaseInsensitiveContains(q)
                || $0.ingredients.contains { $0.name.localizedCaseInsensitiveContains(q) }
        }
    }

    func addRecent(_ recipe: Recipe) {
        recent.removeAll { $0 == recipe.id }
        recent.insert(recipe.id, at: 0)
        if recent.count > 8 { recent.removeLast(recent.count - 8) }
    }

    func toggleSaved(_ recipe: Recipe) {
        if saved.contains(recipe.id) { saved.removeAll { $0 == recipe.id } } else { saved.append(recipe.id) }
    }

    // MARK: Personal recipes and pantry-based suggestions

    func addPersonalRecipe(name: String, minutes: Int, servings: Int,
                           ingredients: [Ingredient], steps: [String], meals: [MealType]) {
        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty && !ingredients.isEmpty && !steps.isEmpty && !meals.isEmpty else { return }
        var r = Recipe(id: "personal-\(UUID().uuidString)", name: title,
                       minutes: max(1, minutes), tag: "Personal", servings: max(1, servings),
                       emoji: "🍽️", hue: 0.31, blurb: "Your own recipe",
                       verified: false, sourceUrl: nil, meals: meals, ingredients: ingredients, steps: steps)
        r.draft = true   // User supplied; dietary safety must never be assumed.
        personalRecipes.append(r)
    }

    func savePantryTemplate(_ template: Recipe) {
        guard !personalRecipes.contains(where: { $0.name == template.name }) else { return }
        addPersonalRecipe(name: template.name, minutes: template.minutes,
                          servings: template.servings, ingredients: template.ingredients,
                          steps: template.steps, meals: template.meals)
    }

    func generatedPantryIdeas() -> [Recipe] {
        // These drafts are not vetted for allergies or dietary restrictions.
        let hasRestrictions = !profile.allergies.subtracting([Options.noAllergies]).isEmpty
            || !profile.intolerances.subtracting([Options.noIntolerances]).isEmpty
            || profile.diet != Options.noPreferences
        guard !hasRestrictions else { return [] }
        return PantryTemplates.all.filter { recipe in
            recipe.ingredients.allSatisfy { pantryHas($0.name) }
        }
    }

    func deletePersonalRecipe(_ id: String) {
        personalRecipes.removeAll { $0.id == id }
        saved.removeAll { $0 == id }
        recent.removeAll { $0 == id }
        for key in Array(plan.keys) {
            guard var day = plan[key] else { continue }
            for meal in Array(day.keys) { day[meal]?.removeAll { $0 == id } }
            plan[key] = day
        }
    }

    /// Recipes using pantry foods; "ready" requires every listed ingredient to be available.
    func pantryIdeas() -> [Recipe] {
        guard !pantry.isEmpty else { return [] }
        return safeRecipes().filter { !$0.ingredients.isEmpty && pantryCount(for: $0) > 0 }
            .sorted { a, b in
                let missingA = a.ingredients.count - pantryCount(for: a)
                let missingB = b.ingredients.count - pantryCount(for: b)
                if missingA != missingB { return missingA < missingB }
                return a.minutes < b.minutes
            }
    }

    // MARK: Suggestions

    /// One pick from the matches, favouring the best-ranked ones; avoids repeats until the pool runs out.
    func suggestion(from pool: [Recipe], excluding seen: Set<String> = []) -> Recipe? {
        let fresh = pool.filter { !seen.contains($0.id) }
        return (fresh.isEmpty ? pool : fresh).prefix(3).randomElement()
    }

    // MARK: Plan

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func dayKey(_ date: Date) -> String { dayFormatter.string(from: date) }

    func planned(on date: Date, meal: MealType) -> [Recipe] {
        let ids = plan[Self.dayKey(date)]?[meal.rawValue] ?? []
        return ids.compactMap { findRecipe($0) }
    }

    func plannedCount(on date: Date) -> Int {
        MealType.allCases.reduce(0) { $0 + planned(on: date, meal: $1).count }
    }

    /// Adds a recipe only if the meal has capacity; returns true on success.
    @discardableResult
    func addToPlan(_ recipe: Recipe, meal: MealType, date: Date) -> Bool {
        let key = Self.dayKey(date)
        var day = plan[key] ?? [:]
        var ids = day[meal.rawValue] ?? []
        guard !ids.contains(recipe.id), ids.count < meal.dailyLimit else { return false }
        ids.append(recipe.id)
        day[meal.rawValue] = ids
        plan[key] = day

        for ingredient in recipe.ingredients where !pantryHas(ingredient.name) {
            let already = shopping.contains { !$0.checked && $0.name.lowercased() == ingredient.name.lowercased() }
            if !already {
                shopping.append(ShoppingItem(name: ingredient.name, category: ingredient.category, quantity: ingredient.quantity,
                                             amount: ingredient.amount.isEmpty ? nil : ingredient.amount))
            }
        }
        return true
    }

    func removeFromPlan(_ recipe: Recipe, meal: MealType, date: Date) {
        let key = Self.dayKey(date)
        guard var day = plan[key] else { return }
        day[meal.rawValue]?.removeAll { $0 == recipe.id }
        plan[key] = day
    }

    /// Fills the plan starting today with one recipe per chosen day/meal. Returns how many meals were added.
    @discardableResult
    func addWeek(_ request: WeeklyRequest, start: Date = Date()) -> Int {
        var count = 0
        for d in 0..<request.days {
            guard let date = Calendar.current.date(byAdding: .day, value: d, to: start) else { continue }
            for meal in MealType.allCases where request.meals[d]?.contains(meal) == true {
                let options = recipes(matching: DailyRequest(minutes: nil, meal: meal,
                                                             cravings: request.cravings, usePantry: request.usePantry))
                guard !options.isEmpty else { continue }
                if addToPlan(options[d % options.count], meal: meal, date: date) {
                    count += 1
                }
            }
        }
        return count
    }
}
