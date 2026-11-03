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
}

struct Ingredient: Hashable {
    let name: String
    let quantity: Int
    let category: String
}

struct Recipe: Identifiable, Hashable {
    let id: String
    let name: String
    let minutes: Int
    let tag: String
    let servings: Int
    let symbol: String
    let hue: Double
    let meals: [MealType]
    let ingredients: [Ingredient]
    let steps: [String]
    var intolerances: Set<String> = []
    var allergens: Set<String> = []
    var diets: Set<String> = []
    var goals: Set<String> = []
    var costPerServing: Double = 3
}

private func ing(_ name: String, _ qty: Int = 1, _ cat: String) -> Ingredient {
    Ingredient(name: name, quantity: qty, category: cat)
}

extension Recipe {
    static let all: [Recipe] = [
        Recipe(id: "chicken-zucchini-bowl", name: "Chicken & zucchini rice bowl", minutes: 25, tag: "High Protein",
               servings: 2, symbol: "fork.knife", hue: 0.10, meals: [.lunch, .dinner],
               ingredients: [ing("Chicken breast", 1, Category.meat), ing("Rice", 1, Category.grains), ing("Zucchini", 2, Category.produce)],
               steps: ["Season and sear the chicken until golden, then set aside.",
                       "Sauté the zucchini in the pan for 4-5 minutes.",
                       "Add the cooked rice and chicken back, toss and serve warm."],
               diets: ["Halal"], goals: ["High Protein", "Eat Healthier"], costPerServing: 4),
        Recipe(id: "veggie-omelette", name: "Tomato & spinach omelette", minutes: 10, tag: "Quick",
               servings: 1, symbol: "sun.max.fill", hue: 0.12, meals: [.breakfast, .lunch],
               ingredients: [ing("Eggs", 3, Category.dairy), ing("Tomatoes", 1, Category.produce), ing("Spinach", 1, Category.produce)],
               steps: ["Whisk the eggs with a pinch of salt.", "Cook tomatoes and spinach for 2 minutes.", "Pour in the eggs and fold when set."],
               intolerances: ["Histamine"], allergens: ["Eggs"], diets: ["Vegetarian", "Halal"],
               goals: ["Save Time", "Low Carb", "High Protein"], costPerServing: 2),
        Recipe(id: "apple-oats", name: "Overnight oats with apple", minutes: 5, tag: "Make ahead",
               servings: 1, symbol: "cup.and.saucer.fill", hue: 0.08, meals: [.breakfast, .snack],
               ingredients: [ing("Oats", 1, Category.grains), ing("Milk", 1, Category.dairy), ing("Apples", 1, Category.produce)],
               steps: ["Mix oats and milk in a jar.", "Grate in the apple and stir.", "Chill overnight and enjoy cold."],
               intolerances: ["Gluten", "Lactose"], allergens: ["Milk"], diets: ["Vegetarian", "Halal"],
               goals: ["Save Time", "Budget Friendly", "Eat Healthier"], costPerServing: 1.5),
        Recipe(id: "tomato-spaghetti", name: "Simple tomato spaghetti", minutes: 20, tag: "Budget",
               servings: 2, symbol: "fork.knife", hue: 0.02, meals: [.lunch, .dinner],
               ingredients: [ing("Spaghetti", 1, Category.grains), ing("Tomatoes", 4, Category.produce), ing("Garlic", 1, Category.produce)],
               steps: ["Boil the spaghetti until al dente.", "Simmer chopped tomatoes with garlic for 10 minutes.", "Toss the pasta in the sauce and serve."],
               intolerances: ["Gluten", "Histamine"], allergens: ["Wheat"], diets: ["Vegan", "Vegetarian", "Halal"],
               goals: ["Budget Friendly", "Save Time"], costPerServing: 1.2),
        Recipe(id: "yogurt-fruit", name: "Yogurt & fruit bowl", minutes: 5, tag: "Light",
               servings: 1, symbol: "leaf.fill", hue: 0.85, meals: [.breakfast, .snack],
               ingredients: [ing("Greek yogurt", 1, Category.dairy), ing("Apples", 1, Category.produce), ing("Honey", 1, Category.misc)],
               steps: ["Spoon yogurt into a bowl.", "Top with sliced fruit and a drizzle of honey."],
               intolerances: ["Lactose", "Fructose"], allergens: ["Milk"], diets: ["Vegetarian", "Halal"],
               goals: ["Save Time", "Eat Healthier", "High Protein"], costPerServing: 2),
        Recipe(id: "lentil-soup", name: "Red lentil soup", minutes: 35, tag: "Comfort",
               servings: 4, symbol: "flame", hue: 0.05, meals: [.lunch, .dinner],
               ingredients: [ing("Red lentils", 1, Category.grains), ing("Carrots", 2, Category.produce), ing("Onion", 1, Category.produce)],
               steps: ["Sauté diced onion and carrot.", "Add lentils and water, simmer 25 minutes.", "Blend partly and season to taste."],
               diets: ["Vegan", "Vegetarian", "Halal"], goals: ["Budget Friendly", "Eat Healthier", "High Protein"], costPerServing: 1),
        Recipe(id: "salmon-veg", name: "Salmon with roasted veg", minutes: 30, tag: "Low Carb",
               servings: 2, symbol: "fish", hue: 0.55, meals: [.dinner],
               ingredients: [ing("Salmon fillet", 2, Category.meat), ing("Broccoli", 1, Category.produce), ing("Zucchini", 1, Category.produce)],
               steps: ["Heat the oven to 200°C.", "Roast the vegetables for 10 minutes.", "Add the salmon and bake another 12 minutes."],
               allergens: ["Fish"], diets: ["Halal"], goals: ["High Protein", "Low Carb", "Eat Healthier", "Try News"], costPerServing: 6),
        Recipe(id: "pb-banana-toast", name: "Peanut butter banana toast", minutes: 5, tag: "Quick",
               servings: 1, symbol: "sun.max.fill", hue: 0.14, meals: [.breakfast, .snack],
               ingredients: [ing("Bread", 2, Category.grains), ing("Peanut butter", 1, Category.misc), ing("Bananas", 1, Category.produce)],
               steps: ["Toast the bread.", "Spread peanut butter and top with banana slices."],
               intolerances: ["Gluten", "Fructose"], allergens: ["Peanuts", "Wheat"], diets: ["Vegan", "Vegetarian", "Halal"],
               goals: ["Save Time", "Budget Friendly"], costPerServing: 1),
        Recipe(id: "chickpea-salad", name: "Crunchy chickpea salad", minutes: 10, tag: "Fresh",
               servings: 2, symbol: "leaf.fill", hue: 0.30, meals: [.lunch],
               ingredients: [ing("Chickpeas", 1, Category.grains), ing("Cucumber", 1, Category.produce), ing("Tomatoes", 2, Category.produce)],
               steps: ["Drain and rinse the chickpeas.", "Chop cucumber and tomatoes.", "Toss everything with olive oil and lemon."],
               intolerances: ["Histamine"], diets: ["Vegan", "Vegetarian", "Halal"],
               goals: ["Eat Healthier", "Save Time", "Budget Friendly", "Low Carb"], costPerServing: 1.5),
        Recipe(id: "shakshuka", name: "Shakshuka", minutes: 25, tag: "Try something new",
               servings: 2, symbol: "flame", hue: 0.01, meals: [.breakfast, .dinner],
               ingredients: [ing("Eggs", 4, Category.dairy), ing("Tomatoes", 4, Category.produce), ing("Onion", 1, Category.produce)],
               steps: ["Cook onion until soft, add tomatoes and spices.", "Simmer 10 minutes, make wells and crack in the eggs.", "Cover until the whites are set."],
               intolerances: ["Histamine"], allergens: ["Eggs"], diets: ["Vegetarian", "Halal"],
               goals: ["Try News", "Low Carb", "High Protein"], costPerServing: 2.5),
        Recipe(id: "tofu-stirfry", name: "Tofu veggie stir-fry", minutes: 20, tag: "High Protein",
               servings: 2, symbol: "carrot", hue: 0.33, meals: [.lunch, .dinner],
               ingredients: [ing("Tofu", 1, Category.misc), ing("Broccoli", 1, Category.produce), ing("Rice", 1, Category.grains)],
               steps: ["Press and cube the tofu, then pan-fry until crisp.", "Stir-fry the broccoli.", "Combine with soy-free sauce and serve over rice."],
               allergens: ["Soy"], diets: ["Vegan", "Vegetarian", "Halal"],
               goals: ["High Protein", "Try News", "Eat Healthier"], costPerServing: 3),
        Recipe(id: "almond-bites", name: "Almond energy bites", minutes: 15, tag: "Snack",
               servings: 6, symbol: "star.fill", hue: 0.09, meals: [.snack],
               ingredients: [ing("Almonds", 1, Category.misc), ing("Dates", 1, Category.produce), ing("Oats", 1, Category.grains)],
               steps: ["Blitz almonds and dates in a food processor.", "Add oats and pulse to combine.", "Roll into balls and chill."],
               intolerances: ["Gluten", "Fructose"], allergens: ["Tree Nuts"], diets: ["Vegan", "Vegetarian", "Halal"],
               goals: ["Eat Healthier", "Try News"], costPerServing: 1.8)
    ]

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
