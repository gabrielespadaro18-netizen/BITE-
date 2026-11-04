import SwiftUI

struct PlanView: View {
    @EnvironmentObject var app: AppState
    @State private var selected = Date()
    @State private var pickerMeal: MealType?

    private var cal: Calendar { .current }

    private var weekDays: [Date] {
        let start = cal.dateInterval(of: .weekOfYear, for: selected)?.start ?? selected
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        return f.string(from: selected)
    }

    private func weekday(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: d).uppercased()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("My Plan").font(.system(size: 28, weight: .bold))
                    calendarHeader
                    ForEach(MealType.allCases) { meal in mealSection(meal) }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: RecipeRoute.self) { RecipeDetailView(route: $0) }
            .sheet(item: $pickerMeal) { meal in
                RecipePickerSheet(meal: meal, date: selected)
            }
        }
    }

    private var calendarHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Text(monthTitle).font(.system(size: 13, weight: .semibold))
                Spacer()
                Button { shift(-7) } label: { Image(systemName: "chevron.left") }
                Button { shift(7) } label: { Image(systemName: "chevron.right") }.padding(.leading, 12)
            }
            .foregroundStyle(.black)

            HStack {
                ForEach(weekDays, id: \.self) { day in
                    let on = cal.isDate(day, inSameDayAs: selected)
                    Button { selected = day } label: {
                        VStack(spacing: 6) {
                            Text(weekday(day)).font(.system(size: 9)).foregroundStyle(.secondary)
                            Text("\(cal.component(.day, from: day))")
                                .font(.system(size: 15, weight: on ? .bold : .regular))
                                .foregroundStyle(.black)
                                .frame(width: 34, height: 34)
                                .background(Circle().fill(on ? Color.biteMint : Color.clear))
                                .overlay(Circle().stroke(Color.biteGreen, lineWidth: cal.isDateInToday(day) && !on ? 1.5 : 0))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func shift(_ days: Int) {
        if let d = cal.date(byAdding: .day, value: days, to: selected) { selected = d }
    }

    private func mealSection(_ meal: MealType) -> some View {
        let items = app.planned(on: selected, meal: meal)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(meal.rawValue):").font(.system(size: 18, weight: .bold))
                Spacer()
                Button { pickerMeal = meal } label: {
                    Label("Add \(meal.rawValue)", systemImage: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Capsule().fill(Color.biteGreen))
                }
            }
            .frame(height: 34)

            if items.isEmpty {
                Text("Nothing planned yet")
                    .font(.system(size: 13)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity).frame(height: 64)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.biteGreen.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])))
            }
            ForEach(items) { recipe in
                HStack(spacing: 8) {
                    NavigationLink(value: RecipeRoute(recipe: recipe)) { RecipeCard(recipe: recipe) }
                        .buttonStyle(.plain)
                    Button { app.removeFromPlan(recipe, meal: meal, date: selected) } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 22)).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
