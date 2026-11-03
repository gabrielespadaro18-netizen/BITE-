import SwiftUI
import Combine

final class AppState: ObservableObject {
    @Published var profile: UserProfile { didSet { save() } }
    @Published var pantry: [PantryItem] { didSet { save() } }
    @Published var shopping: [ShoppingItem] { didSet { save() } }
    /// dayKey -> meal name -> recipe ids
    @Published var plan: [String: [String: [String]]] { didSet { save() } }

    private static let storeKey = "bite.state.v1"

    private struct Snapshot: Codable {
        var profile: UserProfile
        var pantry: [PantryItem]
        var shopping: [ShoppingItem]
        var plan: [String: [String: [String]]]
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storeKey),
           let s = try? JSONDecoder().decode(Snapshot.self, from: data) {
            profile = s.profile
            pantry = s.pantry
            shopping = s.shopping
            plan = s.plan
        } else {
            profile = UserProfile()
            pantry = SeedData.pantry
            shopping = SeedData.shopping
            plan = [:]
        }
    }

    private func save() {
        let snap = Snapshot(profile: profile, pantry: pantry, shopping: shopping, plan: plan)
        if let data = try? JSONEncoder().encode(snap) {
            UserDefaults.standard.set(data, forKey: Self.storeKey)
        }
    }

    func resetAll() {
        profile = UserProfile()
        pantry = SeedData.pantry
        shopping = SeedData.shopping
        plan = [:]
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

    func recommended(for meal: MealType? = nil) -> [Recipe] {
        let p = profile
        let maxMinutes = [15, 30, 999][p.cookTime ?? 2]
        let safe = Recipe.all.filter { r in
            r.intolerances.isDisjoint(with: p.intolerances)
                && r.allergens.isDisjoint(with: p.allergies)
                && (p.diet == Options.noPreferences || p.diet == "Halal" || r.diets.contains(p.diet))
        }
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
}
