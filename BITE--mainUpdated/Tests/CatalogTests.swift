import Foundation

// Compile with Models, WorldTableData, DraftData, Catalog, SimpleRecipes and this test.
@main struct CatalogTests {
    static func main() throws {
        precondition(Catalog.recipes.count == 90)
        precondition(Catalog.recipes.filter(\.verified).count == 22)
        let simpleURL = URL(fileURLWithPath: CommandLine.arguments[1])
        let simple = try JSONDecoder().decode([Recipe].self, from: Data(contentsOf: simpleURL))
        precondition(simple.count == 66)
        precondition(simple.allSatisfy { !$0.verified && $0.draft })
        let recipes = Catalog.recipes + simple
        precondition(Set(recipes.map(\.id)).count == recipes.count, "Unique stable IDs")
        let countries = Dictionary(grouping: recipes, by: \.country)
        precondition(countries.count == 18)
        precondition(countries.values.allSatisfy { $0.count >= 8 })
        precondition(recipes.allSatisfy { !$0.ingredients.isEmpty && !$0.steps.isEmpty })
        print("PASS: catalog has \(recipes.count) recipes, at least 8 per country, 22 verified")
    }
}
