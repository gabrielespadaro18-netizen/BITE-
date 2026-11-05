import SwiftUI

/// Uses the system-managed iOS tab bar (UITabBar via SwiftUI TabView).
/// No custom backgrounds, capsules, overlays, fixed tab heights, or tab-bar positioning.
struct MainTabView: View {
    @EnvironmentObject private var app: AppState
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            HomeView()
                .tabItem { Label("Bite", systemImage: "fork.knife.circle") }
                .tag(0)

            RecipesView()
                .tabItem { Label("Recipes", systemImage: "book.closed") }
                .tag(1)

            PlanView()
                .tabItem { Label("My Plan", systemImage: "calendar") }
                .tag(2)

            PantryView()
                .tabItem { Label("Pantry", systemImage: "carrot") }
                .tag(3)
        }
        .tint(Color.biteGreen)
        .task {
            await PantryNotifications.update(pantry: app.pantry, shopping: app.shopping, plan: app.plan)
        }
        .onReceive(app.$pantry) { items in
            Task { await PantryNotifications.update(pantry: items, shopping: app.shopping, plan: app.plan) }
        }
        .onReceive(app.$shopping) { items in
            Task { await PantryNotifications.update(pantry: app.pantry, shopping: items, plan: app.plan) }
        }
        .onReceive(app.$plan) { value in
            Task { await PantryNotifications.update(pantry: app.pantry, shopping: app.shopping, plan: value) }
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var app: AppState
    @State private var path = NavigationPath()
    @State private var showFlow = false
    @AppStorage("bite.onboarding.reminder.shown") private var reminderShown = false
    @State private var showOnboardingReminder = false

    var body: some View {
        NavigationStack(path: $path) {
            VStack(alignment: .leading, spacing: 0) {
                header
                Text(app.profile.name.isEmpty ? "Welcome to BITE!" : "Welcome \(app.profile.name)!")
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
                    .background(alignment: .topTrailing) {
                        // Draw the original mascot BEHIND the CTA, like the Sketch.
                        // Only its upper portion rises above the button edge.
                        AppleMascot(mood: .happy, size: 82)
                            .rotationEffect(.degrees(-12))
                            .offset(x: -15, y: -66)
                            .allowsHitTesting(false)
                    }
                    .padding(.top, 66)

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
                PlanFlowSheet(onDaily: { path.append(HomeRoute.daily($0)) }, onWeekly: { path.append(HomeRoute.weekly($0)) })
            }
            .onAppear {
                if app.profile.skippedOnboarding && !reminderShown {
                    showOnboardingReminder = true
                    reminderShown = true
                }
                if !app.profile.skippedOnboarding { reminderShown = false }
            }
            .alert("Finish your BITE! setup?", isPresented: $showOnboardingReminder) {
                Button("Complete onboarding") {
                    app.profile.skippedOnboarding = false
                    app.profile.onboarded = false
                }
                Button("Later", role: .cancel) { }
            } message: {
                Text("Answering a few questions will help personalize recipes. You can also resume anytime from your profile.")
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
                Image(systemName: "takeoutbag.and.cup.and.straw")
                    .font(.system(size: 37, weight: .regular))
                    .accessibilityHidden(true)
                Text("Plan Your Meal").font(.system(size: 20, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity).frame(height: 112)
            .background(RoundedRectangle(cornerRadius: 58, style: .continuous).fill(Color.biteGreen)
                .shadow(color: Color.biteGreen.opacity(0.4), radius: 10, y: 6))
        }
    }

    @ViewBuilder
    private var recommended: some View {
        if let recipe = app.recommended().first {
            HStack {
                Text("Recommended for you :").font(.system(size: 15, weight: .bold))
                Spacer()
                Button { path.append(HomeRoute.all) } label: {
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
