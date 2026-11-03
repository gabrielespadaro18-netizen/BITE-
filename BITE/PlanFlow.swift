import SwiftUI

/// "Plan Your Meal" bottom sheet: choose daily or weekly, then fill in the form.
struct PlanFlowSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onDaily: (DailyRequest) -> Void
    let onWeekly: (WeeklyRequest) -> Void

    private enum Step { case choice, daily, weekly }
    @State private var step = Step.choice

    var body: some View {
        Group {
            switch step {
            case .choice:
                choice
            case .daily:
                DailyForm(onClose: { dismiss() }) { request in
                    dismiss()
                    onDaily(request)
                }
            case .weekly:
                WeeklyForm(onClose: { dismiss() }) { request in
                    dismiss()
                    onWeekly(request)
                }
            }
        }
        .presentationDetents(step == .choice ? [.height(300)] : [.large])
        .presentationDragIndicator(.visible)
        .animation(.easeInOut(duration: 0.25), value: step)
    }

    private var choice: some View {
        VStack(spacing: 18) {
            SheetHeader(title: "Select your choice") { dismiss() }
            choiceButton("Plan Daily", icon: "calendar") { step = .daily }
            choiceButton("Plan Weekly", icon: "calendar.badge.clock") { step = .weekly }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private func choiceButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity).frame(height: 56)
                .background(Capsule().fill(Color.biteMint).shadow(color: .black.opacity(0.12), radius: 6, y: 3))
        }
        .buttonStyle(.plain)
    }
}

struct SheetHeader: View {
    let title: String
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Text(title).font(.system(size: 15, weight: .medium))
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color(white: 0.95)))
                }
                Spacer()
            }
        }
    }
}

private struct FormSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.system(size: 16, weight: .bold))
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CravingsAndPantry: View {
    @Binding var cravings: Set<String>
    @Binding var usePantry: Bool

    var body: some View {
        FormSection(title: "What are you craving?") {
            FlowLayout(spacing: 10) {
                ForEach(Options.cravings, id: \.self) { craving in
                    ChipButton(title: craving, on: cravings.contains(craving)) {
                        if cravings.contains(craving) { cravings.remove(craving) } else { cravings.insert(craving) }
                    }
                }
            }
        }
        FormSection(title: "Use what’s already in your Pantry?") {
            HStack(spacing: 12) {
                Text("Prioritize recipes that use ingredients you already have")
                    .font(.system(size: 12))
                Spacer()
                Toggle("", isOn: $usePantry).labelsHidden().tint(Color.biteGreen)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.biteMint))
        }
    }
}

private struct DailyForm: View {
    let onClose: () -> Void
    let onSearch: (DailyRequest) -> Void
    @State private var request = DailyRequest()

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: "Plan for today", onClose: onClose)
                .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 14)
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    FormSection(title: "How much time do you have today?") {
                        HStack(spacing: 10) {
                            ForEach(Options.cookTimes.indices, id: \.self) { i in
                                ChipButton(title: Options.cookTimes[i], on: request.minutes == i) {
                                    request.minutes = request.minutes == i ? nil : i
                                }
                            }
                        }
                    }
                    FormSection(title: "Which meal are you planning?") {
                        FlowLayout(spacing: 10) {
                            ForEach(MealType.allCases) { meal in
                                ChipButton(title: meal.rawValue, on: request.meal == meal) { request.meal = meal }
                            }
                        }
                    }
                    CravingsAndPantry(cravings: $request.cravings, usePantry: $request.usePantry)
                }
                .padding(.horizontal, 20).padding(.bottom, 12)
            }
            PrimaryButton(title: "Search my recipes", enabled: request.meal != nil) { onSearch(request) }
                .padding(.horizontal, 20).padding(.bottom, 12)
        }
    }
}

private struct WeeklyForm: View {
    let onClose: () -> Void
    let onSearch: (WeeklyRequest) -> Void
    @State private var request = WeeklyRequest()
    @State private var expanded: Int?

    private var canSearch: Bool {
        (0..<request.days).contains { !(request.meals[$0] ?? []).isEmpty }
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: "Plan for the week", onClose: onClose)
                .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 14)
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    FormSection(title: "How many days should we plan?") {
                        HStack(spacing: 10) {
                            ForEach([3, 5, 7], id: \.self) { n in
                                ChipButton(title: "\(n) days", on: request.days == n) {
                                    request.days = n
                                    if let e = expanded, e >= n { expanded = nil }
                                }
                            }
                        }
                    }
                    FormSection(title: "Which meals per day?") {
                        VStack(spacing: 0) {
                            ForEach(0..<request.days, id: \.self) { day in
                                dayRow(day)
                                if day < request.days - 1 { Divider().padding(.leading, 14) }
                            }
                        }
                        .background(CardBackground(radius: 14))
                    }
                    CravingsAndPantry(cravings: $request.cravings, usePantry: $request.usePantry)
                }
                .padding(.horizontal, 20).padding(.bottom, 12)
            }
            PrimaryButton(title: "Search my recipes", enabled: canSearch) { onSearch(request) }
                .padding(.horizontal, 20).padding(.bottom, 12)
        }
    }

    private func summary(_ day: Int) -> String {
        let chosen = MealType.allCases.filter { request.meals[day]?.contains($0) == true }
        return chosen.isEmpty ? "Chose" : chosen.map(\.rawValue).joined(separator: ", ")
    }

    @ViewBuilder
    private func dayRow(_ day: Int) -> some View {
        VStack(spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expanded = expanded == day ? nil : day }
            } label: {
                HStack {
                    Text(Options.weekdays[day]).font(.system(size: 14)).foregroundStyle(.black)
                    Spacer()
                    Text(summary(day)).font(.system(size: 12)).foregroundStyle(Color.gray).lineLimit(1)
                    Image(systemName: expanded == day ? "chevron.down" : "chevron.right")
                        .font(.system(size: 11)).foregroundStyle(Color.gray)
                }
                .padding(.horizontal, 14).padding(.vertical, 13)
            }
            .buttonStyle(.plain)

            if expanded == day {
                FlowLayout(spacing: 8) {
                    ForEach(MealType.allCases) { meal in
                        ChipButton(title: meal.rawValue, on: request.meals[day]?.contains(meal) == true) {
                            var set = request.meals[day] ?? []
                            if set.contains(meal) { set.remove(meal) } else { set.insert(meal) }
                            request.meals[day] = set
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14).padding(.bottom, 12)
            }
        }
    }
}

/// "Recipes Week": recipes grouped by meal, with a button that fills My Plan.
struct WeeklyResultsView: View {
    @EnvironmentObject var app: AppState
    let request: WeeklyRequest
    @State private var addedCount: Int?

    var body: some View {
        ResultsScaffold(title: "Here’s what we found") {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(request.chosenMeals) { meal in
                    let options = app.recipes(matching: DailyRequest(minutes: nil, meal: meal,
                                                                      cravings: request.cravings,
                                                                      usePantry: request.usePantry))
                    Text("\(meal.rawValue) :").font(.system(size: 18, weight: .semibold)).padding(.top, 6)
                    if options.isEmpty {
                        Text("No recipes match for this meal.").font(.subheadline).foregroundStyle(.secondary)
                    }
                    ForEach(options.prefix(3)) { recipe in
                        NavigationLink(value: RecipeRoute(recipe: recipe)) { RecipeCard(recipe: recipe) }
                            .buttonStyle(.plain)
                    }
                }
                PrimaryButton(title: "Add the week to My Plan") {
                    addedCount = app.addWeek(request)
                }
                .padding(.top, 10)
            }
        }
        .alert("Added to My Plan", isPresented: Binding(get: { addedCount != nil }, set: { if !$0 { addedCount = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(addedCount ?? 0) meal(s) were added starting today. Missing ingredients went to your shopping list.")
        }
    }
}


/// "Here's what we found" for a daily plan: a highlighted meal suggestion on top, then every match.
struct DailyResultsView: View {
    @EnvironmentObject var app: AppState
    let request: DailyRequest
    @State private var pick: Recipe?
    @State private var seen: Set<String> = []

    private var matches: [Recipe] { app.recipes(matching: request) }

    var body: some View {
        ResultsScaffold(title: "Here’s what we found") {
            VStack(alignment: .leading, spacing: 14) {
                if matches.isEmpty {
                    Text("No recipes match these choices yet. Try changing your answers.")
                        .font(.subheadline).foregroundStyle(.secondary).padding(.top, 20)
                }
                if let pick {
                    HStack {
                        Label("Meal suggestion", systemImage: "sparkles")
                            .font(.system(size: 18, weight: .semibold))
                        Spacer()
                        if matches.count > 1 {
                            Button { shuffle() } label: {
                                Label("Another", systemImage: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.biteGreen)
                            }
                        }
                    }
                    .padding(.top, 6)
                    NavigationLink(value: RecipeRoute(recipe: pick, meal: request.meal)) { RecipeCard(recipe: pick) }
                        .buttonStyle(.plain)
                        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.biteGreen, lineWidth: 2))
                }
                let rest = matches.filter { $0.id != pick?.id }
                if !rest.isEmpty {
                    Text("More matches :").font(.system(size: 18, weight: .semibold)).padding(.top, 6)
                    ForEach(rest) { recipe in
                        NavigationLink(value: RecipeRoute(recipe: recipe, meal: request.meal)) { RecipeCard(recipe: recipe) }
                            .buttonStyle(.plain)
                    }
                }
            }
        }
        .onAppear { if pick == nil { shuffle() } }
    }

    private func shuffle() {
        pick = app.suggestion(from: matches, excluding: seen)
        if let pick { seen.insert(pick.id) }
    }
}
