import Foundation

/// Small, explicitly written cooking patterns. These are NOT LLM outputs and are unverified
/// draft recipes. A suggestion is shown only if every ingredient is actually in the pantry.
enum PantryTemplates {
    static let all: [Recipe] = [
        make("tomato-egg", "Tomato & egg skillet", 15, [.breakfast, .lunch],
             ["Eggs", "Tomatoes"],
             ["Chop the tomatoes and warm them in a nonstick skillet until softened.",
              "Beat the eggs, add to the skillet and stir gently until completely set."]),
        make("apple-yogurt", "Apple yogurt bowl", 7, [.breakfast, .snack],
             ["Apples", "Yogurt"],
             ["Wash and dice the apple.", "Stir into yogurt and serve chilled."]),
        make("tomato-toast", "Quick tomato toast", 10, [.breakfast, .snack],
             ["Bread", "Tomatoes"],
             ["Toast the bread until golden.", "Dice fresh tomatoes and spoon onto the toast."]),
        make("banana-oats", "Banana oat porridge", 15, [.breakfast],
             ["Banana", "Rolled oats", "Milk"],
             ["Simmer rolled oats in milk over low heat until soft.",
              "Mash half the banana into the oats and top with the remaining slices."]),
        make("rice-egg", "Rice & egg bowl", 25, [.lunch, .dinner],
             ["Rice", "Eggs"],
             ["Rinse and cook rice in water according to its package instructions.",
              "Boil the eggs until firm, peel and slice. Serve over the rice."]),
        make("potato-egg", "Simple potato omelette", 25, [.lunch, .dinner],
             ["Potatoes", "Eggs"],
             ["Dice potatoes and boil until fully tender.",
              "Beat eggs, add cooked potatoes and cook slowly in a nonstick pan until thoroughly set."]),
        make("fruit-salad", "Apple & banana fruit salad", 8, [.breakfast, .snack],
             ["Apples", "Banana"],
             ["Wash and chop the apple.", "Slice the banana and gently combine before serving."]),
        make("cucumber-tomato", "Cucumber & tomato salad", 8, [.lunch, .snack],
             ["Cucumber", "Tomatoes"],
             ["Wash and dice the cucumber and tomatoes.", "Mix thoroughly and serve fresh."])
    ]

    private static func make(_ id: String, _ name: String, _ minutes: Int,
                             _ meals: [MealType], _ names: [String], _ steps: [String]) -> Recipe {
        let items = names.map { Ingredient(name: $0, quantity: 1, amount: "", category: Category.misc) }
        var r = Recipe(id: "pantry-\(id)", name: name, minutes: minutes,
                       tag: "From Pantry", servings: 2, emoji: "🥗", hue: 0.28,
                       blurb: "A simple idea made for common pantry ingredients.",
                       verified: false, sourceUrl: nil, meals: meals, ingredients: items, steps: steps)
        r.draft = true
        r.goals = ["Save Time"]
        return r
    }
}
