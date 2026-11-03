import SwiftUI

struct MainTabView: View {
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            HomeView(tab: $tab)
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
    @Binding var tab: Int

    private var lowItems: Int { app.pantry.filter { $0.amount < 3 }.count }

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                ZStack {
                    BiteLogo()
                    HStack {
                        Spacer()
                        NavigationLink { ProfileView() } label: {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 30)).foregroundStyle(Color.biteGreen)
                        }
                    }
                }
                HStack {
                    Text("Hi, \(app.profile.name)!").font(.system(size: 34, weight: .heavy))
                    Spacer()
                }
                Spacer()
                AppleMascot(mood: .happy, size: 130)
                Spacer()
                HStack(spacing: 12) {
                    stat("\(app.plannedCount(on: Date()))", "meals planned today")
                    stat("\(lowItems)", "pantry items running low")
                }
                PrimaryButton(title: "Find recipes") { tab = 1 }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 26, weight: .bold)).foregroundStyle(Color.biteGreen)
            Text(label).font(.system(size: 11)).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(CardBackground(radius: 16))
    }
}
