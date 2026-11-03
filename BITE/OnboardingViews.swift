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
                TextField("", text: $app.profile.name,
                          prompt: Text("Name").foregroundStyle(Color(white: 0.4)))
                    .multilineTextAlignment(.center)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.black)
                    .textInputAutocapitalization(.words)
                    .padding(.vertical, 16)
                    .frame(maxWidth: 280)
                    .background(Capsule().fill(Color.white)
                        .shadow(color: .black.opacity(0.18), radius: 8, y: 4))
                    .overlay(Capsule().stroke(Color.biteGreen, lineWidth: 2))
                Spacer()
            }
        }
    }

    private var goalsQuestion: some View {
        QuestionScaffold(title: "What are your goals?", progress: progress,
                         canContinue: !app.profile.goals.isEmpty,
                         onBack: { go(-1) }, onContinue: { go(1) }) {
            GoalsPicker(selection: $app.profile.goals)
        }
    }

    private var planQuestion: some View {
        QuestionScaffold(title: "Let’s create your plan!", progress: progress,
                         canContinue: app.profile.cookTime != nil,
                         onBack: { go(-1) }, onContinue: { go(1) }) {
            PlanForm(profile: $app.profile)
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
            DietPicker(selection: $app.profile.diet)
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

// MARK: - Multi-select list

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
