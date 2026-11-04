import SwiftUI

extension ShapeStyle where Self == Color {
    static var biteGreen: Color { Color(red: 52/255, green: 199/255, blue: 89/255) }
    static var biteDark: Color { Color(red: 0.21, green: 0.27, blue: 0.19) }
    static var biteMint: Color { Color(red: 195/255, green: 245/255, blue: 208/255) }
    static var biteRed: Color { Color(red: 0.89, green: 0.30, blue: 0.27) }
}

struct BiteLogo: View {
    var body: some View {
        Text("BITE!")
            .font(.system(size: 22, weight: .black))
            .foregroundStyle(Color.biteDark)
    }
}

struct PrimaryButton: View {
    let title: String
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Capsule().fill(Color.biteGreen))
                .shadow(color: Color.biteGreen.opacity(0.35), radius: 8, y: 4)
        }
        .opacity(enabled ? 1 : 0.4)
        .disabled(!enabled)
    }
}

struct CardBackground: View {
    var selected = false
    var radius: CGFloat = 16

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(selected ? Color.biteGreen : Color.white)
            .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
    }
}

struct CircleBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.black)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Color(white: 0.95)))
        }
    }
}

// MARK: - Apple mascot

enum MascotMood {
    case happy, question, wink

    fileprivate var assetName: String {
        switch self {
        case .happy: return "MascotHappy"
        case .question: return "MascotQuestion"
        case .wink: return "MascotWink"
        }
    }

    /// The question artwork includes the floating "?" marks, so it needs more room for the apple to match the others.
    fileprivate var widthFactor: CGFloat {
        switch self {
        case .happy: return 1.0
        case .wink: return 0.95
        case .question: return 1.8
        }
    }
}

struct AppleMascot: View {
    var mood: MascotMood = .happy
    var size: CGFloat = 120

    var body: some View {
        Image(mood.assetName)
            .resizable()
            .scaledToFit()
            .frame(width: size * mood.widthFactor, height: size * 1.1)
            .accessibilityHidden(true)
    }
}
