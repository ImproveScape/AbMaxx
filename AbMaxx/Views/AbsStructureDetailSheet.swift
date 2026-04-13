import SwiftUI

struct AbsStructureDetailSheet: View {
    let scan: ScanResult?
    @Environment(\.dismiss) private var dismiss
    @State private var appearAnimated: Bool = false

    private var structure: AbsStructure {
        scan?.absStructure ?? .flat
    }

    private var structureColor: Color {
        switch structure {
        case .flat: return AppTheme.muted
        case .twoPack: return AppTheme.orange
        case .fourPack: return AppTheme.primaryAccent
        case .sixPack: return AppTheme.secondaryAccent
        case .eightPack: return AppTheme.success
        case .asymmetric: return AppTheme.orange
        }
    }

    private var structureRarity: String {
        switch structure {
        case .flat: return "Starting Point"
        case .twoPack: return "Emerging"
        case .fourPack: return "Above Average"
        case .sixPack: return "Top 15%"
        case .eightPack: return "Top 3%"
        case .asymmetric: return "Unique"
        }
    }

    private var segmentCount: Int {
        switch structure {
        case .flat: return 0
        case .twoPack: return 2
        case .fourPack: return 4
        case .sixPack: return 6
        case .eightPack: return 8
        case .asymmetric: return 6
        }
    }

    private var whatItMeans: String {
        switch structure {
        case .flat:
            return "Your abs are in the early development phase. The rectus abdominis muscle is present but not yet showing visible segmentation. This is completely normal and most people start here."
        case .twoPack:
            return "Your upper abdominal region is beginning to show definition. The top pair of muscle bellies are starting to separate, which means your training and diet are working. Keep pushing."
        case .fourPack:
            return "You have visible separation in your upper abdominal region. The top two pairs of muscle bellies are defined, while the lower pair remains less visible. This is the most common visible ab structure."
        case .sixPack:
            return "Your rectus abdominis shows full segmentation across three rows. All six muscle bellies are visible with clear tendinous intersections. This requires both developed muscle and low body fat."
        case .eightPack:
            return "You have a rare fourth row of visible ab segments. This is largely genetic — only a small percentage of people have the tendinous inscriptions positioned to create an 8-pack. Elite-tier genetics and development."
        case .asymmetric:
            return "Your abs have an offset or staggered alignment. This is entirely genetic — the tendinous inscriptions on your rectus abdominis are not perfectly horizontal. Many elite bodybuilders have asymmetric abs."
        }
    }

    private var geneticsInsight: String {
        switch structure {
        case .flat:
            return "Everyone has a rectus abdominis muscle, but its shape and segmentation pattern is determined by your DNA. As you reduce body fat and build core strength, your unique pattern will start to show."
        case .twoPack:
            return "Your top segments are emerging first — this is the natural progression. Genetics determine the order segments appear. Your unique ab pattern is starting to reveal itself."
        case .fourPack:
            return "Your tendinous inscriptions create clear upper separation. Some people are genetically predisposed to show 4 segments more prominently. Continued development and fat loss can reveal lower segments if your genetics allow."
        case .sixPack:
            return "Your genetics gave you the classic 6-pack layout with three horizontal tendinous intersections. The symmetry and spacing of your segments is unique to you — no two six-packs look exactly the same."
        case .eightPack:
            return "Having a visible 8-pack means you have a rare additional tendinous inscription below the navel. This is entirely genetic — you can't train yourself into having more segments. You won the genetic lottery."
        case .asymmetric:
            return "Asymmetric abs are more common than most people think. Your tendinous inscriptions are offset rather than perfectly aligned. This is 100% genetic and cannot be changed through training. Many top physique competitors have this layout."
        }
    }

    private var nextLevelTip: String {
        switch structure {
        case .flat:
            return "Focus on compound movements like hanging leg raises, cable crunches, and planks. Combined with a slight caloric deficit, you'll start seeing your first visible segments within 8-12 weeks."
        case .twoPack:
            return "You're on the right track. Add progressive overload to your ab training — weighted crunches, cable low-to-high chops, and L-sits. Dropping body fat below 18% will accelerate visible progress."
        case .fourPack:
            return "Your lower abs need targeted work. Reverse crunches, dragon flags, and ab wheel rollouts will build thickness in the lower region. Getting body fat below 15% will make a big difference."
        case .sixPack:
            return "You're in great shape. To sharpen definition further, focus on mind-muscle connection during ab exercises, add weighted resistance, and consider vacuums for transverse abdominis depth."
        case .eightPack:
            return "Maintenance is your game. Keep body fat low, continue progressive overload on weighted ab work, and focus on the details — oblique definition, serratus visibility, and overall conditioning."
        case .asymmetric:
            return "Focus on overall thickness and definition rather than symmetry. Unilateral exercises like single-arm farmer carries and offset cable crunches can help balance strength. At low body fat, asymmetric abs have a distinctive, athletic look."
        }
    }

    private var allStructures: [AbsStructure] {
        [.flat, .twoPack, .fourPack, .sixPack, .eightPack]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        heroSection
                            .padding(.top, 8)

                        VStack(spacing: 20) {
                            structureProgressionSection

                            insightSection(
                                title: "What This Means",
                                icon: "brain.head.profile.fill",
                                text: whatItMeans
                            )

                            insightSection(
                                title: "Your Genetics",
                                icon: "dna",
                                text: geneticsInsight
                            )

                            insightSection(
                                title: "How to Level Up",
                                icon: "arrow.up.forward.circle.fill",
                                text: nextLevelTip
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 28)

                        Color.clear.frame(height: 40)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(AppTheme.muted)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                withAnimation(.spring(duration: 0.8, bounce: 0.2).delay(0.15)) {
                    appearAnimated = true
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(AppTheme.background)
    }

    private var heroSection: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [structureColor.opacity(0.3), structureColor.opacity(0.05), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 90
                        )
                    )
                    .frame(width: 180, height: 180)
                    .scaleEffect(appearAnimated ? 1 : 0.6)
                    .opacity(appearAnimated ? 1 : 0)

                Circle()
                    .fill(AppTheme.cardSurface)
                    .frame(width: 110, height: 110)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [structureColor.opacity(0.6), structureColor.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2.5
                            )
                    )

                if segmentCount > 0 {
                    absGridVisual
                        .frame(width: 50, height: 68)
                        .scaleEffect(appearAnimated ? 1 : 0.4)
                        .opacity(appearAnimated ? 1 : 0)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(structureColor.opacity(0.3))
                        .frame(width: 36, height: 52)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(structureColor.opacity(0.3), lineWidth: 1)
                        )
                        .scaleEffect(appearAnimated ? 1 : 0.4)
                        .opacity(appearAnimated ? 1 : 0)
                }
            }

            VStack(spacing: 10) {
                Text(structure.rawValue)
                    .font(.system(size: 36, weight: .black))
                    .foregroundStyle(.white)

                Text(structureRarity)
                    .font(.system(size: 13, weight: .heavy))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(structureColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(structureColor.opacity(0.12))
                    .clipShape(.capsule)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var absGridVisual: some View {
        VStack(spacing: 3) {
            ForEach(0..<(segmentCount / 2), id: \.self) { row in
                HStack(spacing: 3) {
                    ForEach(0..<2, id: \.self) { col in
                        let rowProgress = Double(row) / Double(max(segmentCount / 2, 1))
                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        structureColor.opacity(0.7 - rowProgress * 0.15),
                                        structureColor.opacity(0.5 - rowProgress * 0.1)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .strokeBorder(structureColor.opacity(0.35), lineWidth: 0.5)
                            )
                    }
                }
            }
        }
    }

    private func insightSection(title: String, icon: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.primaryAccent)
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppTheme.border.opacity(0.5), lineWidth: 1)
        )
    }

    private var structureProgressionSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.primaryAccent)
                Text("Your Journey")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
            }

            VStack(spacing: 0) {
                ForEach(Array(allStructures.enumerated()), id: \.offset) { index, s in
                    let isCurrent = s == structure
                    let isPast = structureTierIndex(s) < structureTierIndex(structure)
                    let _ = structureTierIndex(s) > structureTierIndex(structure)

                    HStack(spacing: 16) {
                        ZStack {
                            if isCurrent {
                                Circle()
                                    .fill(AppTheme.primaryAccent.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                    .scaleEffect(appearAnimated ? 1 : 0.5)

                                Circle()
                                    .fill(AppTheme.primaryAccent)
                                    .frame(width: 32, height: 32)

                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundStyle(.white)
                            } else if isPast {
                                Circle()
                                    .fill(AppTheme.primaryAccent.opacity(0.2))
                                    .frame(width: 32, height: 32)

                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(AppTheme.primaryAccent)
                            } else {
                                Circle()
                                    .fill(AppTheme.cardSurfaceElevated)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(AppTheme.border, lineWidth: 1.5)
                                    )

                                Image(systemName: "lock.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(AppTheme.muted)
                            }
                        }
                        .frame(width: 44, height: 44)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(s.rawValue)
                                .font(.system(size: 16, weight: isCurrent ? .black : .semibold))
                                .foregroundStyle(isCurrent ? .white : isPast ? AppTheme.secondaryText : AppTheme.muted)

                            Text(progressionSubtitle(for: s))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(isCurrent ? AppTheme.primaryAccent : AppTheme.muted.opacity(0.7))
                        }

                        Spacer()

                        if isCurrent {
                            Text("YOU")
                                .font(.system(size: 11, weight: .black))
                                .tracking(0.5)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(AppTheme.primaryAccent)
                                .clipShape(.capsule)
                        } else {
                            Text(structureRange(for: s))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(AppTheme.muted.opacity(0.6))
                        }
                    }
                    .padding(.vertical, isCurrent ? 12 : 8)
                    .padding(.horizontal, isCurrent ? 14 : 0)
                    .background(
                        Group {
                            if isCurrent {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(AppTheme.primaryAccent.opacity(0.06))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .strokeBorder(AppTheme.primaryAccent.opacity(0.2), lineWidth: 1)
                                    )
                            }
                        }
                    )

                    if index < allStructures.count - 1 {
                        HStack {
                            let connectorActive = isPast || isCurrent
                            Rectangle()
                                .fill(connectorActive ? AppTheme.primaryAccent.opacity(0.35) : AppTheme.border.opacity(0.2))
                                .frame(width: 2, height: 20)
                                .padding(.leading, 21)
                            Spacer()
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppTheme.cardSurface)
                .shadow(color: AppTheme.primaryAccent.opacity(0.06), radius: 24, y: 8)
        )
        .clipShape(.rect(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    LinearGradient(
                        colors: [AppTheme.primaryAccent.opacity(0.25), AppTheme.border.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private func structureTierIndex(_ s: AbsStructure) -> Int {
        switch s {
        case .flat: return 0
        case .twoPack: return 1
        case .fourPack: return 2
        case .sixPack: return 3
        case .eightPack: return 4
        case .asymmetric: return 3
        }
    }

    private func structureRange(for s: AbsStructure) -> String {
        switch s {
        case .flat: return "< 52 avg"
        case .twoPack: return "52-57 avg"
        case .fourPack: return "58-71 avg"
        case .sixPack: return "72-84 avg"
        case .eightPack: return "85+ avg"
        case .asymmetric: return "Any range"
        }
    }

    private func progressionSubtitle(for s: AbsStructure) -> String {
        switch s {
        case .flat: return "Beginning your journey"
        case .twoPack: return "First segments visible"
        case .fourPack: return "Upper abs defined"
        case .sixPack: return "Full segmentation"
        case .eightPack: return "Genetic elite"
        case .asymmetric: return "Offset alignment"
        }
    }
}
