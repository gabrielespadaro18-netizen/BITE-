import SwiftUI

enum ProfileSection: String, CaseIterable, Identifiable {
    case goals = "Goals", plan = "Plan", intolerances = "Intolerances", allergies = "Allergies", preferences = "Preferences"
    var id: String { rawValue }
}

struct ProfileView: View {
    @EnvironmentObject var app: AppState
    @State private var confirmReset = false

    private var initial: String {
        String(app.profile.name.trimmingCharacters(in: .whitespaces).first ?? "B").uppercased()
    }

    var body: some View {
        FillScroll {
            VStack(spacing: 0) {
                Spacer(minLength: 12)
                ZStack {
                    Circle().fill(Color.biteGreen).frame(width: 148, height: 148)
                    Circle().fill(.black).frame(width: 136, height: 136)
                    Circle().fill(Color.biteMint).frame(width: 124, height: 124)
                    Text(initial).font(.system(size: 60, weight: .black)).foregroundStyle(Color.biteDark)
                }
                Spacer(minLength: 18)
                Text(app.profile.name).font(.system(size: 24, weight: .bold))
                Spacer(minLength: 48)

                Text("Personal information:")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 14)

                VStack(spacing: 0) {
                    ForEach(ProfileSection.allCases) { section in
                        NavigationLink { ProfileEditor(section: section) } label: {
                            HStack {
                                Text(section.rawValue).font(.system(size: 14)).foregroundStyle(.black)
                                Spacer()
                                Text(summary(section)).font(.system(size: 12)).foregroundStyle(Color.gray).lineLimit(1)
                                Image(systemName: "chevron.right").font(.system(size: 11)).foregroundStyle(Color.gray)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 18)
                        }
                        if section != ProfileSection.allCases.last { Divider().padding(.leading, 16) }
                    }
                }
                .background(CardBackground(radius: 18))
                Spacer(minLength: 28)
            }
            .padding(.horizontal, 20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Redo the questions", systemImage: "arrow.counterclockwise") {
                        app.profile.onboarded = false
                    }
                    Button("Reset all data", systemImage: "trash", role: .destructive) { confirmReset = true }
                } label: { Image(systemName: "slider.horizontal.3") }
            }
        }
        .confirmationDialog("Reset everything?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset all data", role: .destructive) { app.resetAll() }
        } message: {
            Text("This clears your profile, plan, pantry and shopping list.")
        }
    }

    private func summary(_ section: ProfileSection) -> String {
        let p = app.profile
        switch section {
        case .goals: return p.goals.isEmpty ? "Not set" : p.goals.sorted().joined(separator: ", ")
        case .plan:
            let time = p.cookTime.map { Options.cookTimes[$0] } ?? "—"
            return "€\(Int(p.weeklyBudget)) · \(p.people) · \(time)"
        case .intolerances: return list(p.intolerances, none: Options.noIntolerances)
        case .allergies: return list(p.allergies, none: Options.noAllergies)
        case .preferences: return p.diet
        }
    }

    private func list(_ set: Set<String>, none: String) -> String {
        let real = set.subtracting([none])
        return real.isEmpty ? "None" : real.sorted().joined(separator: ", ")
    }
}

struct ProfileEditor: View {
    @EnvironmentObject var app: AppState
    let section: ProfileSection

    var body: some View {
        VStack(alignment: .leading) {
            switch section {
            case .goals:
                GoalsPicker(selection: $app.profile.goals)
            case .plan:
                PlanForm(profile: $app.profile)
            case .intolerances:
                MultiSelectList(items: Options.intolerances, noneLabel: Options.noIntolerances,
                                searchPrompt: "Search Food Intolerances", selection: $app.profile.intolerances)
            case .allergies:
                MultiSelectList(items: Options.allergies, noneLabel: Options.noAllergies,
                                searchPrompt: "Search Food Allergies", selection: $app.profile.allergies)
            case .preferences:
                DietPicker(selection: $app.profile.diet)
            }
        }
        .padding(20)
        .navigationTitle(section.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
}
