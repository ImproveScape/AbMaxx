import SwiftUI

struct ProgressGraphView: View {
    @State private var lineProgress: CGFloat = 0
    @State private var withoutLineProgress: CGFloat = 0
    @State private var glowPulse: Bool = false
    @State private var labelOpacity: Double = 0
    @State private var bottomOpacity: Double = 0
    @State private var dotScale: CGFloat = 0
    @State private var endLabelOpacity: Double = 0

    private let withAbMaxxPoints: [CGFloat] = [0.82, 0.58, 0.38, 0.20, 0.06]
    private let withoutPoints: [CGFloat] = [0.82, 0.79, 0.77, 0.76, 0.75]

    private let accentBlue = AppTheme.primaryAccent
    private let failRed = Color(red: 255/255, green: 65/255, blue: 55/255)

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Your Abs Growth")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)

                Text("Predicted progress over 48 days")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 20)
            .padding(.horizontal, 24)

            Spacer().frame(height: 32)

            VStack(spacing: 0) {
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height
                    let padTop: CGFloat = 12
                    let padBottom: CGFloat = 44
                    let chartW = w
                    let chartH = h - padTop - padBottom

                    ZStack(alignment: .topLeading) {
                        ForEach(0..<5, id: \.self) { i in
                            let y = padTop + chartH * CGFloat(i) / 4.0
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: w, y: y))
                            }
                            .stroke(Color.white.opacity(0.035), lineWidth: 0.5)
                        }

                        withoutAreaFill(chartW: chartW, chartH: chartH, padTop: padTop)
                        withAbMaxxAreaFill(chartW: chartW, chartH: chartH, padTop: padTop)

                        withoutLine(chartW: chartW, chartH: chartH, padTop: padTop)
                        withAbMaxxLine(chartW: chartW, chartH: chartH, padTop: padTop)

                        withAbMaxxDots(chartW: chartW, chartH: chartH, padTop: padTop)

                        if endLabelOpacity > 0 {
                            let abMaxxEndY = padTop + chartH * withAbMaxxPoints.last!
                            let withoutEndY = padTop + chartH * withoutPoints.last!

                            endLabel(text: "With AbMaxx", color: accentBlue, x: chartW, y: abMaxxEndY, alignment: .bottomTrailing)
                            endLabel(text: "Without", color: failRed.opacity(0.7), x: chartW, y: withoutEndY, alignment: .topTrailing)
                        }

                        HStack {
                            Text("NOW")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.3))
                                .tracking(1.5)
                            Spacer()
                            Text("48 DAYS")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.3))
                                .tracking(1.5)
                        }
                        .offset(y: h - 16)
                    }
                }
                .frame(height: 240)
                .padding(.horizontal, 4)
            }
            .padding(20)
            .padding(.top, 4)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.025))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
                    )
            )
            .padding(.horizontal, 24)

            Spacer().frame(height: 32)

            VStack(spacing: 14) {
                HStack(spacing: 20) {
                    statPill(value: "3x", label: "Faster results", icon: "bolt.fill")
                    statPill(value: "48", label: "Day transformation", icon: "calendar")
                }

                Text("AbMaxx users build visible abs definition 3x faster\nwith AI-guided training targeted to their weak points.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .opacity(bottomOpacity)
            .padding(.horizontal, 24)

            Spacer()
        }
        .onAppear { runAnimationSequence() }
    }

    private func statPill(value: String, label: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(accentBlue)
            Text(value)
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.muted)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.04))
        .clipShape(.capsule)
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5))
    }

    private func endLabel(text: String, color: Color, x: CGFloat, y: CGFloat, alignment: Alignment) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(.rect(cornerRadius: 6))
            .opacity(endLabelOpacity)
            .position(x: x - 42, y: alignment == .topTrailing ? y + 16 : y - 16)
    }

    private func withoutLine(chartW: CGFloat, chartH: CGFloat, padTop: CGFloat) -> some View {
        Path { path in
            let pts = withoutPoints.enumerated().map { i, y in
                CGPoint(x: chartW * CGFloat(i) / CGFloat(withoutPoints.count - 1), y: padTop + chartH * y)
            }
            guard pts.count > 1 else { return }
            path.move(to: pts[0])
            for i in 1..<pts.count {
                let prev = pts[i - 1]; let curr = pts[i]
                let midX = (prev.x + curr.x) / 2
                path.addCurve(to: curr, control1: CGPoint(x: midX, y: prev.y), control2: CGPoint(x: midX, y: curr.y))
            }
        }
        .trim(from: 0, to: withoutLineProgress)
        .stroke(failRed.opacity(0.6), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [6, 4]))
    }

    private func withoutAreaFill(chartW: CGFloat, chartH: CGFloat, padTop: CGFloat) -> some View {
        Path { path in
            let pts = withoutPoints.enumerated().map { i, y in
                CGPoint(x: chartW * CGFloat(i) / CGFloat(withoutPoints.count - 1), y: padTop + chartH * y)
            }
            guard pts.count > 1 else { return }
            path.move(to: CGPoint(x: pts[0].x, y: padTop + chartH))
            path.addLine(to: pts[0])
            for i in 1..<pts.count {
                let prev = pts[i - 1]; let curr = pts[i]
                let midX = (prev.x + curr.x) / 2
                path.addCurve(to: curr, control1: CGPoint(x: midX, y: prev.y), control2: CGPoint(x: midX, y: curr.y))
            }
            if let last = pts.last { path.addLine(to: CGPoint(x: last.x, y: padTop + chartH)) }
            path.closeSubpath()
        }
        .fill(LinearGradient(colors: [failRed.opacity(0.06), failRed.opacity(0.01), .clear], startPoint: .top, endPoint: .bottom))
        .opacity(withoutLineProgress > 0.1 ? 1 : 0)
        .animation(.easeIn(duration: 0.6), value: withoutLineProgress)
    }

    private func withAbMaxxLine(chartW: CGFloat, chartH: CGFloat, padTop: CGFloat) -> some View {
        Path { path in
            let pts = withAbMaxxPoints.enumerated().map { i, y in
                CGPoint(x: chartW * CGFloat(i) / CGFloat(withAbMaxxPoints.count - 1), y: padTop + chartH * y)
            }
            guard pts.count > 1 else { return }
            path.move(to: pts[0])
            for i in 1..<pts.count {
                let prev = pts[i - 1]; let curr = pts[i]
                let midX = (prev.x + curr.x) / 2
                path.addCurve(to: curr, control1: CGPoint(x: midX, y: prev.y), control2: CGPoint(x: midX, y: curr.y))
            }
        }
        .trim(from: 0, to: lineProgress)
        .stroke(
            LinearGradient(colors: [accentBlue, Color(red: 0.15, green: 0.75, blue: 1.0)], startPoint: .leading, endPoint: .trailing),
            style: StrokeStyle(lineWidth: 3, lineCap: .round)
        )
        .shadow(color: accentBlue.opacity(glowPulse ? 0.7 : 0.3), radius: glowPulse ? 16 : 8)
    }

    private func withAbMaxxAreaFill(chartW: CGFloat, chartH: CGFloat, padTop: CGFloat) -> some View {
        Path { path in
            let pts = withAbMaxxPoints.enumerated().map { i, y in
                CGPoint(x: chartW * CGFloat(i) / CGFloat(withAbMaxxPoints.count - 1), y: padTop + chartH * y)
            }
            guard pts.count > 1 else { return }
            path.move(to: CGPoint(x: pts[0].x, y: padTop + chartH))
            path.addLine(to: pts[0])
            for i in 1..<pts.count {
                let prev = pts[i - 1]; let curr = pts[i]
                let midX = (prev.x + curr.x) / 2
                path.addCurve(to: curr, control1: CGPoint(x: midX, y: prev.y), control2: CGPoint(x: midX, y: curr.y))
            }
            if let last = pts.last { path.addLine(to: CGPoint(x: last.x, y: padTop + chartH)) }
            path.closeSubpath()
        }
        .fill(LinearGradient(colors: [accentBlue.opacity(0.15), accentBlue.opacity(0.04), .clear], startPoint: .top, endPoint: .bottom))
        .opacity(lineProgress > 0.1 ? 1 : 0)
        .animation(.easeIn(duration: 0.8), value: lineProgress)
    }

    private func withAbMaxxDots(chartW: CGFloat, chartH: CGFloat, padTop: CGFloat) -> some View {
        ForEach(Array(withAbMaxxPoints.enumerated()), id: \.offset) { index, yVal in
            let x = chartW * CGFloat(index) / CGFloat(withAbMaxxPoints.count - 1)
            let y = padTop + chartH * yVal
            let progress = CGFloat(index) / CGFloat(withAbMaxxPoints.count - 1)

            Circle()
                .fill(Color.white)
                .frame(width: 6, height: 6)
                .shadow(color: accentBlue.opacity(0.8), radius: 6)
                .scaleEffect(lineProgress > progress ? dotScale : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.5), value: dotScale)
                .position(x: x, y: y)
        }
    }

    private func runAnimationSequence() {
        Task {
            withAnimation(.easeIn(duration: 0.2)) { labelOpacity = 1 }

            try? await Task.sleep(for: .milliseconds(50))

            withAnimation(.easeInOut(duration: 1.0)) { withoutLineProgress = 1 }

            try? await Task.sleep(for: .milliseconds(200))

            withAnimation(.easeOut(duration: 1.4)) { lineProgress = 1 }

            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.2)) { dotScale = 1 }

            try? await Task.sleep(for: .milliseconds(1000))

            withAnimation(.easeIn(duration: 0.4)) { endLabelOpacity = 1 }

            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) { glowPulse = true }

            withAnimation(.easeIn(duration: 0.4)) { bottomOpacity = 1 }
        }
    }
}
