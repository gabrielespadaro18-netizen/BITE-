import Foundation

@main struct OnboardingAndGlutenFreeTests {
    static func main() throws {
        // Decode a profile saved before the optional onboarding flag existed.
        let legacy = """
        {"name":"Alex","goals":[],"weeklyBudget":20,"people":1,
         "cookTime":null,"intolerances":[],"allergies":[],
         "diet":"No Preferences","onboarded":true}
        """.data(using: .utf8)!
        let profile = try JSONDecoder().decode(UserProfile.self, from: legacy)
        precondition(profile.name == "Alex" && profile.onboarded && !profile.skippedOnboarding)
        var skipped = profile
        skipped.skippedOnboarding = true
        let replay = try JSONDecoder().decode(UserProfile.self, from: JSONEncoder().encode(skipped))
        precondition(replay.skippedOnboarding && replay.onboarded)
        let file = URL(fileURLWithPath: CommandLine.arguments[1])
        let recipes = try JSONDecoder().decode([Recipe].self, from: Data(contentsOf: file))
        let glutenFree = recipes.filter { $0.vibes.contains("Gluten-Free") }
        precondition(glutenFree.count == 12)
        precondition(glutenFree.allSatisfy { $0.draft && !$0.verified && !$0.ingredients.isEmpty && !$0.steps.isEmpty })
        precondition(glutenFree.contains { $0.ingredients.contains { $0.name.contains("gluten-free") } })
        print("PASS: legacy profile decoding / skipped onboarding roundtrip / 12 gluten-free drafts")
    }
}
