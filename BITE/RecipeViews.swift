import SwiftUI

struct RecipeImage: View {
    let recipe: Recipe
    var symbolSize: CGFloat = 34
    var corner: CGFloat = 16

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hue: recipe.hue, saturation: 0.45, brightness: 0.97),
                                    Color(hue: recipe.hue, saturation: 0.7, brightness: 0.78)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: recipe.symbol)
                .font(.system(size: symbolSize, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
        }
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
    }
}

struct RecipeCard: View {
    @EnvironmentObject var app: AppState
    let recipe: Recipe

    var body: some View {
        HStack(spacing: 14) {
            RecipeImage(recipe: recipe).frame(width: 92, height: 80)
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name).font(.system(size: 15, weight: .bold)).foregroundStyle(.black)
                    .multilineTextAlignment(.leading)
                Text("\(recipe.minutes)min · \(recipe.tag)").font(.system(size: 12)).foregroundStyle(.black.opacity(0.75))
                Text("Uses \(app.pantryCount(for: recipe)) \(app.pantryCount(for: recipe) == 1 ? "item" : "items") you already have")
                    .font(.system(size: 11)).foregroundStyle(.black.opacity(0.6))
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.biteMint)
            .shadow(color: .black.opacity(0.12), radius: 6, y: 3))
    }
}

struct RecipesView: View {
    @EnvironmentObject var app: AppState
    @State private var mode = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Here’s what we found").font(.system(size: 22, weight: .bold))
                        Text("Based on your answers").font(.system(size: 13))
                    }
                    Picker("", selection: $mode) {
                        Text("Day").tag(0)
                        Text("Week").tag(1)
                    }
                    .pickerStyle(.segmented)

                    if app.recommended().isEmpty {
                        Text("No recipes match your answers yet. Try relaxing your preferences in your profile.")
                            .font(.subheadline).foregroundStyle(.secondary).padding(.top, 20)
                    } else if mode == 0 {
                        ForEach(app.recommended()) { recipe in
                            NavigationLink(value: recipe) { RecipeCard(recipe: recipe) }.buttonStyle(.plain)
                        }
                    } else {
                        ForEach([MealType.breakfast, .lunch, .dinner]) { meal in
                            Text("\(meal.rawValue) :").font(.system(size: 18, weight: .semibold)).padding(.top, 6)
                            ForEach(app.recommended(for: meal).prefix(3)) { recipe in
                                NavigationLink(value: recipe) { RecipeCard(recipe: recipe) }.buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .navigationDestination(for: Recipe.self) { RecipeDetailView(recipe: $0) }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

struct RecipeDetailView: View {
    @EnvironmentObject var app: AppState
    let recipe: Recipe
    @State private var toast: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RecipeImage(recipe: recipe, symbolSize: 70, corner: 22).frame(height: 220)
                Text(recipe.name).font(.system(size: 20, weight: .bold)).frame(maxWidth: .infinity)

                HStack(spacing: 12) {
                    chip("\(recipe.minutes) min")
                    chip(recipe.tag)
                    chip(recipe.servings == 1 ? "1 Serving" : "\(recipe.servings) Servings")
                }

                Text("Ingredients:").font(.system(size: 16, weight: .semibold))
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(recipe.ingredients, id: \.name) { item in
                        if app.pantryHas(item.name) {
                            Label("\(item.name) - in your pantry", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(Color.biteGreen)
                                .font(.system(size: 15, weight: .semibold))
                                .labelStyle(TintedIcon(color: .biteGreen, text: .black))
                        } else {
                            Label("\(item.name) - buy \(item.quantity)", systemImage: "circle")
                                .font(.system(size: 15, weight: .semibold))
                                .labelStyle(TintedIcon(color: .biteRed, text: .biteRed))
                        }
                    }
                }
                .padding(.leading, 8)

                Text("Steps:").font(.system(size: 16, weight: .semibold))
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                        Text("\(index + 1). \(step)").font(.system(size: 14, weight: .medium))
                    }
                }
                .padding(.leading, 8)
            }
            .padding(16)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(MealType.allCases) { meal in
                        Button(meal.rawValue) { add(to: meal) }
                    }
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(Color.biteGreen))
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let toast {
                Text(toast)
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                    .padding(.horizontal, 18).padding(.vertical, 12)
                    .background(Capsule().fill(Color.biteDark))
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: toast)
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(Capsule().fill(Color.biteMint).shadow(color: .black.opacity(0.1), radius: 4, y: 2))
    }

    private func add(to meal: MealType) {
        app.addToPlan(recipe, meal: meal, date: Date())
        toast = "Added to today’s \(meal.rawValue.lowercased())"
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            toast = nil
        }
    }
}

private struct TintedIcon: LabelStyle {
    let color: Color
    let text: Color

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon.foregroundStyle(color)
            configuration.title.foregroundStyle(text)
        }
    }
}

struct RecipePickerSheet: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    let meal: MealType
    let date: Date

    private var options: [Recipe] {
        let r = app.recommended(for: meal)
        return r.isEmpty ? Recipe.all.filter { $0.meals.contains(meal) } : r
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(options) { recipe in
                        Button {
                            app.addToPlan(recipe, meal: meal, date: date)
                            dismiss()
                        } label: { RecipeCard(recipe: recipe) }
                            .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .navigationTitle("Add \(meal.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }
}
