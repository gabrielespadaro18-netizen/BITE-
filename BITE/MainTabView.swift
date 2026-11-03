import SwiftUI

struct MainTabView: View {
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            HomeView()
                .tabItem { Label("Bite", systemImage: "fork.knife") }
                .tag(0)
            RecipesView()
                .tabItem { Label("Recipes", systemImage: "book.closed.fill") }
                .tag(1)
            PlanView()
                .tabItem { Label("My Plan", systemImage: "calendar") }
                .tag(2)
            PantryView()
                .tabItem { Label("Pantry", systemImage: "carrot") }
                .tag(3)
        }
        .tint(Color.biteGreen)
    }
}

struct HomeView: View {
    @EnvironmentObject var app: AppState
    @State private var path: [HomeRoute] = []
    @State private var showFlow = false

    var body: some View {
        NavigationStack(path: $path) {
            VStack(alignment: .leading, spacing: 0) {
                header
                Text("Welcome \(app.profile.name)!")
                    .font(.system(size: 12))
                    .padding(.top, 20)

                VStack(alignment: .leading, spacing: -6) {
                    Text("No idea")
                    Text("what")
                    Text("to cook?")
                }
                .font(.system(size: 38, weight: .heavy))
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 24)

                planButton
                    .overlay(alignment: .topTrailing) {
                        AppleMascot(mood: .happy, size: 74)
                            .offset(x: 14, y: -62)
                    }

                Spacer(minLength: 24)

                recommended
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .daily(let request):
                    DailyResultsView(request: request)
                case .weekly(let request):
                    WeeklyResultsView(request: request)
                case .all:
                    RecipeResultsView(title: "Recommended for you", subtitle: nil,
                                      sections: [ResultSection(title: nil, recipes: app.recommended())])
                }
            }
            .navigationDestination(for: RecipeRoute.self) { RecipeDetailView(route: $0) }
            .sheet(isPresented: $showFlow) {
                PlanFlowSheet(onDaily: { path.append(.daily($0)) }, onWeekly: { path.append(.weekly($0)) })
            }
        }
    }

    private var header: some View {
        ZStack {
            BiteLogo()
            HStack {
                Spacer()
                NavigationLink { ProfileView() } label: {
                    Image(systemName: "person")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.black)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(Color(white: 0.96)).shadow(color: .black.opacity(0.12), radius: 4, y: 2))
                }
            }
        }
    }

    private var planButton: some View {
        Button { showFlow = true } label: {
            VStack(spacing: 8) {
                Image(systemName: "fork.knife").font(.system(size: 30, weight: .medium))
                Text("Plan Your Meal").font(.system(size: 20, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity).frame(height: 112)
            .background(RoundedRectangle(cornerRadius: 36, style: .continuous).fill(Color.biteGreen)
                .shadow(color: Color.biteGreen.opacity(0.4), radius: 10, y: 6))
        }
    }

    @ViewBuilder
    private var recommended: some View {
        if let recipe = app.recommended().first {
            HStack {
                Text("Recommended for you :").font(.system(size: 15, weight: .bold))
                Spacer()
                Button { path.append(.all) } label: {
                    HStack(spacing: 2) { Text("See all"); Image(systemName: "chevron.right") }
                        .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.biteGreen)
                }
            }
            .padding(.bottom, 10)

            NavigationLink(value: RecipeRoute(recipe: recipe)) {
                VStack(spacing: 0) {
                    RecipeImage(recipe: recipe, symbolSize: 54, corner: 16).frame(height: 128)
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recipe.name).font(.system(size: 13, weight: .bold)).foregroundStyle(.black)
                            Label("\(recipe.minutes) Min.", systemImage: "clock")
                                .font(.system(size: 10)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button { app.toggleSaved(recipe) } label: {
                            Image(systemName: app.saved.contains(recipe.id) ? "bookmark.fill" : "bookmark")
                                .foregroundStyle(.black)
                        }
                    }
                    .padding(12)
                }
                .padding(6)
                .background(CardBackground(radius: 20))
            }
            .buttonStyle(.plain)
        }
    }
}
