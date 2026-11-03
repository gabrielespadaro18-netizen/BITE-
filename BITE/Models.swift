import Foundation

enum MealType: String, CaseIterable, Codable, Identifiable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"

    var id: String { rawValue }
}

enum Category {
    static let produce = "Fruit & Vegetables"
    static let dairy = "Dairy & Eggs"
    static let grains = "Grains & Pasta"
    static let meat = "Fish & Meat"
    static let misc = "Miscellaneous"
    static let all = [produce, dairy, grains, meat, misc]
}

enum Options {
    static let goals: [(label: String, icon: String)] = [
        ("Save Time", "alarm"), ("Eat Healthier", "carrot"),
        ("Budget Friendly", "dollarsign"), ("High Protein", "dumbbell"),
        ("Low Carb", "leaf"), ("Try News", "sparkles")
    ]
    static let noIntolerances = "No Intolerances"
    static let intolerances = ["Fructose", "Gluten", "Histamine", "Sulfites", "Lactose", "Sorbitol", "Caffeine"]
    static let noAllergies = "No Allergies"
    static let allergies = ["Milk", "Eggs", "Tree Nuts", "Peanuts", "Soy", "Fish", "Shellfish", "Wheat", "Sesame"]
    static let noPreferences = "No Preferences"
    static let diets: [(label: String, icon: String)] = [
        (noPreferences, "nosign"), ("Vegetarian", "leaf"), ("Vegan", "carrot"), ("Halal", "fork.knife")
    ]
    static let cookTimes = ["< 15 Min", "15 - 30 Min", "> 30 Min"]
    static let cravings = ["Healthy", "High Protein", "Low Carb", "Comfort food", "Family Friendly"]
    static let weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
}

struct UserProfile: Codable {
    var name = ""
    var goals: Set<String> = []
    var weeklyBudget: Double = 20
    var people = 1
    var cookTime: Int? = nil          // index into Options.cookTimes
    var intolerances: Set<String> = []
    var allergies: Set<String> = []
    var diet = Options.noPreferences
    var onboarded = false
}

struct PantryItem: Identifiable, Codable {
    var id = UUID()
    var name: String
    var amount: Int
    var expiry: Date? = nil
}

struct ShoppingItem: Identifiable, Codable {
    var id = UUID()
    var name: String
    var category: String
    var quantity = 1
    var checked = false
    var amount: String? = nil
}

struct Ingredient: Hashable {
    let name: String
    let quantity: Int        // shopping-list units to add
    let amount: String       // human text, e.g. "500 g"
    let category: String
}

struct Recipe: Identifiable, Hashable {
    let id: String
    let name: String
    let minutes: Int         // 0 when the source has no verified time
    let tag: String
    let servings: Int
    let emoji: String
    let hue: Double
    let blurb: String
    let verified: Bool       // verified by World Table
    var draft = false        // written for the app, not yet verified by World Table
    let sourceUrl: String?
    let meals: [MealType]
    let ingredients: [Ingredient]
    let steps: [String]
    var intolerances: Set<String> = []
    var allergens: Set<String> = []
    var diets: Set<String> = []
    var goals: Set<String> = []
    var costPerServing: Double = 3
    var region = ""
    var country = ""
    var vibes: Set<String> = []
}

extension Recipe {
    /// Has ingredients and steps (verified or draft).
    var hasContent: Bool { verified || draft }

    static let all: [Recipe] = Catalog.recipes

    static func find(_ id: String) -> Recipe? { all.first { $0.id == id } }
}

enum SeedData {
    static var pantry: [PantryItem] {
        [PantryItem(name: "Apples", amount: 5), PantryItem(name: "Chicken breast", amount: 5),
         PantryItem(name: "Eggs", amount: 2), PantryItem(name: "Rice", amount: 5),
         PantryItem(name: "Milk", amount: 1), PantryItem(name: "Tomatoes", amount: 2)]
    }

    static var shopping: [ShoppingItem] {
        [ShoppingItem(name: "Pears", category: Category.produce, checked: true),
         ShoppingItem(name: "Salad", category: Category.produce),
         ShoppingItem(name: "Eggs", category: Category.dairy),
         ShoppingItem(name: "Rice", category: Category.grains),
         ShoppingItem(name: "Spaghetti", category: Category.grains, checked: true)]
    }
}


// MARK: - Navigation values and plan requests

enum Region: String, CaseIterable, Hashable {
    case europe = "Europe", asia = "Asia", africa = "Africa"
    case northAmerica = "North America", southAmerica = "South America", oceania = "Oceania"

    var symbol: String {
        switch self {
        case .europe: return "building.columns.fill"
        case .asia: return "globe.asia.australia.fill"
        case .africa: return "globe.europe.africa.fill"
        case .northAmerica, .southAmerica: return "globe.americas.fill"
        case .oceania: return "globe.central.south.asia.fill"
        }
    }
}

struct RecipeRoute: Hashable {
    let recipe: Recipe
    var meal: MealType? = nil
}

struct CountryRoute: Hashable {
    let region: Region
    let country: String
}

struct DailyRequest: Hashable {
    var minutes: Int? = nil          // index into Options.cookTimes
    var meal: MealType? = nil
    var cravings: Set<String> = []
    var usePantry = true
}

struct WeeklyRequest: Hashable {
    var days = 7
    var meals: [Int: Set<MealType>] = [:]
    var cravings: Set<String> = []
    var usePantry = true

    var chosenMeals: [MealType] {
        MealType.allCases.filter { meal in (0..<days).contains { meals[$0]?.contains(meal) == true } }
    }
}

enum HomeRoute: Hashable {
    case daily(DailyRequest)
    case weekly(WeeklyRequest)
    case all
}
