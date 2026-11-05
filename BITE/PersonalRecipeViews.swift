import SwiftUI

/// Only recipes fully achievable with the foods explicitly selected below.
struct PantryIdeasView: View {
    @EnvironmentObject private var app: AppState
    @State private var selectedIDs: Set<UUID> = []
    @State private var didInitialize = false

    private var available: [PantryItem] { app.pantry.filter { $0.amount > 0 } }
    private var cookable: [Recipe] { app.cookableRecipes(selectedPantryIDs: selectedIDs) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Cook with what you have")
                    .font(.system(size: 27, weight: .bold))
                Text("Select the foods you want to use. Only recipes whose entire ingredient list is available will appear.")
                    .font(.subheadline).foregroundStyle(.secondary)
                if available.isEmpty {
                    ContentUnavailableView("Your pantry is empty", systemImage: "refrigerator",
                        description: Text("Add foods manually or scan a receipt from Pantry."))
                } else {
                    HStack {
                        Text("Choose pantry foods").font(.headline)
                        Spacer()
                        Button(selectedIDs.count == available.count ? "Clear" : "Select all") {
                            if selectedIDs.count == available.count { selectedIDs.removeAll() }
                            else { selectedIDs = Set(available.map(\.id)) }
                        }.font(.subheadline).foregroundStyle(Color.biteGreen)
                    }
                    VStack(spacing: 0) {
                        ForEach(available) { item in
                            Button {
                                if !selectedIDs.insert(item.id).inserted { selectedIDs.remove(item.id) }
                            } label: {
                                HStack {
                                    Image(systemName: selectedIDs.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(Color.biteGreen)
                                    Text(item.name).foregroundStyle(.primary)
                                    Spacer()
                                    Text("×\(item.amount)").foregroundStyle(.secondary)
                                }.padding(.vertical, 12).padding(.horizontal, 14)
                            }.buttonStyle(.plain)
                            if item.id != available.last?.id { Divider().padding(.leading, 14) }
                        }
                    }
                    .background(CardBackground(radius: 18))
                    Text("\(cookable.count) recipes using only your selection")
                        .font(.headline)
                    if selectedIDs.isEmpty {
                        ContentUnavailableView("Choose some foods", systemImage: "checklist",
                            description: Text("Select at least one ingredient above."))
                    } else if cookable.isEmpty {
                        ContentUnavailableView("No complete recipes yet", systemImage: "fork.knife",
                            description: Text("Select more foods or add the missing ingredients to your pantry."))
                    } else {
                        ForEach(cookable) { recipe in
                            NavigationLink(value: RecipeRoute(recipe: recipe)) {
                                RecipeCard(recipe: recipe)
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("From my pantry")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: RecipeRoute.self) { RecipeDetailView(route: $0) }
        .onAppear { initializeSelectionIfNeeded() }
        .onChange(of: app.pantry.map(\.id)) { _, current in
            selectedIDs.formIntersection(Set(current))
        }
    }

    private func initializeSelectionIfNeeded() {
        guard !didInitialize else { return }
        selectedIDs = Set(available.map(\.id))
        didInitialize = true
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
