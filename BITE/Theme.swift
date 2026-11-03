import SwiftUI

extension ShapeStyle where Self == Color {
    static var biteGreen: Color { Color(red: 0.39, green: 0.77, blue: 0.40) }
    static var biteDark: Color { Color(red: 0.21, green: 0.27, blue: 0.19) }
    static var biteMint: Color { Color(red: 0.80, green: 0.94, blue: 0.82) }
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

enum MascotMood { case happy, question, wink }

struct AppleShape: Shape {
    func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        var p = Path()
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.2))
        p.addCurve(to: CGPoint(x: 0, y: h * 0.58),
                   control1: CGPoint(x: w * 0.32, y: h * 0.02), control2: CGPoint(x: 0, y: h * 0.25))
        p.addCurve(to: CGPoint(x: w * 0.3, y: h),
                   control1: CGPoint(x: 0, y: h * 0.85), control2: CGPoint(x: w * 0.12, y: h))
        p.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.95),
                   control1: CGPoint(x: w * 0.4, y: h), control2: CGPoint(x: w * 0.44, y: h * 0.95))
        p.addCurve(to: CGPoint(x: w * 0.7, y: h),
                   control1: CGPoint(x: w * 0.56, y: h * 0.95), control2: CGPoint(x: w * 0.6, y: h))
        p.addCurve(to: CGPoint(x: w, y: h * 0.58),
                   control1: CGPoint(x: w * 0.88, y: h), control2: CGPoint(x: w, y: h * 0.85))
        p.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.2),
                   control1: CGPoint(x: w, y: h * 0.25), control2: CGPoint(x: w * 0.68, y: h * 0.02))
        p.closeSubpath()
        return p
    }
}

private struct EyeArc: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY), control: CGPoint(x: r.midX, y: r.minY - r.height))
        return p
    }
}

struct AppleMascot: View {
    var mood: MascotMood = .happy
    var size: CGFloat = 120

    private var bodyHeight: CGFloat { size * 0.88 }

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.black.opacity(0.12))
                .frame(width: size * 0.75, height: size * 0.07)
                .offset(y: bodyHeight * 0.55)

            // stem + leaf
            RoundedRectangle(cornerRadius: size * 0.02)
                .fill(Color(red: 0.45, green: 0.28, blue: 0.16))
                .frame(width: size * 0.05, height: size * 0.17)
                .rotationEffect(.degrees(12))
                .offset(x: size * 0.02, y: -bodyHeight * 0.48)
            Ellipse()
                .fill(LinearGradient(colors: [Color(red: 0.45, green: 0.78, blue: 0.35), Color(red: 0.25, green: 0.58, blue: 0.25)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.3, height: size * 0.15)
                .rotationEffect(.degrees(-25))
                .offset(x: size * 0.17, y: -bodyHeight * 0.52)

            // body with bite
            ZStack {
                AppleShape().fill(LinearGradient(
                    colors: [Color(red: 0.93, green: 0.30, blue: 0.25), Color(red: 0.78, green: 0.18, blue: 0.16)],
                    startPoint: .top, endPoint: .bottom))
                Circle()
                    .fill(Color(red: 0.98, green: 0.80, blue: 0.35))
                    .frame(width: size * 0.26)
                    .offset(x: size * 0.46, y: -bodyHeight * 0.2)
            }
            .frame(width: size, height: bodyHeight)
            .clipShape(AppleShape())

            face
                .offset(y: bodyHeight * 0.05)

            if mood == .question {
                Text("?").font(.system(size: size * 0.2, weight: .black, design: .rounded))
                    .foregroundStyle(Color.orange)
                    .rotationEffect(.degrees(-15))
                    .offset(x: -size * 0.55, y: -bodyHeight * 0.4)
                Text("?").font(.system(size: size * 0.24, weight: .black, design: .rounded))
                    .foregroundStyle(Color.orange)
                    .rotationEffect(.degrees(15))
                    .offset(x: size * 0.6, y: -bodyHeight * 0.45)
            }
        }
        .frame(width: size * 1.4, height: size * 1.2)
    }

    private var face: some View {
        ZStack {
            HStack(spacing: size * 0.2) {
                eye(left: true)
                eye(left: false)
            }
            HStack(spacing: size * 0.4) {
                Circle().fill(Color.pink.opacity(0.35)).frame(width: size * 0.1)
                Circle().fill(Color.pink.opacity(0.35)).frame(width: size * 0.1)
            }
            .offset(y: size * 0.1)
        }
    }

    @ViewBuilder
    private func eye(left: Bool) -> some View {
        switch mood {
        case .happy:
            arcEye
        case .wink:
            if left { roundEye } else { arcEye }
        case .question:
            ZStack {
                Ellipse().fill(.white).frame(width: size * 0.09, height: size * 0.14)
                Ellipse().fill(Color.biteDark).frame(width: size * 0.05, height: size * 0.08)
            }
        }
    }

    private var arcEye: some View {
        EyeArc()
            .stroke(.white, style: StrokeStyle(lineWidth: size * 0.035, lineCap: .round))
            .frame(width: size * 0.1, height: size * 0.05)
    }

    private var roundEye: some View {
        Ellipse().fill(.white).frame(width: size * 0.08, height: size * 0.12)
    }
}
