import SwiftUI

struct OnboardingFlow: View {
    @EnvironmentObject var app: AppState
    @State private var step = 0
    @State private var forward = true

    private func go(_ delta: Int) {
        forward = delta > 0
        withAnimation(.easeInOut(duration: 0.3)) { step += delta }
    }

    private var progress: Double { Double(step - 1) / 6 }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            Group {
                switch step {
                case 0: welcome
                case 1: intro
                case 2: nameQuestion
                case 3: goalsQuestion
                case 4: planQuestion
                case 5: intolerancesQuestion
                case 6: allergiesQuestion
                case 7: dietQuestion
                default: ready
                }
            }
            .id(step)
            .transition(.asymmetric(
                insertion: .move(edge: forward ? .trailing : .leading),
                removal: .move(edge: forward ? .leading : .trailing)))
        }
        .clipped()
    }

    // MARK: Screens

    private var welcome: some View {
        VStack {
            Spacer()
            AppleMascot(mood: .happy, size: 120)
            (Text("WELCOME\nTO ").font(.system(size: 34, weight: .heavy))
             + Text("BITE!").font(.system(size: 34, weight: .black)))
                .foregroundStyle(Color.biteDark)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
            Spacer()
            Spacer()
            PrimaryButton(title: "Continue") { go(1) }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    private var intro: some View {
        VStack(alignment: .leading) {
            HStack { Spacer(); BiteLogo(); Spacer() }
            Text("Let’s make some Bite questions!")
                .font(.system(size: 34, weight: .heavy))
                .lineSpacing(-6)
                .padding(.top, 24)
            Spacer()
            HStack { Spacer(); AppleMascot(mood: .question, size: 120); Spacer() }
            Spacer()
            Spacer()
            PrimaryButton(title: "Continue") { go(1) }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    private var nameQuestion: some View {
        QuestionScaffold(title: "What’s your name?", progress: progress,
                         canContinue: !app.profile.name.trimmingCharacters(in: .whitespaces).isEmpty,
                         onBack: { go(-1) }, onContinue: { go(1) }) {
            VStack {
                Spacer()
                TextField("Name", text: $app.profile.name)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 15))
                    .textInputAutocapitalization(.words)
                    .padding(.vertical, 14)
                    .frame(maxWidth: 220)
                    .background(Capsule().fill(Color(white: 0.96))
                        .shadow(color: .black.opacity(0.1), radius: 5, y: 3))
                Spacer()
            }
        }
    }

    private var goalsQuestion: some View {
        QuestionScaffold(title: "What are your goals?", progress: progress,
                         canContinue: !app.profile.goals.isEmpty,
                         onBack: { go(-1) }, onContinue: { go(1) }) {
            ScrollView { GoalsPicker(selection: $app.profile.goals).padding(4) }
        }
    }

    private var planQuestion: some View {
        QuestionScaffold(title: "Let’s create your plan!", progress: progress,
                         canContinue: app.profile.cookTime != nil,
                         onBack: { go(-1) }, onContinue: { go(1) }) {
            ScrollView { PlanForm(profile: $app.profile) }
        }
    }

    private var intolerancesQuestion: some View {
        QuestionScaffold(title: "Any food intolerances?", progress: progress,
                         canContinue: !app.profile.intolerances.isEmpty,
                         onBack: { go(-1) }, onContinue: { go(1) }) {
            MultiSelectList(items: Options.intolerances, noneLabel: Options.noIntolerances,
                            searchPrompt: "Search Food Intolerances", selection: $app.profile.intolerances)
        }
    }

    private var allergiesQuestion: some View {
        QuestionScaffold(title: "Any food allergies?", progress: progress,
                         canContinue: !app.profile.allergies.isEmpty,
                         onBack: { go(-1) }, onContinue: { go(1) }) {
            MultiSelectList(items: Options.allergies, noneLabel: Options.noAllergies,
                            searchPrompt: "Search Food Allergies", selection: $app.profile.allergies)
        }
    }

    private var dietQuestion: some View {
        QuestionScaffold(title: "Any diet preferences?", progress: progress,
                         onBack: { go(-1) }, onContinue: { go(1) }) {
            ScrollView { DietPicker(selection: $app.profile.diet).padding(4) }
        }
    }

    private var ready: some View {
        VStack(alignment: .leading) {
            HStack { Spacer(); BiteLogo(); Spacer() }
            Text("Now we are ready, \(app.profile.name.trimmingCharacters(in: .whitespaces))!")
                .font(.system(size: 34, weight: .heavy))
                .lineSpacing(-6)
                .padding(.top, 24)
            Spacer()
            HStack { Spacer(); AppleMascot(mood: .wink, size: 120); Spacer() }
            Spacer()
            Spacer()
            PrimaryButton(title: "Continue") {
                withAnimation { app.profile.onboarded = true }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
}

// MARK: - Scaffold

struct QuestionScaffold<Content: View>: View {
    let title: String
    let progress: Double
    var canContinue = true
    let onBack: () -> Void
    let onContinue: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                BiteLogo()
                HStack { CircleBackButton(action: onBack); Spacer() }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(white: 0.9))
                    Capsule().fill(Color.biteGreen)
                        .frame(width: geo.size.width * progress)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 5)
            Text(title)
                .font(.system(size: 34, weight: .heavy))
                .lineSpacing(-6)
                .fixedSize(horizontal: false, vertical: true)
            content.frame(maxWidth: .infinity, maxHeight: .infinity)
            PrimaryButton(title: "Continue", enabled: canContinue, action: onContinue)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
}

// MARK: - Reusable pickers

struct GoalsPicker: View {
    @Binding var selection: Set<String>

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(Options.goals, id: \.label) { goal in
                let on = selection.contains(goal.label)
                Button {
                    if on { selection.remove(goal.label) } else { selection.insert(goal.label) }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: goal.icon).font(.system(size: 26))
                        Text(goal.label).font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(on ? Color.white : Color.biteGreen)
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .background(CardBackground(selected: on))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct DietPicker: View {
    @Binding var selection: String

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(Options.diets, id: \.label) { diet in
                let on = selection == diet.label
                Button { selection = diet.label } label: {
                    VStack(spacing: 8) {
                        Image(systemName: diet.icon).font(.system(size: 26))
                        Text(diet.label).font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(on ? Color.white : Color.biteGreen)
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .background(CardBackground(selected: on))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct PlanForm: View {
    @Binding var profile: UserProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Weekly food budget").font(.system(size: 15, weight: .semibold))
                (Text("€\(Int(profile.weeklyBudget))").foregroundStyle(Color.biteGreen)
                 + Text(" / week"))
                    .font(.system(size: 30, weight: .bold))
                Slider(value: $profile.weeklyBudget, in: 20...100, step: 5)
                    .tint(Color.biteGreen)
                HStack {
                    Text("20€"); Spacer(); Text("100€")
                }
                .font(.system(size: 11)).foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("People you cook for").font(.system(size: 15, weight: .semibold))
                HStack(spacing: 28) {
                    Spacer()
                    stepButton("minus") { profile.people = max(1, profile.people - 1) }
                    Text("\(profile.people)").font(.system(size: 28, weight: .semibold))
                        .frame(minWidth: 40)
                    stepButton("plus") { profile.people = min(12, profile.people + 1) }
                    Spacer()
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Cooking time per meal").font(.system(size: 15, weight: .semibold))
                HStack(spacing: 10) {
                    ForEach(Options.cookTimes.indices, id: \.self) { i in
                        let on = profile.cookTime == i
                        Button { profile.cookTime = i } label: {
                            Text(Options.cookTimes[i])
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(on ? Color.white : Color.black)
                                .padding(.horizontal, 14).padding(.vertical, 9)
                                .background(Capsule().fill(on ? Color.biteGreen : Color(white: 0.96))
                                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }

    private func stepButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Color(white: 0.96)).shadow(color: .black.opacity(0.1), radius: 4, y: 2))
        }
    }
}

struct MultiSelectList: View {
    let items: [String]
    let noneLabel: String
    let searchPrompt: String
    @Binding var selection: Set<String>
    @State private var query = ""

    private var rows: [String] {
        let all = [noneLabel] + items
        guard !query.isEmpty else { return all }
        return all.filter { $0.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField(searchPrompt, text: $query).font(.system(size: 13))
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.95)))

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(rows, id: \.self) { row in
                        let on = selection.contains(row)
                        Button { toggle(row) } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "nosign").font(.system(size: 20))
                                Text(row).font(.system(size: 12, weight: .bold))
                                Spacer()
                            }
                            .foregroundStyle(on ? Color.white : Color.biteGreen)
                            .padding(.horizontal, 16)
                            .frame(height: 46)
                            .background(CardBackground(selected: on, radius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 2)
            }
        }
    }

    private func toggle(_ row: String) {
        if row == noneLabel {
            selection = [noneLabel]
            return
        }
        selection.remove(noneLabel)
        if selection.contains(row) { selection.remove(row) } else { selection.insert(row) }
    }
}
