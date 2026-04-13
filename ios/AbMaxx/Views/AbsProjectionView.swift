import SwiftUI

struct AbsProjectionView: View {
    let vm: AppViewModel

    private var projection: AbsProjection { vm.absProjection }
    private var goalLevel: AbsGoalLevel { vm.absGoalLevel }
    private var progress: Double { vm.absProjectionProgress }
    private var scan: ScanResult? { vm.latestScan }

    private var currentStructure: AbsStructure {
        scan?.absStructure ?? .flat
    }

    private var goalStructureLabel: String {
        goalLevel.rawValue
    }

    private var projectedWeeks: Int {
        projection.projectedWeeks
    }

    private var projectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: projection.projectedDate)
    }

    private var goalColor: Color {
        switch goalLevel {
        case .visibleAbs: return AppTheme.primaryAccent
        case .fourPack: return AppTheme.success
        case .sixPack: return AppTheme.warning
        case .shreddedSixPack: return Color(red: 1.0, green: 0.4, blue: 0.2)
        }
    }

    private var timelineStages: [(label: String, structure: AbsStructure, targetScore: Int)] {
        switch goalLevel {
        case .visibleAbs:
            return [
                ("Flat", .flat, 0),
                ("Visible", .twoPack, 45)
            ]
        case .fourPack:
            return [
                ("Flat", .flat, 0),
                ("Visible", .twoPack, 30),
                ("4-Pack", .fourPack, 60)
            ]
        case .sixPack:
            return [
                ("Flat", .flat, 0),
                ("2-Pack", .twoPack, 25),
                ("4-Pack", .fourPack, 50),
                ("6-Pack", .sixPack, 75)
            ]
        case .shreddedSixPack:
            return [
                ("Flat", .flat, 0),
                ("4-Pack", .fourPack, 35),
                ("6-Pack", .sixPack, 65),
                ("Shredded", .eightPack, 88)
            ]
        }
    }

    private var currentStageIndex: Int {
        let score = projection.currentScore
        var idx = 0
        for (i, stage) in timelineStages.enumerated() {
            if score >= stage.targetScore {
                idx = i
            }
        }
        return idx
    }

    private var paceStatus: (label: String, icon: String, color: Color) {
        let wRate = projection.workoutAdherenceRate
        let nRate = projection.nutritionAdherenceRate
        let avg = (wRate + nRate) / 2.0

        if avg >= 0.82 {
            return ("Ahead of pace", "flame.fill", AppTheme.success)
        } else if avg >= 0.6 {
            return ("On pace", "arrow.right", AppTheme.warning)
        } else {
            return ("Behind pace", "exclamationmark.triangle.fill", AppTheme.destructive)
        }
    }

    private var actionableInsight: String {
        let wRate = projection.workoutAdherenceRate
        let nRate = projection.nutritionAdherenceRate

        if projection.trackedDaysLast30 == 0 && projection.scheduledWorkoutsLast30 == 0 {
            return "Start training and tracking meals to build your projection"
        }

        switch projection.limitingFactor {
        case .bodyFat:
            let daysSaved = Int(projection.daysAddedByNutrition)
            if daysSaved > 7 {
                return "Body fat is your bottleneck — staying in deficit saves you ~\(daysSaved / 7) weeks"
            }
            if nRate < 0.7 {
                return "Nutrition consistency is slowing fat loss — tighten your deficit to speed up"
            }
            return "Body fat is your limiting factor — stay in deficit to reveal more definition"
        case .muscleScore:
            let daysAdded = Int(projection.daysAddedByMissedWorkouts)
            if daysAdded > 7 {
                return "Missed workouts added ~\(daysAdded / 7) weeks to your timeline"
            }
            if wRate < 0.7 {
                return "Training consistency is key — hit your workouts to build definition faster"
            }
            return "Muscle development is your limiting factor — keep training for more definition"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            heroSection
                .padding(.bottom, 20)

            timelineSection
                .padding(.bottom, 20)

            factorsSection
                .padding(.bottom, 16)

            insightSection
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(AppTheme.cardSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(
                    LinearGradient(
                        colors: [goalColor.opacity(0.25), goalColor.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: paceStatus.icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(paceStatus.color)
                Text(paceStatus.label)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(paceStatus.color)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(paceStatus.color.opacity(0.1))
            .clipShape(Capsule())

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("~\(projectedWeeks)")
                    .font(.system(size: 52, weight: .black))
                    .foregroundStyle(.white)
                Text("weeks")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Text("to \(goalStructureLabel)")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(goalColor)

            Text(projectedDateString)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(AppTheme.muted)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Timeline

    private var timelineSection: some View {
        VStack(spacing: 12) {
            GeometryReader { geo in
                let totalWidth = geo.size.width
                let stageCount = timelineStages.count
                let spacing = stageCount > 1 ? totalWidth / CGFloat(stageCount - 1) : totalWidth

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 6)

                    let fillFraction: CGFloat = stageCount > 1
                        ? (CGFloat(currentStageIndex) + CGFloat(progressWithinStage)) / CGFloat(stageCount - 1)
                        : 0
                    let fillWidth = max(totalWidth * min(fillFraction, 1.0), 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [goalColor.opacity(0.6), goalColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: fillWidth, height: 6)

                    ForEach(0..<stageCount, id: \.self) { i in
                        let x = stageCount > 1 ? spacing * CGFloat(i) : 0
                        let isReached = i <= currentStageIndex
                        let isCurrent = i == currentStageIndex
                        let isGoal = i == stageCount - 1

                        Circle()
                            .fill(isReached ? goalColor : Color.white.opacity(0.12))
                            .frame(width: isCurrent ? 14 : (isGoal ? 12 : 10), height: isCurrent ? 14 : (isGoal ? 12 : 10))
                            .overlay {
                                if isCurrent {
                                    Circle()
                                        .strokeBorder(.white.opacity(0.4), lineWidth: 2)
                                }
                            }
                            .shadow(color: isReached ? goalColor.opacity(0.4) : .clear, radius: 4)
                            .position(x: x, y: 3)
                    }
                }
                .frame(height: 14)
                .padding(.horizontal, 6)
            }
            .frame(height: 14)

            HStack {
                ForEach(0..<timelineStages.count, id: \.self) { i in
                    let stage = timelineStages[i]
                    let isCurrent = i == currentStageIndex
                    let isGoal = i == timelineStages.count - 1

                    Text(stage.label)
                        .font(.system(size: isCurrent ? 11 : 10, weight: isCurrent ? .heavy : .medium))
                        .foregroundStyle(
                            isCurrent ? .white :
                            (i < currentStageIndex ? goalColor.opacity(0.7) :
                             (isGoal ? goalColor : AppTheme.muted))
                        )

                    if i < timelineStages.count - 1 {
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var progressWithinStage: Double {
        let stages = timelineStages
        let idx = currentStageIndex
        guard idx < stages.count - 1 else { return 0 }
        let currentThreshold = stages[idx].targetScore
        let nextThreshold = stages[idx + 1].targetScore
        let gap = nextThreshold - currentThreshold
        guard gap > 0 else { return 0 }
        let scoreInStage = projection.currentScore - currentThreshold
        return min(max(Double(scoreInStage) / Double(gap), 0), 0.99)
    }

    // MARK: - Factors

    private var factorsSection: some View {
        HStack(spacing: 10) {
            factorGauge(
                icon: "flame.fill",
                label: "Body Fat",
                current: String(format: "%.0f%%", projection.currentBodyFat),
                target: String(format: "%.0f%%", projection.targetBodyFat),
                progress: bodyFatProgress,
                color: AppTheme.destructive,
                isLimiting: projection.limitingFactor == .bodyFat
            )

            factorGauge(
                icon: "dumbbell.fill",
                label: "Muscle",
                current: "\(projection.currentScore)",
                target: "\(projection.targetScore)",
                progress: muscleProgress,
                color: AppTheme.primaryAccent,
                isLimiting: projection.limitingFactor == .muscleScore
            )
        }
    }

    private var bodyFatProgress: Double {
        let total = projection.currentBodyFat - projection.targetBodyFat
        guard total > 0 else { return 1.0 }
        let _ = projection.currentBodyFat - projection.currentBodyFat
        return min(max(1.0 - (projection.bfToLose / max(total, 0.1)), 0), 1.0)
    }

    private var muscleProgress: Double {
        let target = projection.targetScore
        guard target > 0 else { return 0 }
        return min(max(Double(projection.currentScore) / Double(target), 0), 1.0)
    }

    private func factorGauge(icon: String, label: String, current: String, target: String, progress: Double, color: Color, isLimiting: Bool) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                if isLimiting {
                    Text("BOTTLENECK")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundStyle(AppTheme.warning)
                        .tracking(0.5)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(AppTheme.warning.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 8)

                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.5), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(geo.size.width * progress, 4), height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text(current)
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppTheme.muted)
                Spacer()
                Text(target)
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(color)
            }
        }
        .padding(14)
        .background(color.opacity(0.04))
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(color.opacity(isLimiting ? 0.25 : 0.1), lineWidth: isLimiting ? 1.5 : 1)
        )
    }

    // MARK: - Insight

    private var insightSection: some View {
        HStack(spacing: 10) {
            Image(systemName: insightIcon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(insightColor)
                .frame(width: 20)

            Text(actionableInsight)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(insightColor)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(insightColor.opacity(0.08))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var insightIcon: String {
        switch projection.limitingFactor {
        case .bodyFat: return "fork.knife"
        case .muscleScore: return "dumbbell.fill"
        }
    }

    private var insightColor: Color {
        let avg = (projection.workoutAdherenceRate + projection.nutritionAdherenceRate) / 2.0
        if avg >= 0.8 { return AppTheme.success }
        if avg >= 0.55 { return AppTheme.warning }
        return AppTheme.destructive
    }
}
