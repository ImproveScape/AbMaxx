import SwiftUI

struct SubscoreBreakdownFullView: View {
    let zone: String
    let score: Int
    let icon: String
    let scan: ScanResult?
    let vm: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var animateRing: Bool = false
    @State private var revealSections: Int = 0

    private var accentColor: Color {
        switch zone {
        case "Upper Abs": return AppTheme.primaryAccent
        case "Lower Abs": return Color(red: 0.55, green: 0.30, blue: 1.0)
        case "Obliques": return AppTheme.orange
        case "Deep Core": return AppTheme.success
        case "Symmetry": return Color(red: 0.40, green: 0.75, blue: 1.0)
        case "V Taper": return Color(red: 1.0, green: 0.45, blue: 0.55)
        default: return AppTheme.primaryAccent
        }
    }

    private var rating: String { ScanResult.ratingLabel(for: score) }

    private var ratingColor: Color {
        if score >= 88 { return AppTheme.success }
        if score >= 78 { return Color(red: 0.40, green: 0.85, blue: 1.0) }
        if score >= 68 { return AppTheme.primaryAccent }
        if score >= 58 { return AppTheme.warning }
        return AppTheme.destructive
    }

    private var bodyFat: Double { scan?.estimatedBodyFat ?? 18.0 }
    private var overallScore: Int { scan?.overallScore ?? 0 }
    private var absStructure: String { scan?.absStructure.rawValue ?? "Developing" }

    private var previousScan: ScanResult? {
        let sorted = vm.scanResults.sorted { $0.date < $1.date }
        guard sorted.count >= 2 else { return nil }
        return sorted[sorted.count - 2]
    }

    private var change: Int? {
        guard let prev = previousScan, let current = scan else { return nil }
        switch zone {
        case "Upper Abs": return current.upperAbsScore - prev.upperAbsScore
        case "Lower Abs": return current.lowerAbsScore - prev.lowerAbsScore
        case "Obliques": return current.obliquesScore - prev.obliquesScore
        case "Deep Core": return current.deepCoreScore - prev.deepCoreScore
        case "Symmetry": return current.symmetry - prev.symmetry
        case "V Taper": return current.frame - prev.frame
        default: return nil
        }
    }

    private var isWeakest: Bool {
        guard let s = scan else { return false }
        let zones: [(String, Int)] = [
            ("Upper Abs", s.upperAbsScore),
            ("Lower Abs", s.lowerAbsScore),
            ("Obliques", s.obliquesScore),
            ("Deep Core", s.deepCoreScore)
        ]
        let weakest = zones.min(by: { $0.1 < $1.1 })?.0
        return weakest == zone
    }

    private var isStrongest: Bool {
        guard let s = scan else { return false }
        let zones: [(String, Int)] = [
            ("Upper Abs", s.upperAbsScore),
            ("Lower Abs", s.lowerAbsScore),
            ("Obliques", s.obliquesScore),
            ("Deep Core", s.deepCoreScore)
        ]
        let strongest = zones.max(by: { $0.1 < $1.1 })?.0
        return strongest == zone
    }

    private var weekInfo: AppViewModel.ZoneWeekInfo? {
        guard let region = regionForZone else { return nil }
        return vm.zoneWeekInfo(for: region)
    }

    private var regionForZone: AbRegion? {
        switch zone {
        case "Upper Abs": return .upperAbs
        case "Lower Abs": return .lowerAbs
        case "Obliques": return .obliques
        case "Deep Core": return .deepCore
        default: return nil
        }
    }

    private var topExercises: [Exercise] {
        guard let region = regionForZone else { return [] }
        return Array(Exercise.exercises(for: region).prefix(3))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        heroSection
                        statusBadge
                        whatThisMeansCard
                        yourScanDataCard
                        muscleAnatomyCard
                        howWeTargetCard
                        exercisePrescription
                        progressionPathCard
                        improvementPlan
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 50)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(AppTheme.muted)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                withAnimation(.spring(duration: 0.8, bounce: 0.15).delay(0.1)) {
                    animateRing = true
                }
                for i in 1...6 {
                    withAnimation(.easeOut(duration: 0.5).delay(0.15 * Double(i))) {
                        revealSections = i
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(AppTheme.background)
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(AppTheme.border)
                .frame(width: 40, height: 4)
                .padding(.bottom, 4)

            ZStack {
                Circle()
                    .stroke(accentColor.opacity(0.1), lineWidth: 10)
                    .frame(width: 140, height: 140)
                Circle()
                    .trim(from: 0, to: animateRing ? Double(score) / 100.0 : 0)
                    .stroke(
                        AngularGradient(
                            colors: [accentColor, accentColor.opacity(0.5), accentColor],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(.system(size: 44, weight: .black))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    Text(rating.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(ratingColor)
                        .tracking(1)
                }
            }
            .shadow(color: accentColor.opacity(0.2), radius: 24)

            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(accentColor)
                    Text(zone)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                }

                if let c = change, c != 0 {
                    HStack(spacing: 4) {
                        Image(systemName: c > 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 11, weight: .black))
                        Text(c > 0 ? "+\(c) since last scan" : "\(c) since last scan")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(c > 0 ? AppTheme.success : AppTheme.destructive)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill((c > 0 ? AppTheme.success : AppTheme.destructive).opacity(0.1))
                    )
                }
            }
        }
    }

    // MARK: - Status Badge

    private var statusBadge: some View {
        HStack(spacing: 12) {
            if isWeakest {
                statusPill(text: "YOUR WEAKEST ZONE", color: AppTheme.destructive, icon: "exclamationmark.triangle.fill")
            } else if isStrongest {
                statusPill(text: "YOUR STRONGEST ZONE", color: AppTheme.success, icon: "crown.fill")
            }

            if let wi = weekInfo {
                statusPill(text: "\(wi.sessionsPerWeek)× THIS WEEK", color: accentColor, icon: "calendar")
            }
        }
        .opacity(revealSections >= 1 ? 1 : 0)
        .offset(y: revealSections >= 1 ? 0 : 8)
    }

    private func statusPill(text: String, color: Color, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text(text)
                .font(.system(size: 10, weight: .heavy))
                .tracking(0.5)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(color.opacity(0.25), lineWidth: 1))
    }

    // MARK: - What This Means For You

    private var whatThisMeansCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(icon: "person.text.rectangle.fill", title: "What This Means For You", color: accentColor)

            Text(personalizedMeaning)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(
            ZStack {
                AppTheme.cardSurface
                RadialGradient(
                    colors: [accentColor.opacity(0.06), Color.clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 250
                )
            }
        )
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(accentColor.opacity(0.2), lineWidth: 1)
        )
        .opacity(revealSections >= 2 ? 1 : 0)
        .offset(y: revealSections >= 2 ? 0 : 10)
    }

    private var personalizedMeaning: String {
        guard let s = scan else {
            return "Complete your first scan to get a detailed breakdown of your \(zone.lowercased())."
        }

        let bf = String(format: "%.0f", s.estimatedBodyFat)
        let structure = s.absStructure.rawValue

        switch zone {
        case "Upper Abs":
            if score >= 80 {
                return "Your upper rectus abdominis is showing real separation — at \(bf)% body fat with a \(structure) structure, the top segments are clearly defined. This is your strongest visual asset right now. The muscle bellies are thick enough to create shadow between segments even in flat lighting."
            } else if score >= 65 {
                return "Your upper abs at \(score) are developing — you can see definition when flexed, but at \(bf)% body fat there's still a layer softening the edges. With your \(structure) structure, the upper two segments want to pop. A few more points of body fat loss and these go from 'visible' to 'sharp.'"
            } else {
                return "At \(score), your upper abs are still building underneath \(bf)% body fat. With your \(structure) structure, the rectus abdominis needs both more hypertrophy and less subcutaneous fat before the top segments break through. This is the first zone that'll show when you lean down — it's coming."
            }

        case "Lower Abs":
            if score >= 80 {
                return "Your lower abs at \(score) are exceptional — this is the hardest area on the body to develop and you're there. At \(bf)% body fat, the V-line and lower segments are visible. Most people never get here because the body stores fat below the navel last. You've broken through that barrier."
            } else if score >= 65 {
                return "Lower abs at \(score) — the area below your navel is tightening but at \(bf)% body fat, the lower rectus abdominis is still partially covered. Your body genetically prioritizes fat storage here. Every 1% of body fat you lose from here makes a massive visual difference in this zone specifically."
            } else {
                return "At \(score), your lower abs are the bottleneck. With \(bf)% body fat and a \(structure) structure, this zone won't fully show until you're below 14%. But here's the thing — the muscle underneath is building with every session. When the fat comes off, what's revealed will be worth the wait."
            }

        case "Obliques":
            if score >= 80 {
                return "Your obliques at \(score) are creating that framed, sculpted look. The external obliques running diagonally along your sides are clearly separated, giving your midsection a 3D quality. At \(bf)% body fat, the V-cut lines are prominent and the serratus integration is showing."
            } else if score >= 65 {
                return "Obliques at \(score) — the diagonal lines are starting to show on your sides. At \(bf)% body fat with your \(structure), the external obliques need more definition to create that full frame around your abs. Without developed obliques, even great front-facing abs look incomplete from the side."
            } else {
                return "Your obliques at \(score) are the frame around your abs — and right now that frame is underdeveloped. At \(bf)% body fat, rotational exercises and anti-rotation work will build the thickness. When these catch up, your entire midsection transforms because abs without obliques look flat and unfinished."
            }

        case "Deep Core":
            if score >= 80 {
                return "Deep core at \(score) — your transverse abdominis and internal stabilizers are firing strong. This shows in how tight your waist looks even relaxed. At \(bf)% body fat, this internal compression is pulling everything in and making your outer abs pop harder. This is the invisible muscle that makes everything else look better."
            } else if score >= 65 {
                return "Your deep core at \(score) is solid but there's room. The transverse abdominis wraps around your midsection like a corset — when it's underdeveloped, your stomach pushes outward even if your outer abs have definition. At \(bf)%, strengthening this zone will visually shrink your waist by 1-2 inches."
            } else {
                return "Deep core at \(score) is holding your entire midsection back. Even with outer ab development, a weak transverse abdominis means your stomach protrudes at rest. At \(bf)% body fat, this is actually the fastest zone to improve — daily stomach vacuums for 4 weeks can transform how your whole core looks."
            }

        case "Symmetry":
            let sym = s.symmetry
            if sym >= 80 {
                return "Your symmetry at \(score) is outstanding — both sides of your rectus abdominis are evenly matched in size and definition. With your \(structure) structure, the even development creates that clean, aesthetic look. Symmetry is partly genetic (tendon placement) but your muscle development is balanced."
            } else if sym >= 65 {
                return "Symmetry at \(score) — there's a visible imbalance between your left and right sides. This is common and usually caused by dominant-hand movement patterns. With your \(structure) and \(bf)% body fat, unilateral exercises will close this gap. The difference between symmetrical and asymmetrical abs is what separates good from elite."
            } else {
                return "Your symmetry at \(score) shows a significant left-right imbalance. Part of this is genetic ab alignment (everyone's tendons are slightly different) but the muscle development gap can be trained out. At \(bf)%, focusing on single-side exercises and strict form will bring the weaker side up."
            }

        case "V Taper":
            if score >= 80 {
                return "V-Taper at \(score) — your waist-to-shoulder ratio and torso definition are creating a dramatic visual taper. The lines between your ab segments are deep and visible from multiple angles. At \(bf)% body fat, you have enough leanness and muscle thickness for real shadow contrast between segments."
            } else if score >= 65 {
                return "V-Taper at \(score) is developing — the overall shape is there but the definition lines between segments are still shallow. At \(bf)% body fat with your \(structure), you're at the inflection point where a small body fat drop creates a massive visual jump in the depth of separation between each ab segment."
            } else {
                return "V-Taper at \(score) means the grooves between your ab segments are faint. At \(bf)% body fat, there's still a subcutaneous layer filling in those grooves. Progressive overload to build thicker muscle bellies PLUS continued fat loss will create the depth and shadow that makes abs look truly defined."
            }

        default:
            return "Your \(zone.lowercased()) score of \(score) reflects your current development. Keep training consistently."
        }
    }

    // MARK: - Your Scan Data

    private var yourScanDataCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(icon: "chart.bar.doc.horizontal.fill", title: "Your Numbers", color: accentColor)

            VStack(spacing: 10) {
                ForEach(Array(scanDataPoints.enumerated()), id: \.offset) { index, point in
                    HStack {
                        Text(point.label)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                        Spacer()
                        Text(point.value)
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(.white)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .background(index % 2 == 0 ? Color.white.opacity(0.02) : Color.clear)
                    .clipShape(.rect(cornerRadius: 8))
                }
            }
        }
        .padding(18)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(AppTheme.border.opacity(0.5), lineWidth: 1)
        )
        .opacity(revealSections >= 2 ? 1 : 0)
        .offset(y: revealSections >= 2 ? 0 : 10)
    }

    private var scanDataPoints: [(label: String, value: String)] {
        guard let s = scan else { return [] }
        var points: [(String, String)] = [
            ("Zone Score", "\(score) / 100"),
            ("Rating", rating),
            ("Overall Score", "\(s.overallScore)"),
            ("Body Fat", String(format: "%.1f%%", s.estimatedBodyFat)),
            ("Abs Structure", s.absStructure.rawValue),
        ]

        if isWeakest {
            points.append(("Status", "Weakest Zone"))
        } else if isStrongest {
            points.append(("Status", "Strongest Zone"))
        }

        if let c = change {
            points.append(("Last Scan Change", c >= 0 ? "+\(c)" : "\(c)"))
        }

        return points
    }

    // MARK: - Muscle Anatomy

    private var muscleAnatomyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(icon: "figure.strengthtraining.traditional", title: "The Muscle", color: accentColor)

            Text(anatomyDescription)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(anatomyFacts, id: \.title) { fact in
                    VStack(alignment: .leading, spacing: 6) {
                        Image(systemName: fact.icon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(accentColor)
                        Text(fact.title)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                        Text(fact.detail)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppTheme.muted)
                            .lineLimit(3)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(accentColor.opacity(0.04))
                    .clipShape(.rect(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(accentColor.opacity(0.1), lineWidth: 1)
                    )
                }
            }
        }
        .padding(18)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(AppTheme.border.opacity(0.5), lineWidth: 1)
        )
        .opacity(revealSections >= 3 ? 1 : 0)
        .offset(y: revealSections >= 3 ? 0 : 10)
    }

    private var anatomyDescription: String {
        switch zone {
        case "Upper Abs":
            return "The upper portion of your rectus abdominis — the 'six-pack muscle.' These are the first segments to show through because the body stores less fat above the navel. They're activated most during spinal flexion (crunching motions)."
        case "Lower Abs":
            return "The lower segments of the rectus abdominis, below your navel toward the pelvis. Notoriously the last to become visible because the body prioritizes fat storage here. Requires posterior pelvic tilt movements to fully engage."
        case "Obliques":
            return "The external and internal obliques run diagonally along your sides. They create the 'frame' around your abs and the V-cut line. Responsible for rotation, side bending, and anti-rotation stability."
        case "Deep Core":
            return "The transverse abdominis — the deepest ab muscle. It wraps horizontally around your midsection like a natural weight belt. When strong, it compresses your waist and makes all other ab muscles look more defined."
        case "Symmetry":
            return "The balance between your left and right ab development. Affected by genetics (tendon placement) and training patterns. Symmetrical development creates the clean, aesthetic look that separates good from great physiques."
        case "V Taper":
            return "The visual ratio between your shoulders/lats and your waist, combined with the depth of separation between ab segments. A strong V-taper makes your abs look more dramatic by framing them within a wider torso."
        default:
            return ""
        }
    }

    private var anatomyFacts: [(title: String, detail: String, icon: String)] {
        switch zone {
        case "Upper Abs":
            return [
                ("Muscle", "Rectus abdominis (upper)", "figure.core.training"),
                ("Function", "Spinal flexion, trunk curling", "arrow.up.and.down"),
                ("Visibility", "First to show at ~16% BF", "eye.fill"),
                ("Key Move", "Cable crunches, decline sit-ups", "dumbbell.fill"),
            ]
        case "Lower Abs":
            return [
                ("Muscle", "Rectus abdominis (lower)", "figure.core.training"),
                ("Function", "Pelvic tilt, hip flexion", "arrow.up.and.down"),
                ("Visibility", "Last to show, needs <14% BF", "eye.fill"),
                ("Key Move", "Hanging leg raises, reverse crunches", "dumbbell.fill"),
            ]
        case "Obliques":
            return [
                ("Muscle", "External & internal obliques", "figure.core.training"),
                ("Function", "Rotation, lateral flexion", "arrow.triangle.2.circlepath"),
                ("Visibility", "V-cut visible at ~15% BF", "eye.fill"),
                ("Key Move", "Woodchops, Pallof press", "dumbbell.fill"),
            ]
        case "Deep Core":
            return [
                ("Muscle", "Transverse abdominis", "figure.core.training"),
                ("Function", "Internal compression, stability", "circle.grid.cross.fill"),
                ("Visual Effect", "Tighter waist, flatter stomach", "eye.fill"),
                ("Key Move", "Stomach vacuums, dead bugs", "dumbbell.fill"),
            ]
        case "Symmetry":
            return [
                ("Factor", "Genetic tendon placement", "dna"),
                ("Trainable", "Muscle size balance (yes)", "checkmark.circle.fill"),
                ("Method", "Unilateral core exercises", "arrow.left.arrow.right"),
                ("Timeline", "4-8 weeks to see balance shifts", "clock.fill"),
            ]
        case "V Taper":
            return [
                ("Ratio", "Shoulder-to-waist proportion", "chart.bar.fill"),
                ("Depth", "Groove depth between segments", "square.stack.3d.down.right"),
                ("Key Factor", "Low body fat + thick bellies", "flame.fill"),
                ("Visual", "Shadow contrast creates definition", "sun.max.fill"),
            ]
        default:
            return []
        }
    }

    // MARK: - How We Target This

    private var howWeTargetCard: some View {
        Group {
            if let wi = weekInfo {
                VStack(alignment: .leading, spacing: 14) {
                    sectionHeader(icon: "target", title: "How Your Plan Targets This", color: accentColor)

                    HStack(spacing: 16) {
                        targetStat(value: "\(wi.sessionsPerWeek)", label: "SESSIONS/WK", color: accentColor)
                        targetStat(value: isWeakest ? "HIGH" : "STD", label: "PRIORITY", color: isWeakest ? AppTheme.destructive : AppTheme.success)
                        targetStat(value: "\(topExercises.count)+", label: "EXERCISES", color: AppTheme.primaryAccent)
                    }

                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(accentColor)
                            .frame(width: 3)
                        Text(wi.statusMessage)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(accentColor)
                            .lineSpacing(3)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(accentColor.opacity(0.06))
                    .clipShape(.rect(cornerRadius: 10))

                    if !wi.dayLabels.isEmpty {
                        HStack(spacing: 6) {
                            Text("Training days:")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(AppTheme.muted)
                            ForEach(wi.dayLabels, id: \.self) { day in
                                Text(day)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(accentColor)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(accentColor.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(18)
                .background(AppTheme.cardSurface)
                .clipShape(.rect(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(accentColor.opacity(0.15), lineWidth: 1)
                )
                .opacity(revealSections >= 4 ? 1 : 0)
                .offset(y: revealSections >= 4 ? 0 : 10)
            }
        }
    }

    private func targetStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(AppTheme.muted)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.04))
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(color.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Exercise Prescription

    private var exercisePrescription: some View {
        Group {
            if !topExercises.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    sectionHeader(icon: "dumbbell.fill", title: "Your \(zone) Exercises", color: accentColor)

                    ForEach(topExercises) { exercise in
                        HStack(spacing: 14) {
                            ExerciseImageView(exercise: exercise, size: 52)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Text(vm.progressiveRepsString(for: exercise))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(AppTheme.secondaryText)
                            }

                            Spacer()

                            HStack(spacing: 3) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 9))
                                Text("+\(exercise.xp)")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundStyle(accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(accentColor.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        .padding(12)
                        .background(AppTheme.cardSurfaceElevated)
                        .clipShape(.rect(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(AppTheme.border, lineWidth: 1)
                        )
                    }
                }
                .padding(18)
                .background(AppTheme.cardSurface)
                .clipShape(.rect(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(AppTheme.border.opacity(0.5), lineWidth: 1)
                )
                .opacity(revealSections >= 4 ? 1 : 0)
                .offset(y: revealSections >= 4 ? 0 : 10)
            }
        }
    }

    // MARK: - Progression Path

    private var progressionPathCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(icon: "chart.line.uptrend.xyaxis", title: "Your Path Forward", color: accentColor)

            VStack(spacing: 0) {
                ForEach(Array(milestones.enumerated()), id: \.offset) { index, milestone in
                    HStack(spacing: 14) {
                        VStack(spacing: 0) {
                            Circle()
                                .fill(score >= milestone.threshold ? accentColor : AppTheme.border)
                                .frame(width: 12, height: 12)
                            if index < milestones.count - 1 {
                                Rectangle()
                                    .fill(score >= milestones[index + 1].threshold ? accentColor.opacity(0.5) : AppTheme.border.opacity(0.3))
                                    .frame(width: 2)
                                    .frame(maxHeight: .infinity)
                            }
                        }
                        .frame(width: 12)

                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(milestone.label)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(score >= milestone.threshold ? .white : AppTheme.muted)
                                Spacer()
                                Text("\(milestone.threshold)+")
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundStyle(score >= milestone.threshold ? accentColor : AppTheme.muted)
                            }
                            Text(milestone.description)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(AppTheme.secondaryText)
                                .lineLimit(2)

                            if score >= milestone.threshold && (index == milestones.count - 1 || score < milestones[index + 1].threshold) {
                                Text("YOU ARE HERE")
                                    .font(.system(size: 9, weight: .heavy))
                                    .foregroundStyle(accentColor)
                                    .tracking(1)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(accentColor.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, 10)
                    }
                }
            }
        }
        .padding(18)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(AppTheme.border.opacity(0.5), lineWidth: 1)
        )
        .opacity(revealSections >= 5 ? 1 : 0)
        .offset(y: revealSections >= 5 ? 0 : 10)
    }

    private var milestones: [(label: String, threshold: Int, description: String)] {
        [
            ("Beginner", 0, "Building the foundation — muscle activation developing"),
            ("Developing", 45, "Muscle is responding to training, definition starting to appear"),
            ("Defined", 65, "Clear visible development, showing through at lower body fat"),
            ("Strong", 78, "Advanced development, visible from most angles"),
            ("Elite", 88, "Top-tier development, competition-level definition"),
        ]
    }

    // MARK: - Improvement Plan

    private var improvementPlan: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                Text("YOUR \(zone.uppercased()) ACTION PLAN")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white)
                    .tracking(1.5)
                Spacer()
            }

            ForEach(Array(actionItems.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(.white.opacity(0.15)))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                        Text(item.detail)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(18)
        .background(
            ZStack {
                accentColor
                LinearGradient(
                    colors: [.white.opacity(0.08), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(.rect(cornerRadius: 20))
        .opacity(revealSections >= 6 ? 1 : 0)
        .offset(y: revealSections >= 6 ? 0 : 10)
    }

    private var actionItems: [(title: String, detail: String)] {
        switch zone {
        case "Upper Abs":
            if score >= 75 {
                return [
                    ("Add weighted cable crunches", "Progressive overload deepens the grooves between your upper segments"),
                    ("Slow eccentric focus", "3-second negatives on every rep to maximize tension"),
                    ("Maintain body fat", "At \(String(format: "%.0f", bodyFat))%, your upper abs respond to staying lean"),
                ]
            } else {
                return [
                    ("Peak contraction crunches", "Squeeze for 2 seconds at the top of every rep — build that mind-muscle connection"),
                    ("Plank-to-crunch variations", "Builds activation patterns your upper abs need"),
                    ("Caloric deficit", "At \(String(format: "%.0f", bodyFat))% body fat, a moderate deficit will reveal what you're building"),
                ]
            }
        case "Lower Abs":
            if score >= 75 {
                return [
                    ("Hanging leg raises with pelvic tilt", "Curl your pelvis up at the top — don't just swing legs"),
                    ("Dragon flags or ab wheel", "Maximum stretch on the lower fibers under load"),
                    ("Tighten nutrition", "Your lower abs need the lowest body fat to fully show — every calorie counts here"),
                ]
            } else {
                return [
                    ("Reverse crunches (strict form)", "Lift your hips off the bench — that's where lower ab activation lives"),
                    ("Dead bugs daily", "Slow, controlled extensions build lower ab firing patterns"),
                    ("Caloric deficit priority", "At \(String(format: "%.0f", bodyFat))%, the lower belly is the last to lean out — be patient and consistent"),
                ]
            }
        case "Obliques":
            if score >= 75 {
                return [
                    ("Cable woodchops with pause", "Hold peak contraction for 1 second — deeper oblique activation"),
                    ("Hanging windshield wipers", "Full range rotation under load — advanced oblique builder"),
                    ("Weighted side planks", "Add progressive overload to your oblique stability work"),
                ]
            } else {
                return [
                    ("Pallof press holds", "Anti-rotation builds oblique thickness without bulking your waist"),
                    ("Bicycle crunches (slow)", "Controlled rotations — don't rush the movement"),
                    ("Side plank variations 3×/week", "Build the foundational oblique strength everything else sits on"),
                ]
            }
        case "Deep Core":
            if score >= 75 {
                return [
                    ("Stomach vacuums: 20 sec × 5 sets daily", "Maximum transverse abdominis control — this is the elite move"),
                    ("L-sits or hollow body holds", "30+ seconds to build deep core endurance"),
                    ("Ab wheel rollouts", "Anti-extension challenges your deep stabilizers at maximum stretch"),
                ]
            } else {
                return [
                    ("Daily stomach vacuums", "Start 10 sec, build to 20 sec over 4 weeks — this alone transforms your waist"),
                    ("Dead bugs with band resistance", "Keep lower back pressed to floor — this is where deep core lives"),
                    ("Bird dogs with 3-sec holds", "Build the stabilization pattern your deep core needs"),
                ]
            }
        case "Symmetry":
            return [
                ("Single-arm farmer carries", "Balance side-to-side core engagement — weaker side first"),
                ("Unilateral cable rotations", "Extra reps on the weaker side to close the gap"),
                ("Film your form", "Watch for compensations — your body cheats without you knowing"),
            ]
        case "V Taper":
            return [
                ("Weighted cable crunches (heavy)", "2-second squeeze to deepen separation grooves between segments"),
                ("Multi-rep-range training", "Heavy 8-10 rep sets AND burnout 20+ rep sets hit different fibers"),
                ("Body fat focus", "At \(String(format: "%.0f", bodyFat))%, dropping 1-2% sharpens existing lines dramatically"),
            ]
        default:
            return [
                ("Train consistently", "Hit this zone according to your plan"),
                ("Track nutrition", "Your results depend on what you eat"),
                ("Scan weekly", "Monitor progress to see what's working"),
            ]
        }
    }

    // MARK: - Helpers

    private func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
            Spacer()
        }
    }
}
