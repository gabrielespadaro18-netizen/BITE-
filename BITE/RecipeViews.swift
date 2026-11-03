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
            Text(recipe.emoji)
                .font(.system(size: symbolSize * 1.3))
        }
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
    }
}

struct RecipeCard: View {
    @EnvironmentObject var app: AppState
    let recipe: Recipe

    var body: some View {
        let used = app.pantryCount(for: recipe)
        HStack(spacing: 14) {
            RecipeImage(recipe: recipe).frame(width: 92, height: 80)
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name).font(.system(size: 15, weight: .bold)).foregroundStyle(.black)
                    .multilineTextAlignment(.leading)
                Text(recipe.hasContent ? "\(recipe.minutes)min · \(recipe.tag)" : recipe.tag)
                    .font(.system(size: 12)).foregroundStyle(.black.opacity(0.75))
                Text(recipe.hasContent ? "Uses \(used) \(used == 1 ? "item" : "items") you already have" : recipe.country)
                    .font(.system(size: 11)).foregroundStyle(.black.opacity(0.6))
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.biteMint)
            .shadow(color: .black.opacity(0.12), radius: 6, y: 3))
    }
}

// MARK: - Results

struct ResultSection: Identifiable {
    let id = UUID()
    let title: String?
    let recipes: [Recipe]
}

/// Header with a back button, title and subtitle, used by every "Here's what we found" style screen.
struct ResultsScaffold<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    var subtitle: String? = "Based on your answers"
    var showsMascot = false
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                CircleBackButton { dismiss() }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 20, weight: .bold))
                    if let subtitle { Text(subtitle).font(.system(size: 13)) }
                }
                Spacer()
                if showsMascot { AppleMascot(mood: .happy, size: 40) }
            }
            .padding(.horizontal, 16)

            ScrollView {
                content
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct RecipeResultsView: View {
    let title: String
    var subtitle: String? = "Based on your answers"
    let sections: [ResultSection]
    var defaultMeal: MealType? = nil

    var body: some View {
        ResultsScaffold(title: title, subtitle: subtitle) {
            VStack(alignment: .leading, spacing: 14) {
                if sections.allSatisfy({ $0.recipes.isEmpty }) {
                    Text("No recipes match these choices yet. Try changing your answers.")
                        .font(.subheadline).foregroundStyle(.secondary).padding(.top, 20)
                }
                ForEach(sections) { section in
                    if let t = section.title {
                        Text("\(t) :").font(.system(size: 18, weight: .semibold)).padding(.top, 6)
                    }
                    ForEach(section.recipes) { recipe in
                        NavigationLink(value: RecipeRoute(recipe: recipe, meal: defaultMeal)) {
                            RecipeCard(recipe: recipe)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Recipes tab

struct RecipesView: View {
    @EnvironmentObject var app: AppState
    @State private var query = ""

    private var recentRecipes: [Recipe] { app.recent.compactMap { Recipe.find($0) } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Find your recipe!").font(.system(size: 26, weight: .bold))

                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                        TextField("Search", text: $query).font(.system(size: 14))
                        if !query.isEmpty {
                            Button { query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                        }
                    }
                    .padding(11)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(white: 0.96))
                        .shadow(color: .black.opacity(0.1), radius: 5, y: 2))

                    if query.trimmingCharacters(in: .whitespaces).isEmpty {
                        recent
                        countries
                    } else {
                        searchResults
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
            .navigationDestination(for: RecipeRoute.self) { RecipeDetailView(route: $0) }
            .navigationDestination(for: Region.self) { CountryListView(region: $0) }
            .navigationDestination(for: CountryRoute.self) { route in
                RecipeResultsView(title: "Here’s what we found",
                                  sections: [ResultSection(title: nil,
                                                           recipes: app.safeRecipes(includeUnverified: true).filter { $0.country == route.country })])
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    @ViewBuilder
    private var searchResults: some View {
        let found = app.search(query)
        if found.isEmpty {
            Text("No recipes found.").font(.subheadline).foregroundStyle(.secondary)
        }
        ForEach(found) { recipe in
            NavigationLink(value: RecipeRoute(recipe: recipe)) { RecipeCard(recipe: recipe) }.buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var recent: some View {
        Text("My recent recipes:").font(.system(size: 15, weight: .bold))
        if recentRecipes.isEmpty {
            Text("Recipes you open will show up here.").font(.system(size: 13)).foregroundStyle(.secondary)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(recentRecipes) { recipe in
                        NavigationLink(value: RecipeRoute(recipe: recipe)) {
                            VStack(spacing: 6) {
                                RecipeImage(recipe: recipe, symbolSize: 26, corner: 12).frame(width: 84, height: 84)
                                Text(recipe.name).font(.system(size: 10)).foregroundStyle(.black)
                                    .lineLimit(1).frame(width: 84)
                            }
                            .padding(5)
                            .background(CardBackground(radius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 6).padding(.horizontal, 2)
            }
        }
    }

    private var countries: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select the country:").font(.system(size: 15, weight: .bold))
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                ForEach(Region.allCases, id: \.self) { region in
                    NavigationLink(value: region) {
                        VStack(spacing: 10) {
                            Image(systemName: region.symbol).font(.system(size: 30)).foregroundStyle(Color.biteGreen)
                            Text(region.rawValue).font(.system(size: 12, weight: .semibold)).foregroundStyle(.black)
                        }
                        .frame(maxWidth: .infinity).frame(height: 104)
                        .background(CardBackground(radius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2).padding(.bottom, 6)
        }
    }
}

struct CountryListView: View {
    @EnvironmentObject var app: AppState
    let region: Region

    private var countries: [String] {
        let all = app.safeRecipes(includeUnverified: true).filter { $0.region == region.rawValue }.map(\.country)
        return Array(Set(all)).sorted()
    }

    var body: some View {
        ResultsScaffold(title: "Select Your Country", subtitle: "Based on your choice", showsMascot: true) {
            VStack(spacing: 14) {
                if countries.isEmpty {
                    Text("No recipes for this region match your answers.")
                        .font(.subheadline).foregroundStyle(.secondary).padding(.top, 20)
                }
                ForEach(countries, id: \.self) { country in
                    NavigationLink(value: CountryRoute(region: region, country: country)) {
                        HStack(spacing: 16) {
                            Text(Catalog.flag(for: country))
                                .font(.system(size: 42))
                                .frame(width: 92, height: 80)
                                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(0.7)))
                            Text(country).font(.system(size: 17, weight: .semibold)).foregroundStyle(.black)
                            Spacer()
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.biteMint)
                            .shadow(color: .black.opacity(0.12), radius: 6, y: 3))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Detail

struct RecipeDetailView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    let route: RecipeRoute
    @State private var toast: String?

    private var recipe: Recipe { route.recipe }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                CircleBackButton { dismiss() }
                Spacer()
                addButton
            }
            .padding(.horizontal, 16).padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    RecipeImage(recipe: recipe, symbolSize: 70, corner: 22).frame(height: 210)
                    Text(recipe.name).font(.system(size: 20, weight: .bold))

                    HStack(spacing: 12) {
                        if recipe.hasContent { chip("\(recipe.minutes) min") }
                        chip(recipe.tag)
                        if recipe.hasContent { chip(recipe.servings == 1 ? "1 Serving" : "\(recipe.servings) Servings") }
                    }

                    if recipe.draft {
                        Label("Draft recipe — not yet verified by World Table. Check allergens and quantities yourself.",
                              systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.orange)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.orange.opacity(0.12)))
                    }

                    if !recipe.hasContent {
                        Text(recipe.blurb).font(.system(size: 14))
                        Text("The ingredients and steps for this recipe are still being verified, so it can’t be added to your plan yet.")
                            .font(.system(size: 13)).foregroundStyle(.secondary)
                        if let link = recipe.sourceUrl.flatMap(URL.init(string:)) {
                            Link("Read more", destination: link)
                                .font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.biteGreen)
                        }
                    }

                    if recipe.hasContent {
                    Text("Ingredients:").font(.system(size: 16, weight: .semibold))
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(recipe.ingredients, id: \.name) { item in
                            if app.pantryHas(item.name) || app.isBought(item.name) {
                                Label(app.pantryHas(item.name) ? "\(item.name) - in your pantry" : "\(item.name) - bought",
                                      systemImage: "checkmark.circle.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                    .labelStyle(TintedIcon(color: .biteGreen, text: .black))
                            } else {
                                let added = app.isInShopping(item.name)
                                Button { app.toggleShopping(ingredient: item) } label: {
                                    Label(added ? "\(item.name) - in your shopping list"
                                                : "\(item.name) - buy \(item.amount.isEmpty ? "some" : item.amount)",
                                          systemImage: added ? "cart.fill.badge.plus" : "circle")
                                        .font(.system(size: 15, weight: .semibold))
                                        .labelStyle(TintedIcon(color: added ? .biteGreen : .biteRed,
                                                               text: added ? .biteGreen : .biteRed))
                                }
                                .buttonStyle(.plain)
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
                }
                .padding(.horizontal, 16).padding(.bottom, 24)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { app.addRecent(recipe) }
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

    private var addPill: some View {
        Label("Add", systemImage: "plus")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(Capsule().fill(Color.biteGreen).shadow(color: Color.biteGreen.opacity(0.35), radius: 5, y: 3))
    }

    @ViewBuilder
    private var addButton: some View {
        if !recipe.hasContent {
            EmptyView()
        } else if let meal = route.meal {
            Button { add(to: meal) } label: { addPill }
        } else {
            Menu {
                ForEach(MealType.allCases) { meal in
                    Button(meal.rawValue) { add(to: meal) }
                }
            } label: { addPill }
        }
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
        return r.isEmpty ? Recipe.all.filter { $0.hasContent && $0.meals.contains(meal) } : r
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
