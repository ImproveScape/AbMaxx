import SwiftUI

struct GrowthChartSlide: View {
    let onBack: () -> Void
    let onNext: () -> Void
    let currentPage: Int
    let totalPages: Int

    @State private var animateChart: Bool = false
    @State private var animateGlow: Bool = false
    @State private var showLabels: Bool = false
    @State private var showStats: Bool = false
    @State private var pulseEndpoint: Bool = false

    private let weekLabels = ["Now", "Week 4", "Week 8", "Week 12"]
    private let scoreValues: [CGFloat] = [0.18, 0.38, 0.62, 0.9]
    private let milestones = [
        (week: "Week 4", label: "Core Activation", icon: "flame.fill"),
        (week: "Week 8", label: "Visible Definition", icon: "eye.fill"),
        (week: "Week 12", label: "Peak AbMaxx", icon: "crown.fill"),
    ]

    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.primaryAccent.opacity(0.06))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(y: -50)

            VStack(spacing: 0) {
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)

                Spacer().frame(minHeight: 12, maxHeight: 20)

                VStack(spacing: 4) {
                    Text("Your Growth")
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundStyle(.white)

                    Text("What AbMaxx users achieve")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .opacity(showLabels ? 1 : 0)
                .offset(y: showLabels ? 0 : 10)

                Spacer().frame(minHeight: 12, maxHeight: 20)

                chartCard
                    .padding(.horizontal, 20)

                Spacer().frame(minHeight: 12, maxHeight: 16)

                milestonesRow
                    .padding(.horizontal, 20)
                    .opacity(showStats ? 1 : 0)
                    .offset(y: showStats ? 0 : 16)

                Spacer().frame(minHeight: 10, maxHeight: 14)

                statCards
                    .padding(.horizontal, 20)
                    .opacity(showStats ? 1 : 0)
                    .offset(y: showStats ? 0 : 16)

                Spacer(minLength: 12)

                Button(action: onNext) {
                    Text("Start Your Journey")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.primaryAccent)
                        .clipShape(.capsule)
                        .shadow(color: AppTheme.primaryAccent.opacity(0.5), radius: 24, y: 6)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)

                pageDots
                    .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showLabels = true
            }
            withAnimation(.spring(duration: 1.4, bounce: 0.1).delay(0.3)) {
                animateChart = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(1.0)) {
                showStats = true
            }
            withAnimation(.easeInOut(duration: 1.5).delay(1.5).repeatForever(autoreverses: true)) {
                pulseEndpoint = true
            }
            withAnimation(.easeInOut(duration: 2.0).delay(1.5).repeatForever(autoreverses: true)) {
                animateGlow = true
            }
        }
    }

    private var chartCard: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                let w = geo.size.width - 48
                let h = geo.size.height - 40
                let originX: CGFloat = 24
                let originY: CGFloat = h

                ZStack {
                    ForEach(0..<4, id: \.self) { i in
                        let y = originY - (h * CGFloat(i) / 3)
                        Path { path in
                            path.move(to: CGPoint(x: originX, y: y))
                            path.addLine(to: CGPoint(x: originX + w, y: y))
                        }
                        .stroke(Color.white.opacity(i == 0 ? 0.12 : 0.05), lineWidth: 1)
                    }

                    ForEach(0..<4, id: \.self) { i in
                        let x = originX + (w * CGFloat(i) / 3)
                        Text(weekLabels[i])
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(AppTheme.secondaryText)
                            .position(x: x, y: originY + 16)
                    }

                    let gradientPath = Path { path in
                        path.move(to: CGPoint(x: originX, y: originY))
                        for i in 0..<scoreValues.count {
                            let x = originX + (w * CGFloat(i) / CGFloat(scoreValues.count - 1))
                            let y = originY - (h * scoreValues[i])
                            if i == 0 {
                                path.addLine(to: CGPoint(x: x, y: y))
                            } else {
                                let prevX = originX + (w * CGFloat(i - 1) / CGFloat(scoreValues.count - 1))
                                let prevY = originY - (h * scoreValues[i - 1])
                                let cp1 = CGPoint(x: prevX + (x - prevX) * 0.4, y: prevY)
                                let cp2 = CGPoint(x: prevX + (x - prevX) * 0.6, y: y)
                                path.addCurve(to: CGPoint(x: x, y: y), control1: cp1, control2: cp2)
                            }
                        }
                        let lastX = originX + w
                        path.addLine(to: CGPoint(x: lastX, y: originY))
                        path.closeSubpath()
                    }

                    gradientPath
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppTheme.primaryAccent.opacity(0.25),
                                    AppTheme.primaryAccent.opacity(0.08),
                                    AppTheme.primaryAccent.opacity(0.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .mask(
                            Rectangle()
                                .scaleEffect(x: animateChart ? 1 : 0, anchor: .leading)
                        )

                    let linePath = Path { path in
                        for i in 0..<scoreValues.count {
                            let x = originX + (w * CGFloat(i) / CGFloat(scoreValues.count - 1))
                            let y = originY - (h * scoreValues[i])
                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                let prevX = originX + (w * CGFloat(i - 1) / CGFloat(scoreValues.count - 1))
                                let prevY = originY - (h * scoreValues[i - 1])
                                let cp1 = CGPoint(x: prevX + (x - prevX) * 0.4, y: prevY)
                                let cp2 = CGPoint(x: prevX + (x - prevX) * 0.6, y: y)
                                path.addCurve(to: CGPoint(x: x, y: y), control1: cp1, control2: cp2)
                            }
                        }
                    }

                    linePath
                        .trim(from: 0, to: animateChart ? 1 : 0)
                        .stroke(
                            LinearGradient(
                                colors: [AppTheme.primaryAccent, AppTheme.primaryAccent.opacity(0.8), Color(red: 0.4, green: 0.85, blue: 1.0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                        )

                    ForEach(0..<scoreValues.count, id: \.self) { i in
                        let x = originX + (w * CGFloat(i) / CGFloat(scoreValues.count - 1))
                        let y = originY - (h * scoreValues[i])
                        let isLast = i == scoreValues.count - 1

                        if isLast {
                            Circle()
                                .fill(AppTheme.primaryAccent.opacity(0.2))
                                .frame(width: pulseEndpoint ? 26 : 16, height: pulseEndpoint ? 26 : 16)
                                .position(x: x, y: y)
                                .opacity(animateChart ? 1 : 0)
                        }

                        Circle()
                            .fill(AppTheme.background)
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .fill(isLast ? Color(red: 0.4, green: 0.85, blue: 1.0) : AppTheme.primaryAccent)
                                    .frame(width: 6, height: 6)
                            )
                            .position(x: x, y: y)
                            .opacity(animateChart ? 1 : 0)
                    }
                }
            }
            .frame(height: 170)
            .padding(.top, 12)
            .padding(.bottom, 6)
        }
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardSurface)
                .shadow(color: animateGlow ? AppTheme.primaryAccent.opacity(0.12) : AppTheme.primaryAccent.opacity(0.04), radius: 30, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(
                        colors: [AppTheme.blueBorder, AppTheme.border],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private var milestonesRow: some View {
        HStack(spacing: 6) {
            ForEach(Array(milestones.enumerated()), id: \.offset) { index, milestone in
                VStack(spacing: 4) {
                    Image(systemName: milestone.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(
                            index == 2 ? Color(red: 1.0, green: 0.84, blue: 0.3) :
                            index == 1 ? Color(red: 0.4, green: 0.85, blue: 1.0) :
                            AppTheme.primaryAccent
                        )

                    Text(milestone.label)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(milestone.week)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.cardSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(AppTheme.border, lineWidth: 1)
                )
            }
        }
    }

    private var statCards: some View {
        HStack(spacing: 10) {
            statPill(value: "3.5x", label: "Faster Results", color: AppTheme.success)
            statPill(value: "12 wk", label: "Full Transform", color: AppTheme.primaryAccent)
        }
    }

    private func statPill(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.cardSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(AppTheme.border, lineWidth: 1)
        )
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? AppTheme.primaryAccent : Color.white.opacity(0.2))
                    .frame(width: 8, height: 8)
            }
        }
    }
}
