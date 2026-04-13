import SwiftUI

struct BreakdownInsightsSectionView: View {
    let scan: ScanResult
    let weakestZone: AbRegion
    let strongestZone: AbRegion
    let animateIn: Bool
    let onTrainWeakestZone: () -> Void

    private var weakestScore: Int {
        score(for: weakestZone)
    }

    private var strongestScore: Int {
        score(for: strongestZone)
    }

    private var scoreGap: Int {
        max(strongestScore - weakestScore, 0)
    }

    private var zoneSummaries: [ZoneSummary] {
        let zones: [AbRegion] = [.upperAbs, .lowerAbs, .obliques, .deepCore]
        return zones
            .map { zone in
                ZoneSummary(
                    zone: zone,
                    currentScore: score(for: zone),
                    targetScore: targetScore(for: zone)
                )
            }
            .sorted { lhs, rhs in
                if lhs.currentScore == rhs.currentScore {
                    return lhs.zone.rawValue < rhs.zone.rawValue
                }
                return lhs.currentScore < rhs.currentScore
            }
            .enumerated()
            .map { index, summary in
                ZoneSummary(
                    zone: summary.zone,
                    currentScore: summary.currentScore,
                    targetScore: summary.targetScore,
                    rank: index + 1
                )
            }
    }

    private var weakZoneSummaries: [ZoneSummary] {
        Array(zoneSummaries.prefix(2))
    }

    private var weakZones: Set<AbRegion> {
        Set(weakZoneSummaries.map(\.zone))
    }

    private var potentialOverallScore: Int {
        let zoneTotal: Int = zoneSummaries.reduce(0) { $0 + $1.targetScore }
        let improvedSymmetry: Int = min(max(scan.symmetry + max(4, scoreGap / 2), strongestScore - 2), 95)
        let improvedFrame: Int = min(scan.frame + 4, 95)
        let estimate: Int = Int(round(Double(zoneTotal + improvedSymmetry + improvedFrame) / 6.0))
        return max(estimate, scan.overallScore)
    }

    private var potentialLift: Int {
        max(potentialOverallScore - scan.overallScore, 0)
    }

    private var definitionSignals: [DefinitionSignal] {
        [
            DefinitionSignal(
                title: "Lower Line",
                value: scan.lowerAbsScore,
                style: .lowerLine
            ),
            DefinitionSignal(
                title: "Side Cut",
                value: Int(round(Double(scan.obliquesScore + scan.frame) / 2.0)),
                style: .sideCut
            ),
            DefinitionSignal(
                title: "Core Tightness",
                value: Int(round(Double(scan.deepCoreScore + scan.symmetry) / 2.0)),
                style: .coreTightness
            )
        ]
    }

    var body: some View {
        VStack(spacing: 16) {
            BreakdownPotentialComparisonCard(
                currentScore: scan.overallScore,
                potentialScore: potentialOverallScore,
                potentialLift: potentialLift,
                zoneSummaries: zoneSummaries,
                weakZones: weakZones,
                animateIn: animateIn
            )

            BreakdownWeakAreasCard(
                weakZoneSummaries: weakZoneSummaries,
                allZoneSummaries: zoneSummaries,
                scoreGap: scoreGap,
                animateIn: animateIn,
                onTrainWeakestZone: onTrainWeakestZone
            )

            BreakdownDefinitionSignalsCard(
                signals: definitionSignals,
                animateIn: animateIn
            )
        }
    }

    private func score(for zone: AbRegion) -> Int {
        switch zone {
        case .upperAbs:
            scan.upperAbsScore
        case .lowerAbs:
            scan.lowerAbsScore
        case .obliques:
            scan.obliquesScore
        case .deepCore:
            scan.deepCoreScore
        }
    }

    private func targetScore(for zone: AbRegion) -> Int {
        let currentScore: Int = score(for: zone)
        let floorCatchUp: Int = strongestScore - 2
        let paddedImprovement: Int = currentScore + max(8, scoreGap + 2)
        return min(max(currentScore + 8, min(paddedImprovement, floorCatchUp)), 95)
    }
}

private struct BreakdownPotentialComparisonCard: View {
    let currentScore: Int
    let potentialScore: Int
    let potentialLift: Int
    let zoneSummaries: [ZoneSummary]
    let weakZones: Set<AbRegion>
    let animateIn: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current vs Potential")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(.white)

                    Text("How much your score can move")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("+\(potentialLift)")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(AppTheme.primaryAccent)
                        .contentTransition(.numericText())

                    Text("UPSIDE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(AppTheme.secondaryText)
                        .tracking(1.2)
                }
            }

            HStack(spacing: 10) {
                BreakdownComparisonPanel(
                    title: "Current",
                    score: currentScore,
                    zoneSummaries: zoneSummaries,
                    mode: .current,
                    weakZones: weakZones,
                    animateIn: animateIn
                )

                BreakdownDeltaPill(
                    currentScore: currentScore,
                    potentialScore: potentialScore,
                    animateIn: animateIn
                )

                BreakdownComparisonPanel(
                    title: "Potential",
                    score: potentialScore,
                    zoneSummaries: zoneSummaries,
                    mode: .potential,
                    weakZones: weakZones,
                    animateIn: animateIn
                )
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [AppTheme.primaryAccent.opacity(0.10), AppTheme.card],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: .rect(cornerRadius: AppTheme.cardCornerRadius)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
        )
    }
}

private struct BreakdownComparisonPanel: View {
    let title: String
    let score: Int
    let zoneSummaries: [ZoneSummary]
    let mode: BreakdownComparisonMode
    let weakZones: Set<AbRegion>
    let animateIn: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .lastTextBaseline) {
                Text(title.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .tracking(1.2)

                Spacer(minLength: 8)

                Text("\(score)")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }

            VStack(spacing: 9) {
                ForEach(zoneSummaries) { summary in
                    BreakdownComparisonRow(
                        zone: summary.zone,
                        score: score(for: summary),
                        tint: tint(for: summary),
                        animateIn: animateIn
                    )
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.035), in: .rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private func score(for summary: ZoneSummary) -> Int {
        switch mode {
        case .current:
            summary.currentScore
        case .potential:
            summary.targetScore
        }
    }

    private func tint(for summary: ZoneSummary) -> Color {
        switch mode {
        case .current:
            return weakZones.contains(summary.zone) ? AppTheme.destructive : Color.white.opacity(0.30)
        case .potential:
            return AppTheme.primaryAccent
        }
    }
}

private struct BreakdownComparisonRow: View {
    let zone: AbRegion
    let score: Int
    let tint: Color
    let animateIn: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: zone.icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 14)

                Text(zone.compactLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 8)

                Text("\(score)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.82))
                    .contentTransition(.numericText())
            }

            GeometryReader { proxy in
                let progressWidth: CGFloat = max(16, proxy.size.width * CGFloat(score) / 100.0)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.06))

                    Capsule()
                        .fill(tint)
                        .frame(width: animateIn ? progressWidth : 18)
                        .animation(.spring(duration: 0.7, bounce: 0.12), value: animateIn)
                }
            }
            .frame(height: 6)
        }
    }
}

private struct BreakdownDeltaPill: View {
    let currentScore: Int
    let potentialScore: Int
    let animateIn: Bool

    private var improvement: Int {
        max(potentialScore - currentScore, 0)
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.primaryAccent)
                .offset(x: animateIn ? 0 : -6)
                .opacity(animateIn ? 1 : 0.35)
                .animation(.spring(duration: 0.7, bounce: 0.15).delay(0.12), value: animateIn)

            VStack(spacing: 3) {
                Text("+\(improvement)")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(AppTheme.primaryAccent)
                    .contentTransition(.numericText())

                Text("LIFT")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .tracking(1.2)
            }
        }
        .frame(width: 52)
    }
}

private struct BreakdownWeakAreasCard: View {
    let weakZoneSummaries: [ZoneSummary]
    let allZoneSummaries: [ZoneSummary]
    let scoreGap: Int
    let animateIn: Bool
    let onTrainWeakestZone: () -> Void

    private var weakestZoneName: String {
        weakZoneSummaries.first?.zone.rawValue ?? "Lower Abs"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weakest Areas")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(.white)

                    Text("The zones making your abs look less sharp")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer()

                Text("\(scoreGap) pt gap")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.destructive)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.destructive.opacity(0.12), in: Capsule())
            }

            HStack(spacing: 16) {
                BreakdownWeakZoneMapView(
                    zoneSummaries: allZoneSummaries,
                    animateIn: animateIn
                )
                .frame(width: 110, height: 152)

                VStack(spacing: 12) {
                    ForEach(weakZoneSummaries) { summary in
                        BreakdownWeakZoneRow(
                            summary: summary,
                            animateIn: animateIn
                        )
                    }
                }
            }

            Button(action: onTrainWeakestZone) {
                HStack {
                    Text("Train \(weakestZoneName)")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
            }
            .buttonStyle(GlowButtonStyle())
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [AppTheme.destructive.opacity(0.12), AppTheme.card],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: .rect(cornerRadius: AppTheme.cardCornerRadius)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}

private struct BreakdownWeakZoneMapView: View {
    let zoneSummaries: [ZoneSummary]
    let animateIn: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.035))

            VStack(spacing: 8) {
                Capsule()
                    .fill(fill(for: .upperAbs))
                    .frame(width: 62, height: 18)
                    .shadow(color: glow(for: .upperAbs), radius: 10)
                    .scaleEffect(animateIn ? 1 : 0.86)
                    .animation(.spring(duration: 0.8, bounce: 0.18).delay(0.04), value: animateIn)

                HStack(alignment: .top, spacing: 8) {
                    obliqueCapsule(rotation: -16)

                    VStack(spacing: 8) {
                        Capsule()
                            .fill(fill(for: .deepCore))
                            .frame(width: 18, height: 54)
                            .shadow(color: glow(for: .deepCore), radius: 10)
                            .scaleEffect(animateIn ? 1 : 0.86)
                            .animation(.spring(duration: 0.8, bounce: 0.18).delay(0.08), value: animateIn)

                        Capsule()
                            .fill(fill(for: .lowerAbs))
                            .frame(width: 50, height: 22)
                            .shadow(color: glow(for: .lowerAbs), radius: 10)
                            .scaleEffect(animateIn ? 1 : 0.86)
                            .animation(.spring(duration: 0.8, bounce: 0.18).delay(0.12), value: animateIn)
                    }

                    obliqueCapsule(rotation: 16)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private func obliqueCapsule(rotation: Double) -> some View {
        Capsule()
            .fill(fill(for: .obliques))
            .frame(width: 14, height: 72)
            .rotationEffect(.degrees(rotation))
            .shadow(color: glow(for: .obliques), radius: 10)
            .scaleEffect(animateIn ? 1 : 0.86)
            .animation(.spring(duration: 0.8, bounce: 0.18).delay(0.10), value: animateIn)
    }

    private func fill(for zone: AbRegion) -> Color {
        guard let summary = zoneSummaries.first(where: { $0.zone == zone }) else {
            return Color.white.opacity(0.08)
        }

        if summary.rank == 1 {
            return AppTheme.destructive
        }

        if summary.rank == 2 {
            return AppTheme.destructive.opacity(0.82)
        }

        return Color.white.opacity(0.10)
    }

    private func glow(for zone: AbRegion) -> Color {
        guard let summary = zoneSummaries.first(where: { $0.zone == zone }) else {
            return .clear
        }

        if summary.rank <= 2 {
            return AppTheme.destructive.opacity(0.28)
        }

        return .clear
    }
}

private struct BreakdownWeakZoneRow: View {
    let summary: ZoneSummary
    let animateIn: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(AppTheme.destructive.opacity(0.12))
                        .frame(width: 32, height: 32)

                    Image(systemName: summary.zone.icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.destructive)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(summary.zone.rawValue)
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text("Priority \(summary.rank)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.secondaryText)
                        .tracking(0.8)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(summary.currentScore)")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())

                    Text("-\(summary.deficit)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.destructive)
                }
            }

            GeometryReader { proxy in
                let currentWidth: CGFloat = max(18, proxy.size.width * CGFloat(summary.currentScore) / 100.0)
                let targetOffset: CGFloat = min(max(0, proxy.size.width * CGFloat(summary.targetScore) / 100.0), proxy.size.width - 2)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.06))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.destructive.opacity(0.82), AppTheme.destructive],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: animateIn ? currentWidth : 18)
                        .animation(.spring(duration: 0.8, bounce: 0.14), value: animateIn)

                    RoundedRectangle(cornerRadius: 1)
                        .fill(.white.opacity(0.85))
                        .frame(width: 2, height: 12)
                        .offset(x: targetOffset - 1)
                }
            }
            .frame(height: 12)

            HStack {
                Text("now")
                Spacer()
                Text("target \(summary.targetScore)")
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(AppTheme.secondaryText)
            .tracking(0.5)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04), in: .rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

private struct BreakdownDefinitionSignalsCard: View {
    let signals: [DefinitionSignal]
    let animateIn: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("What Shapes Your Look")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(.white)

                Text("The things people notice first")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            HStack(spacing: 10) {
                ForEach(signals) { signal in
                    BreakdownDefinitionSignalTile(
                        signal: signal,
                        animateIn: animateIn
                    )
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.06), AppTheme.card],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: .rect(cornerRadius: AppTheme.cardCornerRadius)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}

private struct BreakdownDefinitionSignalTile: View {
    let signal: DefinitionSignal
    let animateIn: Bool

    var body: some View {
        VStack(spacing: 12) {
            BreakdownDefinitionVisual(
                style: signal.style,
                tint: signal.tint,
                animateIn: animateIn
            )
            .frame(height: 46)

            VStack(spacing: 3) {
                Text("\(signal.value)")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                Text(signal.status)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(signal.tint)
                    .tracking(0.8)

                Text(signal.title)
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .background(signal.tint.opacity(0.08), in: .rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(signal.tint.opacity(0.20), lineWidth: 1)
        )
    }
}

private struct BreakdownDefinitionVisual: View {
    let style: DefinitionSignalStyle
    let tint: Color
    let animateIn: Bool

    var body: some View {
        switch style {
        case .lowerLine:
            VStack(spacing: 6) {
                Capsule()
                    .fill(tint.opacity(0.28))
                    .frame(width: 34, height: 5)
                Capsule()
                    .fill(tint.opacity(0.52))
                    .frame(width: 42, height: 6)
                Capsule()
                    .fill(tint)
                    .frame(width: animateIn ? 52 : 22, height: 8)
                    .animation(.spring(duration: 0.8, bounce: 0.18).delay(0.04), value: animateIn)
            }
        case .sideCut:
            HStack(alignment: .bottom, spacing: 12) {
                Capsule()
                    .fill(tint)
                    .frame(width: 10, height: animateIn ? 32 : 14)
                    .rotationEffect(.degrees(-18))
                    .animation(.spring(duration: 0.8, bounce: 0.18).delay(0.06), value: animateIn)

                Capsule()
                    .fill(tint.opacity(0.24))
                    .frame(width: 6, height: 18)

                Capsule()
                    .fill(tint)
                    .frame(width: 10, height: animateIn ? 32 : 14)
                    .rotationEffect(.degrees(18))
                    .animation(.spring(duration: 0.8, bounce: 0.18).delay(0.06), value: animateIn)
            }
        case .coreTightness:
            ZStack {
                Circle()
                    .stroke(tint.opacity(0.20), lineWidth: 1)
                    .frame(width: 42, height: 42)

                VStack(spacing: 4) {
                    Capsule()
                        .fill(tint.opacity(0.34))
                        .frame(width: 10, height: 6)

                    Capsule()
                        .fill(tint)
                        .frame(width: 12, height: animateIn ? 20 : 8)
                        .animation(.spring(duration: 0.8, bounce: 0.18).delay(0.08), value: animateIn)

                    Capsule()
                        .fill(tint.opacity(0.58))
                        .frame(width: 10, height: 6)
                }
            }
        }
    }
}

private struct ZoneSummary: Identifiable {
    let zone: AbRegion
    let currentScore: Int
    let targetScore: Int
    let rank: Int

    init(zone: AbRegion, currentScore: Int, targetScore: Int, rank: Int = 0) {
        self.zone = zone
        self.currentScore = currentScore
        self.targetScore = targetScore
        self.rank = rank
    }

    var id: String {
        zone.rawValue
    }

    var deficit: Int {
        max(targetScore - currentScore, 0)
    }
}

private struct DefinitionSignal: Identifiable {
    let title: String
    let value: Int
    let style: DefinitionSignalStyle

    var id: String {
        title
    }

    var tint: Color {
        value < 70 ? AppTheme.destructive : AppTheme.primaryAccent
    }

    var status: String {
        if value >= 82 {
            return "Sharp"
        }

        if value >= 70 {
            return "Building"
        }

        return "Needs Work"
    }
}

private enum BreakdownComparisonMode {
    case current
    case potential
}

private enum DefinitionSignalStyle {
    case lowerLine
    case sideCut
    case coreTightness
}

private extension AbRegion {
    var compactLabel: String {
        switch self {
        case .upperAbs:
            "Upper"
        case .lowerAbs:
            "Lower"
        case .obliques:
            "Obliques"
        case .deepCore:
            "Core"
        }
    }
}
