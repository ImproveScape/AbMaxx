import SwiftUI

struct RestDayFullView: View {
    @Bindable var vm: AppViewModel
    @State private var sorenessLevel: Int = 0
    @State private var sleepHours: Double = 7.0
    @State private var saved: Bool = false
    @State private var restChecks: [Bool] = [false, false, false, false, false]
    @State private var hydrationGlasses: Int = 0
    @State private var animateCards: Bool = false
    @State private var showBreathingTimer: Bool = false
    @State private var breathPhase: BreathPhase = .inhale
    @State private var breathTimer: Int = 0

    private let purpleAccent = Color(red: 0.6, green: 0.4, blue: 1.0)

    private var scan: ScanResult? { vm.latestScan }

    private var weakestZone: String {
        guard let s = scan else { return "Lower Abs" }
        let zones: [(String, Int)] = [
            ("Upper Abs", s.upperAbsScore),
            ("Lower Abs", s.lowerAbsScore),
            ("Obliques", s.obliquesScore),
            ("Deep Core", s.deepCoreScore)
        ]
        return zones.min(by: { $0.1 < $1.1 })?.0 ?? "Lower Abs"
    }

    private var strongestZone: String {
        guard let s = scan else { return "Upper Abs" }
        let zones: [(String, Int)] = [
            ("Upper Abs", s.upperAbsScore),
            ("Lower Abs", s.lowerAbsScore),
            ("Obliques", s.obliquesScore),
            ("Deep Core", s.deepCoreScore)
        ]
        return zones.max(by: { $0.1 < $1.1 })?.0 ?? "Upper Abs"
    }

    private var bodyFat: Double { scan?.estimatedBodyFat ?? 18.0 }
    private var overallScore: Int { scan?.overallScore ?? 0 }

    private var recoveryPercent: Double {
        let checks = restChecks.filter { $0 }.count
        let base = 50.0
        let fromChecks = Double(checks) * 8.0
        let fromSleep = sleepHours >= 8 ? 10.0 : (sleepHours >= 7 ? 5.0 : 0)
        let fromSoreness = max(0, 10.0 - Double(sorenessLevel) * 3.0)
        return min(base + fromChecks + fromSleep + fromSoreness, 100)
    }

    private var tomorrowLabel: String { vm.tomorrowTargetLabel }
    private var isTomorrowRest: Bool { vm.isTomorrowRestDay }

    private var personalizedRestMessage: String {
        guard let s = scan else {
            return "Your muscles are rebuilding right now. Every hour of rest today compounds into visible results this week."
        }
        let bf = String(format: "%.0f", s.estimatedBodyFat)
        if s.overallScore >= 75 {
            return "At \(bf)% body fat with a \(s.overallScore) score, your abs are elite-level. Today's recovery preserves that definition. Don't undo the work — rest hard."
        } else if s.overallScore >= 60 {
            return "Your \(weakestZone) scored lowest last scan. While you rest, your \(strongestZone) maintains its edge. Tomorrow targets exactly what you need."
        } else {
            return "At \(bf)% body fat, your abs are building underneath. Rest days are when the muscle fibers you tore yesterday actually repair and grow thicker. This is where the magic happens."
        }
    }

    private var stretchRoutine: [(name: String, duration: String, icon: String, target: String)] {
        guard scan != nil else {
            return defaultStretches
        }
        let weak = weakestZone
        switch weak {
        case "Lower Abs":
            return [
                ("Reverse Pelvic Tilt Hold", "45 sec", "arrow.down.circle.fill", "Lower abs activation"),
                ("Lying Knee-to-Chest", "30 sec each", "figure.cooldown", "Hip flexor release"),
                ("Cat-Cow Stretch", "60 sec", "cat.fill", "Spinal mobility"),
                ("Dead Bug Hold", "30 sec", "figure.roll", "Deep core recovery"),
                ("Child's Pose", "45 sec", "leaf.fill", "Full body decompression"),
            ]
        case "Obliques":
            return [
                ("Seated Spinal Twist", "30 sec each", "arrow.triangle.2.circlepath", "Oblique mobility"),
                ("Side-Lying Stretch", "30 sec each", "arrow.left.and.right", "Lateral chain release"),
                ("Thread the Needle", "30 sec each", "figure.cooldown", "Thoracic rotation"),
                ("Cat-Cow Stretch", "60 sec", "cat.fill", "Spinal mobility"),
                ("Standing Side Bend", "20 sec each", "figure.stand", "Oblique lengthening"),
            ]
        case "Deep Core":
            return [
                ("Stomach Vacuum Hold", "15 sec × 3", "wind", "Transverse abdominis"),
                ("Diaphragmatic Breathing", "60 sec", "lungs.fill", "Core pressure reset"),
                ("Supine Pelvic Floor Lift", "30 sec", "arrow.up.circle.fill", "Deep stabilizers"),
                ("Cat-Cow Stretch", "60 sec", "cat.fill", "Spinal mobility"),
                ("Child's Pose", "45 sec", "leaf.fill", "Full body decompression"),
            ]
        default:
            return [
                ("Cobra Stretch", "45 sec", "arrow.up.forward", "Upper ab lengthening"),
                ("Foam Roll Upper Back", "60 sec", "circle.grid.3x3.fill", "Thoracic release"),
                ("Cat-Cow Stretch", "60 sec", "cat.fill", "Spinal mobility"),
                ("Lying Spinal Twist", "30 sec each", "arrow.triangle.2.circlepath", "Rotational mobility"),
                ("Child's Pose", "45 sec", "leaf.fill", "Full body decompression"),
            ]
        }
    }

    private var defaultStretches: [(name: String, duration: String, icon: String, target: String)] {
        [
            ("Cat-Cow Stretch", "60 sec", "cat.fill", "Spinal mobility"),
            ("Cobra Stretch", "45 sec", "arrow.up.forward", "Ab lengthening"),
            ("Seated Spinal Twist", "30 sec each", "arrow.triangle.2.circlepath", "Rotation"),
            ("Hip Flexor Stretch", "30 sec each", "figure.cooldown", "Hip mobility"),
            ("Child's Pose", "45 sec", "leaf.fill", "Decompression"),
        ]
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            StandardBackgroundOrbs()

            ScrollView {
                VStack(spacing: 20) {
                    heroSection
                    coachMessageCard
                    recoveryMeterCard
                    stretchRoutineCard
                    sleepAndSorenessCard
                    tomorrowPreviewCard
                    nutritionRecoveryCard
                    breathingCard
                    Color.clear.frame(height: 60)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            restChecks = vm.restDayCheckboxes()
            if restChecks.count < 5 {
                restChecks = restChecks + Array(repeating: false, count: 5 - restChecks.count)
            }
            loadSavedSleep()
            hydrationGlasses = vm.waterGlasses
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                animateCards = true
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(purpleAccent.opacity(0.08))
                    .frame(width: 100, height: 100)
                Circle()
                    .strokeBorder(purpleAccent.opacity(0.3), lineWidth: 2)
                    .frame(width: 100, height: 100)
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(purpleAccent)
                    .symbolEffect(.breathe, options: .repeating)
            }
            .shadow(color: purpleAccent.opacity(0.15), radius: 30)

            VStack(spacing: 6) {
                Text("Recovery Day")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                Text("Day \(vm.programDayNumber) of your transformation")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            if let s = scan {
                HStack(spacing: 0) {
                    VStack(spacing: 3) {
                        Text("\(s.overallScore)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                        Text("SCORE")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1.5)
                            .foregroundStyle(AppTheme.muted)
                    }
                    .frame(maxWidth: .infinity)

                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 1, height: 24)

                    VStack(spacing: 3) {
                        Text(String(format: "%.0f%%", s.estimatedBodyFat))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                        Text("BODY FAT")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1.5)
                            .foregroundStyle(AppTheme.muted)
                    }
                    .frame(maxWidth: .infinity)

                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 1, height: 24)

                    VStack(spacing: 3) {
                        Text("\(vm.profile.streakDays)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                        Text("STREAK")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1.5)
                            .foregroundStyle(AppTheme.muted)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(AppTheme.cardSurface)
                .clipShape(.rect(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(AppTheme.border, lineWidth: 1)
                )
            }
        }
        .padding(.top, 10)
    }

    // MARK: - Coach Message

    private var coachMessageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(purpleAccent)
                Text("YOUR REST DAY BRIEF")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(purpleAccent)
                    .tracking(1.5)
                Spacer()
            }

            Text(personalizedRestMessage)
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
                    colors: [purpleAccent.opacity(0.06), Color.clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 250
                )
            }
        )
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(purpleAccent.opacity(0.2), lineWidth: 1)
        )
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 12)
    }

    // MARK: - Recovery Meter

    private var recoveryMeterCard: some View {
        let percent = recoveryPercent
        let meterColor: Color = percent >= 80 ? AppTheme.success : (percent >= 60 ? AppTheme.warning : AppTheme.destructive)

        return VStack(spacing: 16) {
            HStack {
                Text("RECOVERY METER")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(meterColor)
                    .tracking(1.5)
                Spacer()
                Text(recoveryLabel(percent))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(meterColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(meterColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            ZStack {
                Circle()
                    .stroke(AppTheme.border.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)
                Circle()
                    .trim(from: 0, to: percent / 100.0)
                    .stroke(meterColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.8), value: percent)
                VStack(spacing: 2) {
                    Text("\(Int(percent))")
                        .font(.system(size: 36, weight: .black))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    Text("RECOVERY")
                        .font(.system(size: 8, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(AppTheme.muted)
                }
            }
            .shadow(color: meterColor.opacity(0.15), radius: 20)

            Text("Complete the activities below to max out your recovery score")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(18)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(meterColor.opacity(0.2), lineWidth: 1)
        )
        .animation(.spring(duration: 0.4), value: restChecks)
    }

    private func recoveryLabel(_ percent: Double) -> String {
        if percent >= 90 { return "Fully Recovered" }
        if percent >= 75 { return "Well Rested" }
        if percent >= 60 { return "Recovering" }
        return "Needs Attention"
    }

    // MARK: - Stretch Routine

    private var stretchRoutineCard: some View {
        VStack(spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "figure.cooldown")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.success)
                    Text("TARGETED RECOVERY")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(AppTheme.success)
                        .tracking(1.5)
                }
                Spacer()
                Text("~7 min")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.muted)
            }

            if scan != nil {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppTheme.success)
                        .frame(width: 3)
                    Text("Tailored for your \(weakestZone) — your lowest scoring zone")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.success)
                        .lineSpacing(3)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.success.opacity(0.06))
                .clipShape(.rect(cornerRadius: 10))
            }

            ForEach(Array(stretchRoutine.enumerated()), id: \.offset) { index, stretch in
                Button {
                    guard index < restChecks.count else { return }
                    restChecks[index].toggle()
                    saveRestChecks()
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            let done = index < restChecks.count && restChecks[index]
                            RoundedRectangle(cornerRadius: 10)
                                .fill(done ? AppTheme.success : AppTheme.success.opacity(0.1))
                                .frame(width: 36, height: 36)
                            if done {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                            } else {
                                Text("\(index + 1)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(AppTheme.success)
                            }
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(stretch.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(
                                    (index < restChecks.count && restChecks[index]) ? .white : AppTheme.secondaryText
                                )
                            HStack(spacing: 8) {
                                Text(stretch.duration)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(AppTheme.muted)
                                Text("·")
                                    .foregroundStyle(AppTheme.muted)
                                Text(stretch.target)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(AppTheme.success.opacity(0.8))
                            }
                        }

                        Spacer()

                        if index < restChecks.count && restChecks[index] {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(AppTheme.success)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(12)
                    .background(
                        (index < restChecks.count && restChecks[index])
                            ? AppTheme.success.opacity(0.06)
                            : AppTheme.cardSurfaceElevated
                    )
                    .clipShape(.rect(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                (index < restChecks.count && restChecks[index]) ? AppTheme.success.opacity(0.3) : AppTheme.border,
                                lineWidth: 1
                            )
                    )
                }
                .sensoryFeedback(.impact(weight: .light), trigger: restChecks)
            }

            let done = restChecks.filter { $0 }.count
            if done == stretchRoutine.count {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.success)
                    Text("Recovery routine complete")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.success)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(AppTheme.success.opacity(0.08))
                .clipShape(.rect(cornerRadius: 12))
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(18)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(AppTheme.success.opacity(0.15), lineWidth: 1)
        )
        .animation(.spring(duration: 0.35), value: restChecks)
    }

    // MARK: - Sleep & Soreness

    private var sleepAndSorenessCard: some View {
        VStack(spacing: 18) {
            HStack {
                Text("HOW'S YOUR BODY?")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(Color(red: 0.5, green: 0.4, blue: 1.0))
                    .tracking(1.5)
                Spacer()
                if saved {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                        Text("Saved")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(AppTheme.success)
                    .transition(.scale.combined(with: .opacity))
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Soreness Level")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
                HStack(spacing: 6) {
                    ForEach(0..<5) { level in
                        Button {
                            sorenessLevel = level
                            saveRecovery()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: sorenessIcon(level))
                                    .font(.system(size: 18))
                                    .foregroundStyle(level == sorenessLevel ? sorenessColor(level) : AppTheme.muted)
                                Text(sorenessLabel(level))
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(level == sorenessLevel ? .white : AppTheme.muted)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(level == sorenessLevel ? sorenessColor(level).opacity(0.15) : AppTheme.cardSurfaceElevated)
                            .clipShape(.rect(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(level == sorenessLevel ? sorenessColor(level).opacity(0.4) : AppTheme.border.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }

                if sorenessLevel >= 3, let s = scan {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.warning)
                        Text("High soreness with a \(s.overallScore) score means your muscles are adapting. Extra rest and protein today.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.warning)
                    }
                    .padding(10)
                    .background(AppTheme.warning.opacity(0.08))
                    .clipShape(.rect(cornerRadius: 10))
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Sleep Last Night")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                    Spacer()
                    Text(String(format: "%.1f hours", sleepHours))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
                Slider(value: $sleepHours, in: 3...12, step: 0.5)
                    .tint(Color(red: 0.5, green: 0.4, blue: 1.0))
                    .onChange(of: sleepHours) { _, _ in saveRecovery() }

                if sleepHours < 7 {
                    HStack(spacing: 8) {
                        Image(systemName: "moon.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.destructive)
                        Text("Under 7 hours slows recovery by up to 40%. Aim for an early night tonight.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.destructive.opacity(0.8))
                    }
                    .padding(10)
                    .background(AppTheme.destructive.opacity(0.06))
                    .clipShape(.rect(cornerRadius: 10))
                } else if sleepHours >= 8 {
                    HStack(spacing: 8) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.success)
                        Text("8+ hours — optimal recovery. Your growth hormone peaks during deep sleep.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.success)
                    }
                    .padding(10)
                    .background(AppTheme.success.opacity(0.06))
                    .clipShape(.rect(cornerRadius: 10))
                }
            }
        }
        .padding(18)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color(red: 0.5, green: 0.4, blue: 1.0).opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Tomorrow Preview

    private var tomorrowPreviewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "sunrise.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.orange)
                Text("TOMORROW'S PLAN")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(AppTheme.orange)
                    .tracking(1.5)
                Spacer()
                Text("Day \(vm.programDayNumber + 1)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.muted)
            }

            if isTomorrowRest {
                HStack(spacing: 12) {
                    Image(systemName: "bed.double.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(purpleAccent)
                    Text("Another rest day — double recovery block for maximum gains")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text(tomorrowLabel)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)

                    let exercises = vm.tomorrowExercisesPreview
                    if !exercises.isEmpty {
                        HStack(spacing: 12) {
                            HStack(spacing: 5) {
                                Image(systemName: "dumbbell.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppTheme.muted)
                                Text("\(exercises.count) exercises")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            HStack(spacing: 5) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppTheme.muted)
                                Text("~\(exercises.count * 2 + 1) min")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                        }

                        ForEach(exercises.prefix(3)) { ex in
                            HStack(spacing: 10) {
                                Image(systemName: ex.region.icon)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(AppTheme.primaryAccent)
                                    .frame(width: 24)
                                Text(ex.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(AppTheme.secondaryText)
                                    .lineLimit(1)
                                Spacer()
                                Text(ex.region.rawValue)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(AppTheme.muted)
                            }
                        }
                    }

                    if let s = scan {
                        let gap = s.overallScore < 75
                            ? "Your \(weakestZone) is the priority — tomorrow's session has extra volume there."
                            : "Maintenance session to keep all zones sharp."
                        Text(gap)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.orange)
                            .lineSpacing(3)
                    }
                }
            }
        }
        .padding(18)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(AppTheme.orange.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Nutrition Recovery

    private var nutritionRecoveryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.success)
                Text("RECOVERY NUTRITION")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(AppTheme.success)
                    .tracking(1.5)
                Spacer()
            }

            let proteinGoal = Int(vm.dailyNutrition.proteinGoal)
            let proteinDone = Int(vm.totalProteinToday)
            let waterGoal = vm.dailyNutrition.waterGoal
            let waterDone = vm.waterGlasses

            HStack(spacing: 12) {
                nutritionPill(
                    label: "Protein",
                    value: "\(proteinDone)g",
                    goal: "\(proteinGoal)g",
                    progress: proteinGoal > 0 ? Double(proteinDone) / Double(proteinGoal) : 0,
                    color: AppTheme.primaryAccent
                )
                nutritionPill(
                    label: "Water",
                    value: "\(waterDone)",
                    goal: "\(waterGoal) glasses",
                    progress: waterGoal > 0 ? Double(waterDone) / Double(waterGoal) : 0,
                    color: Color(red: 0.3, green: 0.7, blue: 1.0)
                )
            }

            VStack(spacing: 8) {
                recoveryNutritionTip(icon: "fish.fill", text: "Protein repairs the muscle fibers you tore this week", color: AppTheme.success)
                recoveryNutritionTip(icon: "drop.fill", text: "Dehydrated muscles recover up to 40% slower", color: Color(red: 0.3, green: 0.7, blue: 1.0))
                recoveryNutritionTip(icon: "leaf.fill", text: "Anti-inflammatory foods reduce soreness — berries, salmon, leafy greens", color: AppTheme.success)
            }
        }
        .padding(18)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(AppTheme.success.opacity(0.15), lineWidth: 1)
        )
    }

    private func nutritionPill(label: String, value: String, goal: String, progress: Double, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(AppTheme.border, lineWidth: 4)
                    .frame(width: 50, height: 50)
                Circle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                Text("\(Int(min(progress, 1.0) * 100))%")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(color)
            }
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
            Text("\(value) / \(goal)")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.04))
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(color.opacity(0.12), lineWidth: 1)
        )
    }

    private func recoveryNutritionTip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
                .lineSpacing(2)
        }
    }

    // MARK: - Breathing Exercise

    private var breathingCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "wind")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(purpleAccent)
                Text("BOX BREATHING")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(purpleAccent)
                    .tracking(1.5)
                Spacer()
                Text("Reduces cortisol")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.muted)
            }

            Text("High cortisol blocks ab definition. 2 minutes of box breathing drops cortisol by 25%.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
                .lineSpacing(3)

            if showBreathingTimer {
                breathingTimerView
            } else {
                Button {
                    withAnimation(.spring(duration: 0.4)) {
                        showBreathingTimer = true
                    }
                    startBreathingCycle()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 13, weight: .bold))
                        Text("Start 2-Min Session")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(purpleAccent)
                    .clipShape(.rect(cornerRadius: 14))
                    .shadow(color: purpleAccent.opacity(0.25), radius: 12, y: 4)
                }
            }
        }
        .padding(18)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(purpleAccent.opacity(0.15), lineWidth: 1)
        )
    }

    private var breathingTimerView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(AppTheme.border.opacity(0.3), lineWidth: 4)
                    .frame(width: 100, height: 100)
                Circle()
                    .trim(from: 0, to: Double(breathTimer) / 4.0)
                    .stroke(purpleAccent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: breathTimer)
                VStack(spacing: 4) {
                    Text(breathPhase.label)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Text("\(breathTimer)")
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(purpleAccent)
                        .contentTransition(.numericText())
                }
            }
            .shadow(color: purpleAccent.opacity(0.15), radius: 20)

            Button {
                withAnimation(.spring(duration: 0.3)) {
                    showBreathingTimer = false
                }
            } label: {
                Text("Stop")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(AppTheme.cardSurfaceElevated)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .transition(.scale.combined(with: .opacity))
    }

    private func startBreathingCycle() {
        breathPhase = .inhale
        breathTimer = 4
        runBreathCycle()
    }

    private func runBreathCycle() {
        guard showBreathingTimer else { return }
        Task {
            for _ in 0..<8 {
                guard showBreathingTimer else { return }
                for phase in BreathPhase.allCases {
                    guard showBreathingTimer else { return }
                    breathPhase = phase
                    for count in stride(from: 4, through: 1, by: -1) {
                        guard showBreathingTimer else { return }
                        withAnimation { breathTimer = count }
                        try? await Task.sleep(for: .seconds(1))
                    }
                }
            }
            withAnimation { showBreathingTimer = false }
        }
    }

    // MARK: - Helpers

    private func saveRestChecks() {
        let truncated = Array(restChecks.prefix(4))
        vm.saveRestDayCheckboxes(truncated)
    }

    private func saveRecovery() {
        vm.logRecovery(sorenessLevel: sorenessLevel, sleepHours: sleepHours)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        UserDefaults.standard.set(sleepHours, forKey: "restSleep_\(formatter.string(from: Date()))")
        withAnimation(.spring(duration: 0.3)) { saved = true }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { saved = false }
        }
    }

    private func loadSavedSleep() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = "restSleep_\(formatter.string(from: Date()))"
        let saved = UserDefaults.standard.double(forKey: key)
        if saved > 0 { sleepHours = saved }

        let calendar = Calendar.current
        if let today = vm.recoveryDays.first(where: { calendar.isDateInToday($0.date) }) {
            sorenessLevel = today.sorenessLevel
            if today.sleepHours > 0 { sleepHours = today.sleepHours }
        }
    }

    private func sorenessIcon(_ level: Int) -> String {
        switch level {
        case 0: return "face.smiling"
        case 1: return "face.smiling"
        case 2: return "hand.raised.fill"
        case 3: return "bolt.fill"
        default: return "exclamationmark.triangle.fill"
        }
    }

    private func sorenessLabel(_ level: Int) -> String {
        switch level {
        case 0: return "None"
        case 1: return "Mild"
        case 2: return "Med"
        case 3: return "Sore"
        default: return "V.Sore"
        }
    }

    private func sorenessColor(_ level: Int) -> Color {
        switch level {
        case 0: return AppTheme.success
        case 1: return Color(red: 0.5, green: 0.85, blue: 0.5)
        case 2: return AppTheme.warning
        case 3: return AppTheme.orange
        default: return AppTheme.destructive
        }
    }
}

nonisolated enum BreathPhase: String, CaseIterable, Sendable {
    case inhale
    case hold1
    case exhale
    case hold2

    var label: String {
        switch self {
        case .inhale: return "Breathe In"
        case .hold1: return "Hold"
        case .exhale: return "Breathe Out"
        case .hold2: return "Hold"
        }
    }
}
