import SwiftUI

struct SubscoreDetailSheet: View {
    let name: String
    let score: Int
    let icon: String
    let change: Int?
    let scan: ScanResult?
    @State private var animateBar: Bool = false
    @State private var animateContent: Bool = false

    private var accentColor: Color {
        switch name {
        case "Upper Abs": return AppTheme.primaryAccent
        case "Lower Abs": return Color(red: 0.55, green: 0.30, blue: 1.0)
        case "Obliques": return AppTheme.orange
        case "Deep Core": return AppTheme.success
        case "Symmetry": return Color(red: 0.40, green: 0.75, blue: 1.0)
        case "V Taper": return Color(red: 1.0, green: 0.45, blue: 0.55)
        default: return AppTheme.primaryAccent
        }
    }

    private var rating: String {
        ScanResult.ratingLabel(for: score)
    }

    private var ratingColor: Color {
        if score >= 88 { return AppTheme.success }
        if score >= 78 { return Color(red: 0.40, green: 0.85, blue: 1.0) }
        if score >= 68 { return AppTheme.primaryAccent }
        if score >= 58 { return AppTheme.warning }
        return AppTheme.destructive
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                scoreRingSection
                insightCard
                breakdownFactors
                actionableAdvice
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .background(BackgroundView().ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.15).delay(0.1)) {
                animateBar = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                animateContent = true
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 6) {
            Capsule()
                .fill(AppTheme.border)
                .frame(width: 40, height: 4)
                .padding(.bottom, 8)

            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(accentColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Detailed Breakdown")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.muted)
                }
                Spacer()

                if let change, change != 0 {
                    HStack(spacing: 3) {
                        Image(systemName: change > 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 11, weight: .black))
                        Text(change > 0 ? "+\(change)" : "\(change)")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(change > 0 ? AppTheme.success : AppTheme.destructive)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill((change > 0 ? AppTheme.success : AppTheme.destructive).opacity(0.1))
                    )
                }
            }
        }
    }

    private var scoreRingSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(accentColor.opacity(0.1), lineWidth: 12)
                    .frame(width: 130, height: 130)

                Circle()
                    .trim(from: 0, to: animateBar ? Double(score) / 100.0 : 0)
                    .stroke(
                        AngularGradient(
                            colors: [accentColor, accentColor.opacity(0.5), accentColor],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 130, height: 130)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(.system(size: 40, weight: .black, design: .default))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    Text(rating)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(ratingColor)
                        .textCase(.uppercase)
                        .tracking(1)
                }
            }
            .shadow(color: accentColor.opacity(0.2), radius: 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var insightCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "person.text.rectangle.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(accentColor)
                Text("Your \(name) Analysis")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text(personalizedInsight)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(accentColor.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(accentColor.opacity(0.15), lineWidth: 1)
                )
        )
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 10)
    }

    private var breakdownFactors: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.doc.horizontal.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(accentColor)
                Text("Contributing Factors")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 10) {
                ForEach(Array(factors.enumerated()), id: \.offset) { index, factor in
                    factorRow(
                        label: factor.label,
                        value: factor.value,
                        maxValue: 100,
                        delay: Double(index) * 0.08
                    )
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppTheme.border.opacity(0.5), lineWidth: 1)
        )
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 10)
    }

    private func factorRow(label: String, value: Int, maxValue: Int, delay: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
                Spacer()
                Text("\(value)")
                    .font(.system(size: 13, weight: .black, design: .default))
                    .foregroundStyle(.white)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.border.opacity(0.5))
                        .frame(height: 4)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: animateBar ? geo.size.width * Double(value) / Double(maxValue) : 0, height: 4)
                }
            }
            .frame(height: 4)
        }
    }

    private var actionableAdvice: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.warning)
                Text("How to Improve")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
            }

            ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.system(size: 12, weight: .black, design: .default))
                        .foregroundStyle(accentColor)
                        .frame(width: 22, height: 22)
                        .background(
                            Circle()
                                .fill(accentColor.opacity(0.12))
                        )
                    Text(tip)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppTheme.border.opacity(0.5), lineWidth: 1)
        )
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 10)
    }

    // MARK: - Personalized Content

    private var personalizedInsight: String {
        guard let scan else {
            return "Complete your first scan to get a personalized breakdown of your \(name.lowercased())."
        }

        switch name {
        case "Upper Abs":
            if score >= 85 {
                return "Your upper abs are exceptionally well-defined. The rectus abdominis shows strong separation and the muscle bellies are clearly visible even at rest. This level of upper ab development indicates low subcutaneous fat in the upper region and solid hypertrophy. You're in the top tier."
            } else if score >= 70 {
                return "Your upper abs are showing solid definition — the top two segments of your rectus abdominis are visible, especially when flexed. There's still a thin layer of tissue softening the edges slightly. With continued training and dialing in nutrition, you'll push these into elite territory."
            } else if score >= 58 {
                return "Your upper abs are developing but aren't fully breaking through yet. You can see the outline when flexed hard, but at rest they're still smooth. This is common — upper abs are usually the first to show, so you're on the right track. A caloric deficit and consistent training will reveal them."
            } else {
                return "Your upper abs are in the early stages of development. The muscle is there underneath but body fat and muscle thickness need work before they'll be visible. Focus on progressive overload with crunches and cable work, paired with a nutrition plan to reduce body fat."
            }

        case "Lower Abs":
            if score >= 85 {
                return "Your lower abs are exceptionally developed — this is the hardest area to bring out and you've done it. The lower segments of your rectus abdominis are clearly separated and the V-line leading to the pelvis is sharp. This indicates very low body fat below the navel and excellent core control."
            } else if score >= 70 {
                return "Your lower abs are showing real progress. The area below the navel is starting to tighten and you can see the outline of the lower rectus abdominis. Most people struggle here because the body stores fat in this region last. You're ahead of the curve."
            } else if score >= 58 {
                return "Your lower abs are the stubborn zone — and that's completely normal. The lower belly holds onto fat longer than anywhere else on the torso. You've got the muscle foundation building, but the subcutaneous layer is still masking the detail. Targeted leg raises and a slight caloric deficit will make the biggest difference here."
            } else {
                return "Your lower abs haven't broken through yet, but don't be discouraged — this is the last place to lean out for almost everyone. The lower rectus abdominis requires both low body fat and direct lower ab work like hanging leg raises and reverse crunches. Stay consistent and this will come."
            }

        case "Obliques":
            if score >= 85 {
                return "Your obliques are razor sharp. The external obliques frame your midsection perfectly, creating that detailed, sculpted look on both sides. The serratus anterior integration is visible and the V-cut lines are prominent. This gives your physique a complete, three-dimensional look."
            } else if score >= 70 {
                return "Your obliques are showing solid development with visible lines running diagonally along your sides. The external obliques are starting to create that framed, athletic look. A bit more definition and you'll have that complete midsection that stands out from every angle."
            } else if score >= 58 {
                return "Your obliques are developing but still lack the sharp separation that creates that V-cut frame. The muscles are there — you can feel them when you twist — but the visual definition needs more work. Woodchops, side planks, and Pallof presses will bring them out."
            } else {
                return "Your obliques are still in the building phase. These muscles run along your sides and create the frame for your abs. Without developed obliques, even great abs look incomplete. Focus on rotational exercises and anti-rotation work to build thickness, then lean down to reveal the lines."
            }

        case "Deep Core":
            if score >= 85 {
                return "Your deep core stability is excellent. The transverse abdominis, internal obliques, and pelvic floor are working in strong coordination. This shows in your posture, the tightness of your waist, and how your abs look even when relaxed. Deep core strength is the foundation everything else is built on."
            } else if score >= 70 {
                return "Your deep core is solid — the foundation is strong. Your transverse abdominis is engaged well, which keeps your waist tight and supports your outer ab muscles. Good deep core function means better posture and a flatter, more controlled midsection throughout the day."
            } else if score >= 58 {
                return "Your deep core needs attention. While your outer abs might look decent when flexed, the underlying stability muscles aren't fully activated. This can cause your stomach to push outward slightly at rest. Vacuum exercises, dead bugs, and hollow body holds will tighten everything from the inside out."
            } else {
                return "Your deep core is underdeveloped, which means the transverse abdominis isn't providing the internal compression your midsection needs. This is why your abs might not look as tight even if you have some definition. Start with daily stomach vacuums and anti-extension exercises — this will transform how your entire core looks."
            }

        case "Symmetry":
            let sym = scan.symmetry
            if sym >= 85 {
                return "Your ab symmetry is outstanding. Both sides of your rectus abdominis are evenly developed with matching muscle belly sizes and consistent separation lines. Symmetrical abs create that clean, aesthetic look that separates good physiques from great ones."
            } else if sym >= 70 {
                return "Your symmetry is good but there's a slight imbalance between sides. One side of your abs may be slightly more developed or defined than the other — this is common and often related to dominant-hand movement patterns. Unilateral exercises will help even things out."
            } else if sym >= 58 {
                return "There's a noticeable asymmetry in your ab development. This could be genetic (ab alignment varies person to person) or training-related. While you can't change bone structure, you can balance muscle development by focusing on single-side exercises and being mindful of form."
            } else {
                return "Your ab symmetry needs work. Significant imbalance between left and right sides is visible. This is usually caused by favoring one side during exercises or having a dominant rotation pattern. Focus on strict, even form and incorporate unilateral core work like single-arm farmer carries."
            }

        case "V Taper":
            let def = scan.definition
            if def >= 85 {
                return "Your V-taper is elite level. The definition lines between each ab segment are deep, clear, and visible from multiple angles. This level of definition means your body fat is low enough and your muscle bellies are thick enough to create real depth and shadow between segments."
            } else if def >= 70 {
                return "Your V-taper definition is solid — the lines between your ab segments are visible, especially in good lighting. You're at the point where a small drop in body fat or increase in muscle thickness will push these lines from \"visible\" to \"dramatic.\""
            } else if def >= 58 {
                return "Your V-taper definition is emerging. You can see the outlines and some separation, but the grooves between segments are still shallow. This is a combination of body fat sitting in the grooves and the muscle bellies needing more thickness to push outward and create deeper separation."
            } else {
                return "Your V-taper definition is still developing. The lines between ab segments are faint or only visible in very specific lighting. Getting deeper separation requires both reducing body fat (especially the last stubborn layer on the stomach) and building thicker muscle bellies through progressive overload."
            }

        default:
            return "Your \(name.lowercased()) score reflects your current development in this area. Keep training consistently and scanning every few days to track your progress."
        }
    }

    private struct Factor {
        let label: String
        let value: Int
    }

    private var factors: [Factor] {
        guard let scan else {
            return [Factor(label: "No data", value: 0)]
        }

        switch name {
        case "Upper Abs":
            return [
                Factor(label: "Definition Depth", value: scan.definition),
                Factor(label: "Muscle Thickness", value: scan.thickness),
                Factor(label: "Visual Clarity", value: scan.aesthetic)
            ]
        case "Lower Abs":
            return [
                Factor(label: "Lower Definition", value: scan.frame),
                Factor(label: "Core Thickness", value: scan.thickness),
                Factor(label: "Fat Distribution", value: max(50, 100 - Int(scan.estimatedBodyFat * 3)))
            ]
        case "Obliques":
            return [
                Factor(label: "Oblique Line Depth", value: scan.obliques),
                Factor(label: "Side Definition", value: (scan.obliques + scan.aesthetic) / 2),
                Factor(label: "V-Cut Visibility", value: (scan.obliques + scan.frame) / 2)
            ]
        case "Deep Core":
            return [
                Factor(label: "Core Stability", value: scan.thickness),
                Factor(label: "Internal Compression", value: scan.symmetry),
                Factor(label: "Waist Tightness", value: (scan.thickness + scan.symmetry) / 2)
            ]
        case "Symmetry":
            return [
                Factor(label: "Left-Right Balance", value: scan.symmetry),
                Factor(label: "Upper-Lower Balance", value: (scan.definition + scan.frame) / 2),
                Factor(label: "Proportionality", value: scan.aesthetic)
            ]
        case "V Taper":
            return [
                Factor(label: "Segment Separation", value: scan.definition),
                Factor(label: "Groove Depth", value: (scan.definition + scan.thickness) / 2),
                Factor(label: "Shadow Contrast", value: scan.aesthetic)
            ]
        default:
            return [Factor(label: "Score", value: score)]
        }
    }

    private var tips: [String] {
        switch name {
        case "Upper Abs":
            if score >= 75 {
                return [
                    "Add weighted cable crunches — progressive overload deepens the grooves between segments",
                    "Try decline sit-ups with a slow 3-second negative to maximize upper ab tension",
                    "Maintain your current body fat level — your upper abs respond well to staying lean"
                ]
            } else {
                return [
                    "Start with controlled crunches focusing on peak contraction — squeeze for 2 seconds at the top",
                    "Add plank-to-crunch variations to build the mind-muscle connection",
                    "Reduce body fat through a moderate caloric deficit — upper abs are the first to show when you get lean enough"
                ]
            }

        case "Lower Abs":
            if score >= 75 {
                return [
                    "Hanging leg raises with a posterior pelvic tilt — curl your pelvis up, don't just lift your legs",
                    "Try dragon flags or ab wheel rollouts to hit the lower portion under maximum stretch",
                    "Tighten up nutrition — lower abs need the lowest body fat to fully show"
                ]
            } else {
                return [
                    "Reverse crunches on a flat bench — focus on lifting your hips off the bench, not swinging legs",
                    "Dead bugs with slow, controlled extensions to build lower ab activation",
                    "Prioritize a caloric deficit — the lower belly is the last place to lean out and the first place to store fat"
                ]
            }

        case "Obliques":
            if score >= 75 {
                return [
                    "Cable woodchops with a pause at peak contraction for deeper oblique activation",
                    "Hanging windshield wipers to hit obliques under load with full range of motion",
                    "Side planks with hip dips — add a weight for progressive overload"
                ]
            } else {
                return [
                    "Pallof press holds — anti-rotation builds oblique thickness without bulking the waist",
                    "Bicycle crunches with slow, controlled rotations — don't rush the movement",
                    "Side plank variations 3x per week to build the foundational oblique strength"
                ]
            }

        case "Deep Core":
            if score >= 75 {
                return [
                    "Stomach vacuums — hold for 15-20 seconds, 5 sets daily to maximize transverse abdominis control",
                    "L-sits or hollow body holds for 30+ seconds to build elite-level deep core endurance",
                    "Add anti-extension work like ab wheel rollouts to challenge deep stabilizers"
                ]
            } else {
                return [
                    "Daily stomach vacuums — start with 10-second holds and build to 20 seconds over 4 weeks",
                    "Dead bugs with band resistance — focus on keeping your lower back pressed into the floor",
                    "Bird dogs with 3-second holds — build the stabilization pattern your deep core needs"
                ]
            }

        case "Symmetry":
            if score >= 75 {
                return [
                    "Single-arm farmer carries to balance side-to-side core engagement",
                    "Unilateral cable rotations — do the weaker side first, then match reps on the stronger side",
                    "Pay attention to form on bilateral exercises — film yourself to spot compensations"
                ]
            } else {
                return [
                    "Single-arm suitcase carries — 3 sets per side, start with your weaker side",
                    "Unilateral dead bugs — do extra reps on the weaker side to close the gap",
                    "Focus on strict, symmetrical form — avoid twisting or leaning during standard ab exercises"
                ]
            }

        case "V Taper":
            if score >= 75 {
                return [
                    "Weighted cable crunches with a 2-second squeeze to deepen the separation grooves",
                    "Train abs in multiple rep ranges — heavy sets of 8-10 and burnout sets of 20+",
                    "Drop body fat by 1-2% to sharpen the existing lines into dramatic definition"
                ]
            } else {
                return [
                    "Progressive overload on your ab exercises — add weight or reps every week",
                    "Train abs 4-5x per week with variety — crunches, leg raises, and planks hit different fibers",
                    "Focus on nutrition — a consistent caloric deficit will reveal the definition you're building underneath"
                ]
            }

        default:
            return ["Stay consistent with your training", "Track your nutrition daily", "Scan weekly to monitor progress"]
        }
    }
}
