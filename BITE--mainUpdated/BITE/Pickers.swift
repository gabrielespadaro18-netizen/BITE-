import SwiftUI

// MARK: - Layout helpers

/// Wraps its children onto new lines when they run out of horizontal space.
struct FlowLayout: Layout {
    var spacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, width: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth + 0.5 && x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            width = max(width, x - spacing)
        }
        return CGSize(width: proposal.width ?? width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX + 0.5 && x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

struct ChipButton: View {
    let title: String
    let on: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(on ? Color.white : Color.black)
                .padding(.horizontal, 14).padding(.vertical, 9)
                .background(Capsule().fill(on ? Color.biteGreen : Color(white: 0.97))
                    .shadow(color: .black.opacity(0.12), radius: 4, y: 2))
        }
        .buttonStyle(.plain)
    }
}

/// A scroll view whose content is at least as tall as the space it is given,
/// so `Spacer`s inside spread the content over the empty space instead of bunching it at the top.
struct FillScroll<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                content.frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: .top)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

// MARK: - Tile grid (goals, diet)

/// Two-column grid whose tiles grow to use the available height instead of leaving a gap above the button.
struct TileGrid: View {
    let items: [(label: String, icon: String)]
    let isOn: (String) -> Bool
    let tap: (String) -> Void

    private var rows: Int { (items.count + 1) / 2 }

    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 14
            let rowCount = CGFloat(rows)
            let tile = min(170, max(96, (geo.size.height - spacing * (rowCount - 1)) / rowCount))
            LazyVGrid(columns: [GridItem(.flexible(), spacing: spacing), GridItem(.flexible(), spacing: spacing)],
                      spacing: spacing) {
                ForEach(items, id: \.label) { item in
                    let on = isOn(item.label)
                    Button { tap(item.label) } label: {
                        VStack(spacing: 10) {
                            Image(systemName: item.icon).font(.system(size: min(36, tile * 0.28)))
                            Text(item.label).font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(on ? Color.white : Color.biteGreen)
                        .frame(maxWidth: .infinity)
                        .frame(height: tile)
                        .background(CardBackground(selected: on, radius: 20))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
    }
}

struct GoalsPicker: View {
    @Binding var selection: Set<String>

    var body: some View {
        TileGrid(items: Options.goals, isOn: { selection.contains($0) }) { label in
            if selection.contains(label) { selection.remove(label) } else { selection.insert(label) }
        }
    }
}

struct DietPicker: View {
    @Binding var selection: String

    var body: some View {
        TileGrid(items: Options.diets, isOn: { selection == $0 }) { selection = $0 }
    }
}

// MARK: - Plan form (budget / people / time)

struct PlanForm: View {
    @Binding var profile: UserProfile

    var body: some View {
        FillScroll {
            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 8)
                budget
                Spacer(minLength: 28)
                people
                Spacer(minLength: 28)
                time
                Spacer(minLength: 8)
            }
            .padding(.horizontal, 4)
        }
    }

    private var budget: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weekly food budget").font(.system(size: 15, weight: .semibold))
            (Text("€\(Int(profile.weeklyBudget))").foregroundStyle(Color.biteGreen) + Text(" / week"))
                .font(.system(size: 32, weight: .bold))
            Slider(value: $profile.weeklyBudget, in: 20...100, step: 5).tint(Color.biteGreen)
            HStack { Text("20€"); Spacer(); Text("100€") }
                .font(.system(size: 11)).foregroundStyle(.secondary)
        }
    }

    private var people: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("People you cook for").font(.system(size: 15, weight: .semibold))
            HStack(spacing: 28) {
                Spacer()
                stepButton("minus") { profile.people = max(1, profile.people - 1) }
                Text("\(profile.people)").font(.system(size: 30, weight: .semibold)).frame(minWidth: 44)
                stepButton("plus") { profile.people = min(12, profile.people + 1) }
                Spacer()
            }
        }
    }

    private var time: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Cooking time per meal").font(.system(size: 15, weight: .semibold))
            HStack(spacing: 10) {
                ForEach(Options.cookTimes.indices, id: \.self) { i in
                    ChipButton(title: Options.cookTimes[i], on: profile.cookTime == i) { profile.cookTime = i }
                }
            }
        }
    }

    private func stepButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 42, height: 42)
                .background(Circle().fill(Color(white: 0.96)).shadow(color: .black.opacity(0.1), radius: 4, y: 2))
        }
    }
}
