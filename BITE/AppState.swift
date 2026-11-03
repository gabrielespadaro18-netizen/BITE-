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

    private static let storeKey = "bite.state.v1"

    private struct Snapshot: Codable {
        var profile: UserProfile
        var pantry: [PantryItem]
        var shopping: [ShoppingItem]
        var plan: [String: [String: [String]]]
        var recent: [String]?
        var saved: [String]?
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storeKey),
           let s = try? JSONDecoder().decode(Snapshot.self, from: data) {
            profile = s.profile
            pantry = s.pantry
            shopping = s.shopping
            plan = s.plan
            recent = s.recent ?? []
            saved = s.saved ?? []
        } else {
            profile = UserProfile()
            pantry = SeedData.pantry
            shopping = SeedData.shopping
            plan = [:]
            recent = []
            saved = []
        }
    }

    private func save() {
        let snap = Snapshot(profile: profile, pantry: pantry, shopping: shopping, plan: plan, recent: recent, saved: saved)
        if let data = try? JSONEncoder().encode(snap) {
            UserDefaults.standard.set(data, forKey: Self.storeKey)
        }
    }

    func resetAll() {
        profile = UserProfile()
        pantry = SeedData.pantry
        shopping = SeedData.shopping
        plan = [:]
        recent = []
        saved = []
    }

    // MARK: Pantry

    func pantryHas(_ name: String) -> Bool {
        let n = name.lowercased()
        return pantry.contains { item in
            let p = item.name.lowercased()
            return item.amount > 0 && !p.isEmpty && (p.contains(n) || n.contains(p))
        }
    }

    func pantryCount(for recipe: Recipe) -> Int {
        recipe.ingredients.filter { pantryHas($0.name) }.count
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
    /// Catalogue-only entries (not verified) have no allergen or diet data, so they are shown only
    /// when the profile has no restrictions at all, and never in planning or suggestions.
    func safeRecipes(includeUnverified: Bool = false) -> [Recipe] {
        let p = profile
        let hasRestrictions = !p.intolerances.subtracting([Options.noIntolerances]).isEmpty
            || !p.allergies.subtracting([Options.noAllergies]).isEmpty
            || p.diet != Options.noPreferences
        return Recipe.all.filter { r in
            if !r.verified && (!includeUnverified || hasRestrictions) { return false }
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
        return ids.compactMap { Recipe.find($0) }
    }

    func plannedCount(on date: Date) -> Int {
        MealType.allCases.reduce(0) { $0 + planned(on: date, meal: $1).count }
    }

    func addToPlan(_ recipe: Recipe, meal: MealType, date: Date) {
        let key = Self.dayKey(date)
        var day = plan[key] ?? [:]
        var ids = day[meal.rawValue] ?? []
        guard !ids.contains(recipe.id) else { return }
        ids.append(recipe.id)
        day[meal.rawValue] = ids
        plan[key] = day

        for ingredient in recipe.ingredients where !pantryHas(ingredient.name) {
            let already = shopping.contains { !$0.checked && $0.name.lowercased() == ingredient.name.lowercased() }
            if !already {
                shopping.append(ShoppingItem(name: ingredient.name, category: ingredient.category, quantity: ingredient.quantity))
            }
        }
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
                addToPlan(options[d % options.count], meal: meal, date: date)
                count += 1
            }
        }
        return count
    }
}
