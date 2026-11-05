import SwiftUI

/// Simple line icons based on the provided Sketch screens; other icons use SF Symbols.
struct SketchBowlIcon: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            var bowl = Path()
            bowl.move(to: CGPoint(x: 0.09*w, y: 0.48*h))
            bowl.addQuadCurve(to: CGPoint(x: 0.91*w, y: 0.48*h), control: CGPoint(x: 0.5*w, y: 0.70*h))
            bowl.addQuadCurve(to: CGPoint(x: 0.5*w, y: 0.88*h), control: CGPoint(x: 0.80*w, y: 0.86*h))
            bowl.addQuadCurve(to: CGPoint(x: 0.09*w, y: 0.48*h), control: CGPoint(x: 0.20*w, y: 0.84*h))
            context.stroke(bowl, with: .foreground, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            var rim = Path(ellipseIn: CGRect(x: 0.07*w, y: 0.33*h, width: 0.86*w, height: 0.26*h))
            context.stroke(rim, with: .foreground, lineWidth: 2)
            var spoon = Path()
            spoon.move(to: CGPoint(x: 0.55*w, y: 0.38*h))
            spoon.addLine(to: CGPoint(x: 0.95*w, y: 0.11*h))
            context.stroke(spoon, with: .foreground, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
        }
        .accessibilityHidden(true)
    }
}

struct SketchMealPlanIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .stroke(.white, lineWidth: 3)
                .frame(width: 30, height: 34)
                .offset(x: -9, y: 3)
            Path { p in
                p.move(to: CGPoint(x: 9, y: 17))
                p.addQuadCurve(to: CGPoint(x: 25, y: 17), control: CGPoint(x: 17, y: 9))
            }.stroke(.white, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            RoundedRectangle(cornerRadius: 3)
                .stroke(.white, lineWidth: 3)
                .frame(width: 15, height: 27)
                .offset(x: 14, y: 8)
                .background(alignment: .topTrailing) {
                    Capsule().fill(.white).frame(width: 20, height: 3)
                        .rotationEffect(.degrees(-40)).offset(x: 11, y: -7)
                }
        }
        .frame(width: 58, height: 48)
        .accessibilityHidden(true)
    }
}

struct SketchCalendarIcon: View {
    let day: Int
    var body: some View {
        Text("\(day)")
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 20, height: 20)
            .background(RoundedRectangle(cornerRadius: 3).fill(Color.biteDark))
            .overlay(RoundedRectangle(cornerRadius: 3)
                .stroke(Color.biteDark, lineWidth: 0.5))
    }
}
