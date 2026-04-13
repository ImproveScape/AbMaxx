import SwiftUI

struct TodayProgressRingsView: View {
    let exerciseDone: Int
    let exerciseTotal: Int
    let nutritionDone: Int
    let nutritionTotal: Int
    let mindsetDone: Int
    let mindsetTotal: Int
    let caloriesEaten: Int
    let calorieGoal: Int
    let proteinEaten: Double
    let proteinGoal: Double
    let waterGlasses: Int
    let waterGoal: Int
    @State private var animateRings: Bool = false

    private var overallProgress: Double {
        let total = exerciseTotal + nutritionTotal + mindsetTotal
        guard total > 0 else { return 0 }
        return Double(exerciseDone + nutritionDone + mindsetDone) / Double(total)
    }

    private var exerciseProgress: Double {
        guard exerciseTotal > 0 else { return 0 }
        return min(Double(exerciseDone) / Double(exerciseTotal), 1.0)
    }

    private var nutritionProgress: Double {
        guard nutritionTotal > 0 else { return 0 }
        return min(Double(nutritionDone) / Double(nutritionTotal), 1.0)
    }

    private var mindsetProgress: Double {
        guard mindsetTotal > 0 else { return 0 }
        return min(Double(mindsetDone) / Double(mindsetTotal), 1.0)
    }

    private let exerciseColor = AppTheme.primaryAccent
    private let nutritionColor = AppTheme.success
    private let mindsetColor = Color(red: 1.0, green: 0.6, blue: 0.15)

    private var allComplete: Bool {
        let total = exerciseTotal + nutritionTotal + mindsetTotal
        guard total > 0 else { return false }
        return (exerciseDone + nutritionDone + mindsetDone) >= total
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Today's Progress")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                if allComplete {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                        Text("Complete")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(AppTheme.success)
                } else {
                    Text("\(Int(overallProgress * 100))%")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(AppTheme.muted)
                }
            }

            HStack(spacing: 0) {
                ZStack {
                    ringTrack(radius: 48)
                    ringFill(radius: 48, progress: exerciseProgress, color: exerciseColor)
                    ringTrack(radius: 36)
                    ringFill(radius: 36, progress: nutritionProgress, color: nutritionColor)
                    ringTrack(radius: 24)
                    ringFill(radius: 24, progress: mindsetProgress, color: mindsetColor)

                    if allComplete {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 110, height: 110)

                Spacer(minLength: 16)

                VStack(spacing: 10) {
                    ringRow(
                        color: exerciseColor,
                        icon: "figure.core.training",
                        title: "Exercise",
                        done: exerciseDone,
                        total: exerciseTotal
                    )
                    ringRow(
                        color: nutritionColor,
                        icon: "leaf.fill",
                        title: "Nutrition",
                        done: nutritionDone,
                        total: nutritionTotal
                    )
                    ringRow(
                        color: mindsetColor,
                        icon: "brain.head.profile.fill",
                        title: "Mindset",
                        done: mindsetDone,
                        total: mindsetTotal
                    )
                }
            }

            separator

            HStack(spacing: 0) {
                macroStat(
                    icon: "flame.fill",
                    value: "\(caloriesEaten)",
                    label: "/ \(calorieGoal) cal",
                    color: caloriesEaten <= calorieGoal ? AppTheme.primaryAccent : AppTheme.destructive
                )
                macroDivider
                macroStat(
                    icon: "bolt.fill",
                    value: "\(Int(proteinEaten))g",
                    label: "/ \(Int(proteinGoal))g protein",
                    color: proteinEaten >= proteinGoal ? AppTheme.success : AppTheme.secondaryText
                )
                macroDivider
                macroStat(
                    icon: "drop.fill",
                    value: "\(waterGlasses)",
                    label: "/ \(waterGoal) glasses",
                    color: waterGlasses >= waterGoal ? AppTheme.primaryAccent : AppTheme.secondaryText
                )
            }
        }
        .padding(18)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 18))
        .onAppear {
            withAnimation(.spring(duration: 1.0).delay(0.2)) {
                animateRings = true
            }
        }
    }

    private var separator: some View {
        Rectangle()
            .fill(Color.white.opacity(0.04))
            .frame(height: 1)
    }

    private var macroDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(width: 1, height: 32)
    }

    private func macroStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(color)
                Text(value)
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(.white)
            }
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.muted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private func ringTrack(radius: CGFloat) -> some View {
        Circle()
            .stroke(Color.white.opacity(0.06), style: StrokeStyle(lineWidth: 7, lineCap: .round))
            .frame(width: radius * 2, height: radius * 2)
    }

    private func ringFill(radius: CGFloat, progress: Double, color: Color) -> some View {
        Circle()
            .trim(from: 0, to: animateRings ? progress : 0)
            .stroke(
                AngularGradient(
                    colors: [color, color.opacity(0.6), color],
                    center: .center,
                    startAngle: .degrees(0),
                    endAngle: .degrees(360)
                ),
                style: StrokeStyle(lineWidth: 7, lineCap: .round)
            )
            .frame(width: radius * 2, height: radius * 2)
            .rotationEffect(.degrees(-90))
            .shadow(color: color.opacity(animateRings && progress > 0 ? 0.35 : 0), radius: 4)
    }

    private func ringRow(color: Color, icon: String, title: String, done: Int, total: Int) -> some View {
        let isComplete = done >= total && total > 0
        return HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 3, height: 20)

            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 16)

            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            if isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(color)
            } else {
                Text("\(done)/\(total)")
                    .font(.system(size: 13, weight: .bold, design: .default))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }
}
