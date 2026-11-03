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
        ScrollView {
            VStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color.biteGreen).frame(width: 140, height: 140)
                    Circle().fill(.black).frame(width: 128, height: 128)
                    Circle().fill(Color.biteMint).frame(width: 116, height: 116)
                    Text(initial).font(.system(size: 56, weight: .black)).foregroundStyle(Color.biteDark)
                }
                .padding(.top, 8)
                Text(app.profile.name).font(.system(size: 22, weight: .bold))

                Text("Personal information:")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 30)

                VStack(spacing: 0) {
                    ForEach(ProfileSection.allCases) { section in
                        NavigationLink { ProfileEditor(section: section) } label: {
                            HStack {
                                Text(section.rawValue).font(.system(size: 13)).foregroundStyle(.black)
                                Spacer()
                                Text(summary(section)).font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(1)
                                Image(systemName: "chevron.right").font(.system(size: 11)).foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 14).padding(.vertical, 13)
                        }
                        if section != ProfileSection.allCases.last { Divider().padding(.leading, 14) }
                    }
                }
                .background(CardBackground(radius: 16))
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
                ScrollView { GoalsPicker(selection: $app.profile.goals).padding(4) }
            case .plan:
                ScrollView { PlanForm(profile: $app.profile) }
            case .intolerances:
                MultiSelectList(items: Options.intolerances, noneLabel: Options.noIntolerances,
                                searchPrompt: "Search Food Intolerances", selection: $app.profile.intolerances)
            case .allergies:
                MultiSelectList(items: Options.allergies, noneLabel: Options.noAllergies,
                                searchPrompt: "Search Food Allergies", selection: $app.profile.allergies)
            case .preferences:
                ScrollView { DietPicker(selection: $app.profile.diet).padding(4) }
            }
        }
        .padding(20)
        .navigationTitle(section.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
}
