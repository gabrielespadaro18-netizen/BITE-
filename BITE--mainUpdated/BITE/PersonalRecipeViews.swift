import SwiftUI

/// Suggestions are ranked by real pantry overlap; no recipe is invented from arbitrary ingredients.
struct PantryIdeasView: View {
    @EnvironmentObject private var app: AppState
    @State private var showCreator = false

    private var ideas: [Recipe] { app.pantryIdeas() }
    private var ready: [Recipe] {
        ideas.filter { $0.tag != "From Pantry" && app.pantryCount(for: $0) == $0.ingredients.count }
    }
    private var almostReady: [Recipe] {
        ideas.filter {
            guard $0.tag != "From Pantry" else { return false }
            let missing = $0.ingredients.count - app.pantryCount(for: $0)
            return missing > 0 && missing <= 2
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Cook from my pantry")
                    .font(.system(size: 28, weight: .bold))
                Text("Find recipes based on foods you actually have. Missing items can be added to your shopping list from the recipe.")
                    .font(.subheadline).foregroundStyle(.secondary)
                Button { showCreator = true } label: {
                    Label("Create my own recipe", systemImage: "plus")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 48)
                        .background(Capsule().fill(Color.biteGreen))
                }
                if app.pantry.isEmpty {
                    ContentUnavailableView("Your pantry is empty", systemImage: "carrot",
                        description: Text("Add food manually or scan a receipt to discover recipes."))
                        .padding(.top, 30)
                } else {
                    let generated = app.generatedPantryIdeas()
                    if !generated.isEmpty {
                        Text("Made for your pantry").font(.system(size: 17, weight: .bold))
                        Text("These simple draft ideas use only your listed foods. Review the ingredients and instructions before cooking.")
                            .font(.footnote).foregroundStyle(.secondary)
                        ForEach(generated) { recipe in
                            VStack(spacing: 6) {
                                NavigationLink(value: RecipeRoute(recipe: recipe)) { RecipeCard(recipe: recipe) }
                                    .buttonStyle(.plain)
                                Button {
                                    app.savePantryTemplate(recipe)
                                } label: {
                                    Label(app.personalRecipes.contains(where: { $0.name == recipe.name })
                                          ? "Saved to my recipes" : "Save as my own recipe",
                                          systemImage: "bookmark")
                                }
                                .font(.footnote)
                                .foregroundStyle(Color.biteGreen)
                                .disabled(app.personalRecipes.contains(where: { $0.name == recipe.name }))
                            }
                        }
                    }
                    section("Ready with what you have", recipes: ready)
                    section("Missing only 1–2 ingredients", recipes: almostReady)
                    if ready.isEmpty && almostReady.isEmpty {
                        ContentUnavailableView("No close matches yet", systemImage: "fork.knife",
                            description: Text("Add more ingredients to your pantry or make your own recipe."))
                    }
                }
                if !app.personalRecipes.isEmpty {
                    section("Your own recipes", recipes: app.personalRecipes)
                }
            }
            .padding(20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: RecipeRoute.self) { RecipeDetailView(route: $0) }
        .sheet(isPresented: $showCreator) { CreatePersonalRecipeView() }
    }

    @ViewBuilder
    private func section(_ title: String, recipes: [Recipe]) -> some View {
        if !recipes.isEmpty {
            Text(title).font(.system(size: 17, weight: .bold))
            ForEach(recipes) { recipe in
                NavigationLink(value: RecipeRoute(recipe: recipe)) {
                    RecipeCard(recipe: recipe)
                }.buttonStyle(.plain)
            }
        }
    }
}

struct CreatePersonalRecipeView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: FocusField?
    @State private var title = ""
    @State private var minutes = 20
    @State private var servings = 2
    @State private var meal: MealType = .lunch
    @State private var chosen: Set<UUID> = []
    @State private var manualIngredients: [EditableIngredient] = [EditableIngredient()]
    @State private var stepsText = ""

    private enum FocusField: Hashable { case name, ingredient(UUID) }
    private struct EditableIngredient: Identifiable {
        let id = UUID()
        var name = ""
        var amount = ""
    }

    private var steps: [String] {
        stepsText.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    private var ingredients: [Ingredient] {
        let fromPantry = app.pantry.filter { chosen.contains($0.id) }
            .map { Ingredient(name: $0.name, quantity: 1, amount: "", category: Category.misc) }
        let custom = manualIngredients.compactMap { item -> Ingredient? in
            let name = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            return Ingredient(name: name, quantity: 1,
                              amount: item.amount.trimmingCharacters(in: .whitespacesAndNewlines),
                              category: Category.misc)
        }
        let combined = fromPantry + custom
        // Avoid duplicated items when user types the same food as a pantry choice.
        var seen = Set<String>()
        return combined.filter { seen.insert($0.name.lowercased()).inserted }
    }
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !ingredients.isEmpty && !steps.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Recipe details") {
                    TextField("Recipe name", text: $title)
                        .focused($focused, equals: .name)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .accessibilityIdentifier("personalRecipeName")
                    Picker("Meal", selection: $meal) {
                        ForEach(MealType.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Stepper("Cooking time: \(minutes) min", value: $minutes, in: 5...240, step: 5)
                    Stepper("Servings: \(servings)", value: $servings, in: 1...12)
                }
                Section {
                    ForEach($manualIngredients) { $ingredient in
                        HStack(spacing: 9) {
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Ingredient name", text: $ingredient.name)
                                    .focused($focused, equals: .ingredient(ingredient.id))
                                    .textInputAutocapitalization(.sentences)
                                TextField("Amount (optional), e.g. 200 g", text: $ingredient.amount)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Button {
                                manualIngredients.removeAll { $0.id == ingredient.id }
                                if manualIngredients.isEmpty { manualIngredients.append(EditableIngredient()) }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Remove ingredient")
                        }
                    }
                    Button {
                        let new = EditableIngredient()
                        manualIngredients.append(new)
                        focused = .ingredient(new.id)
                    } label: {
                        Label("Add ingredient", systemImage: "plus.circle.fill")
                    }
                    .accessibilityIdentifier("addManualIngredient")
                } header: { Text("Ingredients") }
                  footer: { Text("Type any ingredients you need. Your pantry is completely optional.") }

                if !app.pantry.isEmpty {
                    Section("Also use ingredients from my pantry (optional)") {
                        ForEach(app.pantry) { item in
                            Button {
                                if !chosen.insert(item.id).inserted { chosen.remove(item.id) }
                            } label: {
                                HStack {
                                    Image(systemName: chosen.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(Color.biteGreen)
                                    Text(item.name).foregroundStyle(.primary)
                                    Spacer()
                                    Text("×\(item.amount)").foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                Section("Steps · one per line") {
                    TextEditor(text: $stepsText)
                        .frame(minHeight: 140)
                        .accessibilityIdentifier("personalRecipeSteps")
                        .accessibilityLabel("Recipe preparation steps")
                }
                Section {
                    Text("Personal recipes are saved on this iPhone. Ingredient and allergen safety are not independently verified.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)
            .navigationTitle("My own recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .accessibilityIdentifier("savePersonalRecipe")
                }
            }
            .tint(Color.biteGreen)
        }
    }

    private func save() {
        guard canSave else { return }
        app.addPersonalRecipe(name: title, minutes: minutes, servings: servings,
                              ingredients: ingredients, steps: steps, meals: [meal])
        dismiss()
    }
}
