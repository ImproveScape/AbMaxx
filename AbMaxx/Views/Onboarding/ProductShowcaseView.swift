import SwiftUI

struct ProductShowcaseView: View {
    let page: Int
    let onContinue: () -> Void

    @State private var phase: Int = 0

    private var config: ShowcaseConfig {
        switch page {
        case 0: return .aiScanner
        case 1: return .personalizedTraining
        case 2: return .progressTracking
        default: return .nutritionTracking
        }
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            AppTheme.onboardingGradient.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text(config.category)
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(config.accentColor)
                    .tracking(2)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .opacity(phase >= 1 ? 1 : 0)
                    .animation(.easeOut(duration: 0.4), value: phase)

                Spacer(minLength: 12)

                HStack {
                    Spacer()
                    phoneMockup
                        .frame(maxWidth: 220)
                    Spacer()
                }
                .opacity(phase >= 1 ? 1 : 0)
                .scaleEffect(phase >= 1 ? 1 : 0.92)
                .animation(.spring(duration: 0.7, bounce: 0.1), value: phase)

                Spacer(minLength: 16)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(config.accentColor.opacity(0.15))
                                .frame(width: 28, height: 28)
                            Image(systemName: config.icon)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(config.accentColor)
                        }
                        Text(config.category)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppTheme.secondaryText)
                            .tracking(1)
                    }
                    .padding(.bottom, 10)
                    .opacity(phase >= 2 ? 1 : 0)
                    .offset(y: phase >= 2 ? 0 : 8)
                    .animation(.easeOut(duration: 0.4), value: phase)

                    Text(config.title)
                        .font(.system(size: 30, weight: .black))
                        .foregroundStyle(.white)
                        .lineSpacing(2)
                        .padding(.bottom, 8)
                        .opacity(phase >= 2 ? 1 : 0)
                        .offset(y: phase >= 2 ? 0 : 10)
                        .animation(.easeOut(duration: 0.5).delay(0.1), value: phase)

                    Text(config.tagline)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(config.accentColor)
                        .padding(.bottom, 6)
                        .opacity(phase >= 3 ? 1 : 0)
                        .offset(y: phase >= 3 ? 0 : 6)
                        .animation(.easeOut(duration: 0.4), value: phase)

                    Text(config.description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineSpacing(3)
                        .opacity(phase >= 3 ? 1 : 0)
                        .offset(y: phase >= 3 ? 0 : 6)
                        .animation(.easeOut(duration: 0.4).delay(0.1), value: phase)
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 20)

                Button(action: onContinue) {
                    HStack(spacing: 8) {
                        Text("Continue")
                            .font(.system(size: 17, weight: .bold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(AppTheme.primaryAccent)
                    .clipShape(.capsule)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 44)
                .opacity(phase >= 4 ? 1 : 0)
                .offset(y: phase >= 4 ? 0 : 12)
                .animation(.spring(duration: 0.5), value: phase)
            }
        }
        .onAppear {
            Task {
                try? await Task.sleep(for: .milliseconds(100))
                withAnimation { phase = 1 }
                try? await Task.sleep(for: .milliseconds(300))
                withAnimation { phase = 2 }
                try? await Task.sleep(for: .milliseconds(250))
                withAnimation { phase = 3 }
                try? await Task.sleep(for: .milliseconds(200))
                withAnimation { phase = 4 }
            }
        }
    }

    private var phoneMockup: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32)
                .fill(Color(red: 20/255, green: 20/255, blue: 30/255))
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.5), radius: 30, y: 10)

            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black)
                    .frame(width: 60, height: 18)
                    .padding(.top, 8)

                config.mockContent
                    .padding(.horizontal, 8)
                    .padding(.top, 6)

                Spacer(minLength: 0)

                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 80, height: 5)
                    .padding(.bottom, 6)
            }
            .clipShape(.rect(cornerRadius: 30))
        }
        .aspectRatio(0.48, contentMode: .fit)
    }
}

private struct ShowcaseConfig {
    let category: String
    let icon: String
    let title: String
    let tagline: String
    let description: String
    let accentColor: Color
    let mockContent: AnyView

    static let aiScanner = ShowcaseConfig(
        category: "AI BODY SCAN",
        icon: "viewfinder",
        title: "See What The\nMirror Can't",
        tagline: "Your exact score in 3 seconds.",
        description: "Most people train abs for years and never know where they actually stand. One scan reveals your precise weak points — so every rep counts.",
        accentColor: AppTheme.primaryAccent,
        mockContent: AnyView(ScannerMockScreen())
    )

    static let personalizedTraining = ShowcaseConfig(
        category: "YOUR PLAN",
        icon: "figure.core.training",
        title: "Built For Your\nBody, Not Theirs",
        tagline: "No more guessing what works.",
        description: "Generic ab workouts waste your time. AbMaxx builds a plan around your scan results — targeting your weakest zones first for visible results faster.",
        accentColor: AppTheme.primaryAccent,
        mockContent: AnyView(TrainingMockScreen())
    )

    static let progressTracking = ShowcaseConfig(
        category: "RESULTS",
        icon: "chart.line.uptrend.xyaxis",
        title: "Proof You're\nActually Growing",
        tagline: "Watch your score climb weekly.",
        description: "Stop wondering if it's working. Scan-to-scan comparisons show exactly how much you've improved — the kind of clarity that keeps you locked in.",
        accentColor: AppTheme.success,
        mockContent: AnyView(ProgressMockScreen())
    )

    static let nutritionTracking = ShowcaseConfig(
        category: "FUEL",
        icon: "flame.fill",
        title: "Abs Are Built\nIn The Kitchen",
        tagline: "Nail your calories. Reveal your abs.",
        description: "Training alone won't cut it — 70% of visible abs comes from nutrition. Track every meal in seconds with AI-powered food scanning, and watch the fat melt off your midsection.",
        accentColor: AppTheme.orange,
        mockContent: AnyView(NutritionMockScreen())
    )
}

private struct ScannerMockScreen: View {
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("AbMaxx Score")
                        .font(.system(size: 7, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text("82")
                            .font(.system(size: 28, weight: .black))
                            .foregroundStyle(.white)
                        Text("/100")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(AppTheme.border, lineWidth: 3)
                        .frame(width: 38, height: 38)
                    Circle()
                        .trim(from: 0, to: 0.82)
                        .stroke(
                            LinearGradient(colors: [AppTheme.primaryAccent, AppTheme.primaryAccent.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 38, height: 38)
                        .rotationEffect(.degrees(-90))
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.primaryAccent)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.cardSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(AppTheme.blueBorder, lineWidth: 1)
                    )
            )

            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.cardSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(AppTheme.border, lineWidth: 1)
                    )
                Image(systemName: "figure.core.training")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(colors: [AppTheme.primaryAccent, AppTheme.primaryAccent.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    )
            }
            .frame(height: 50)

            HStack(spacing: 5) {
                miniZone(name: "Upper", score: "85", color: AppTheme.primaryAccent)
                miniZone(name: "Lower", score: "74", color: AppTheme.primaryAccent)
            }
            HStack(spacing: 5) {
                miniZone(name: "Obliques", score: "79", color: AppTheme.success)
                miniZone(name: "Core", score: "71", color: AppTheme.orange)
            }
        }
    }

    private func miniZone(name: String, score: String, color: Color) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 2, height: 16)
            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .font(.system(size: 6, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                Text(score)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .padding(7)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppTheme.cardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(AppTheme.border, lineWidth: 1)
                )
        )
    }
}

private struct TrainingMockScreen: View {
    private let accentBlue = AppTheme.primaryAccent

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Today's Workout")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Core Destroyer")
                        .font(.system(size: 6, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Spacer()
                Text("16m")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(accentBlue)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(accentBlue.opacity(0.15))
                    .clipShape(.capsule)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.cardSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(accentBlue.opacity(0.25), lineWidth: 1)
                    )
            )

            exerciseRow(name: "Hanging Leg Raise", sets: "3×12", done: true)
            exerciseRow(name: "Cable Crunch", sets: "4×15", done: true)
            exerciseRow(name: "Ab Wheel Rollout", sets: "3×10", done: false)
            exerciseRow(name: "Pallof Press", sets: "3×12", done: false)

            HStack(spacing: 5) {
                statPill(icon: "flame.fill", val: "248", sub: "cal", color: AppTheme.orange)
                statPill(icon: "clock.fill", val: "12:34", sub: "min", color: accentBlue)
                statPill(icon: "checkmark.circle.fill", val: "2/4", sub: "done", color: AppTheme.success)
            }
        }
    }

    private func exerciseRow(name: String, sets: String, done: Bool) -> some View {
        HStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(done ? accentBlue.opacity(0.15) : AppTheme.cardSurface)
                    .frame(width: 22, height: 22)
                Image(systemName: done ? "checkmark" : "figure.core.training")
                    .font(.system(size: done ? 7 : 8, weight: .semibold))
                    .foregroundStyle(done ? AppTheme.success : accentBlue)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .font(.system(size: 7, weight: .semibold))
                    .foregroundStyle(done ? AppTheme.secondaryText : .white)
                    .strikethrough(done, color: AppTheme.secondaryText)
                Text(sets)
                    .font(.system(size: 6, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
        }
        .padding(7)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppTheme.cardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(AppTheme.border, lineWidth: 1)
                )
        )
    }

    private func statPill(icon: String, val: String, sub: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 7))
                .foregroundStyle(color)
            Text(val)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white)
            Text(sub)
                .font(.system(size: 5, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppTheme.cardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(AppTheme.border, lineWidth: 1)
                )
        )
    }
}

private struct NutritionMockScreen: View {
    private let brandOrange = AppTheme.orange
    private let brandRed = Color(red: 0.95, green: 0.3, blue: 0.3)
    private let brandBlue = Color(red: 0.45, green: 0.55, blue: 0.95)

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Calories Left")
                        .font(.system(size: 7, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("1,247")
                            .font(.system(size: 24, weight: .black))
                            .foregroundStyle(.white)
                        Text("/ 2,180")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(AppTheme.border, lineWidth: 3.5)
                        .frame(width: 40, height: 40)
                    Circle()
                        .trim(from: 0, to: 0.43)
                        .stroke(
                            LinearGradient(colors: [brandOrange, brandOrange.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                        )
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))
                    Text("43%")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(brandOrange)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.cardSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(brandOrange.opacity(0.25), lineWidth: 1)
                    )
            )

            HStack(spacing: 4) {
                macroPill(label: "Protein", current: "84", goal: "165", unit: "g", color: brandRed)
                macroPill(label: "Carbs", current: "112", goal: "245", unit: "g", color: brandOrange)
                macroPill(label: "Fat", current: "31", goal: "68", unit: "g", color: brandBlue)
            }

            foodRow(name: "Grilled Chicken Breast", cal: "284", time: "12:30 PM", icon: "\u{1F357}")
            foodRow(name: "Greek Yogurt + Berries", cal: "180", time: "9:15 AM", icon: "\u{1FAD0}")
            foodRow(name: "Protein Shake", cal: "220", time: "7:00 AM", icon: "\u{1F964}")

            HStack(spacing: 4) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 7, weight: .semibold))
                    .foregroundStyle(brandOrange)
                Text("Scan food to log instantly")
                    .font(.system(size: 6, weight: .semibold))
                    .foregroundStyle(brandOrange)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(brandOrange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(brandOrange.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }

    private func macroPill(label: String, current: String, goal: String, unit: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 5, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
            Text("\(current)\(unit)")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.15))
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * (Double(current) ?? 0) / (Double(goal) ?? 1))
                }
            }
            .frame(height: 3)
            Text("/ \(goal)\(unit)")
                .font(.system(size: 5, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppTheme.cardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(AppTheme.border, lineWidth: 1)
                )
        )
    }

    private func foodRow(name: String, cal: String, time: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Text(icon)
                .font(.system(size: 10))
                .frame(width: 20, height: 20)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(AppTheme.cardSurfaceElevated)
                )
            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .font(.system(size: 7, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(time)
                    .font(.system(size: 5, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
            Text("\(cal) cal")
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(brandOrange)
        }
        .padding(7)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppTheme.cardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(AppTheme.border, lineWidth: 1)
                )
        )
    }
}

private struct ProgressMockScreen: View {
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Your Progress")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Last 30 days")
                        .font(.system(size: 6, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Spacer()
                HStack(spacing: 2) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 6, weight: .bold))
                    Text("+12")
                        .font(.system(size: 7, weight: .bold))
                }
                .foregroundStyle(AppTheme.success)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(AppTheme.success.opacity(0.12))
                .clipShape(.capsule)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.cardSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(AppTheme.success.opacity(0.2), lineWidth: 1)
                    )
            )

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.cardSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(AppTheme.border, lineWidth: 1)
                    )

                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(0..<12, id: \.self) { i in
                        let heights: [CGFloat] = [0.25, 0.3, 0.35, 0.33, 0.45, 0.5, 0.47, 0.55, 0.6, 0.65, 0.7, 0.78]
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.success, AppTheme.success.opacity(0.3)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: 40 * heights[i])
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 6)
                .padding(.top, 6)
            }
            .frame(height: 52)

            HStack(spacing: 5) {
                miniStat(icon: "camera.viewfinder", val: "12", label: "Scans", color: AppTheme.primaryAccent)
                miniStat(icon: "flame.fill", val: "18d", label: "Streak", color: AppTheme.orange)
                miniStat(icon: "star.fill", val: "Lv4", label: "Level", color: AppTheme.warning)
            }

            VStack(spacing: 0) {
                milestoneRow(title: "80+ AbMaxx Score", done: true)
                milestoneRow(title: "Complete Phase 2", done: true)
                milestoneRow(title: "30-Day Streak", done: false)
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.cardSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(AppTheme.border, lineWidth: 1)
                    )
            )
        }
    }

    private func miniStat(icon: String, val: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 7))
                .foregroundStyle(color)
            Text(val)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 5, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppTheme.cardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(AppTheme.border, lineWidth: 1)
                )
        )
    }

    private func milestoneRow(title: String, done: Bool) -> some View {
        HStack(spacing: 5) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 8))
                .foregroundStyle(done ? AppTheme.success : AppTheme.muted)
            Text(title)
                .font(.system(size: 7, weight: .medium))
                .foregroundStyle(done ? .white : AppTheme.secondaryText)
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
    }
}
