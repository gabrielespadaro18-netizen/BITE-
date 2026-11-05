import Foundation

/// Bundle fallback for simple recipes. Airtable may override these when configured.
enum SimpleRecipes {
    static let all: [Recipe] = {
        guard let url = Bundle.main.url(forResource: "simple_recipes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let recipes = try? JSONDecoder().decode([Recipe].self, from: data) else { return [] }
        return recipes
    }()
}
