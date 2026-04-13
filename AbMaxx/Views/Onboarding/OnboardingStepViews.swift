import SwiftUI

// MARK: - Dark Motivational Screens

struct ScienceBackedView: View {
    @State private var phase: Int = 0
    @State private var orbPulse: Bool = false

    private let pillars: [(icon: String, title: String, subtitle: String, color: Color, bgColor: Color)] = [
        ("flame.fill", "PROGRAM", "Targeted core training", Color(red: 0.40, green: 0.60, blue: 1.0), Color(red: 0.10, green: 0.15, blue: 0.35)),
        ("bolt.fill", "FUEL", "Nutrition that reveals abs", Color(red: 0.30, green: 0.95, blue: 0.60), Color(red: 0.08, green: 0.22, blue: 0.14)),
        ("brain.head.profile.fill", "MINDSET", "Consistency over perfection", Color(red: 0.78, green: 0.50, blue: 1.0), Color(red: 0.18, green: 0.10, blue: 0.30)),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 52) {
                VStack(spacing: 12) {
                    Text("Anyone can")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))

                    Text("get abs.")
                        .font(.system(size: 56, weight: .black))
                        .foregroundStyle(.clear)
                        .overlay(
                            MeshGradient(
                                width: 3, height: 2,
                                points: [
                                    [0, 0], [0.5, 0], [1, 0],
                                    [0, 1], [0.5, 1], [1, 1]
                                ],
                                colors: [
                                    .blue, .cyan, .mint,
                                    .purple, .blue, .cyan
                                ]
                            )
                            .mask(
                                Text("get abs.")
                                    .font(.system(size: 56, weight: .black))
                            )
                        )
                        .shadow(color: Color.cyan.opacity(0.3), radius: 30)
                }
                .multilineTextAlignment(.center)
                .opacity(phase >= 1 ? 1 : 0)
                .animation(.easeOut(duration: 0.7), value: phase)

                HStack(spacing: 12) {
                    ForEach(Array(pillars.enumerated()), id: \.offset) { index, pillar in
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(pillar.color.opacity(0.15))
                                    .frame(width: 56, height: 56)
                                    .blur(radius: 8)

                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [pillar.bgColor, pillar.bgColor.opacity(0.3)],
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: 28
                                        )
                                    )
                                    .frame(width: 52, height: 52)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(pillar.color.opacity(0.25), lineWidth: 1)
                                    )

                                Image(systemName: pillar.icon)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(pillar.color)
                            }

                            VStack(spacing: 6) {
                                Text(pillar.title)
                                    .font(.system(size: 11, weight: .heavy))
                                    .foregroundStyle(pillar.color)
                                    .tracking(2)

                                Text(pillar.subtitle)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.3))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .padding(.horizontal, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(pillar.bgColor.opacity(0.4))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [pillar.color.opacity(0.2), pillar.color.opacity(0.05)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .opacity(phase >= 2 ? 1 : 0)
                        .scaleEffect(phase >= 2 ? 1 : 0.8)
                        .animation(.spring(duration: 0.55, bounce: 0.2).delay(Double(index) * 0.08), value: phase)
                    }
                }

                VStack(spacing: 12) {
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { i in
                            Capsule()
                                .fill(pillars[i].color.opacity(0.5))
                                .frame(width: phase >= 3 ? 20 : 0, height: 3)
                                .animation(.spring(duration: 0.5).delay(Double(i) * 0.08), value: phase)
                        }
                    }

                    Text("Science, not genetics.")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.35))
                }
                .opacity(phase >= 3 ? 1 : 0)
                .animation(.easeIn(duration: 0.5), value: phase)
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(orbPulse ? 0.06 : 0.03))
                    .frame(width: 300, height: 300)
                    .blur(radius: 100)
                    .offset(y: -80)
                Circle()
                    .fill(Color.purple.opacity(orbPulse ? 0.05 : 0.02))
                    .frame(width: 250, height: 250)
                    .blur(radius: 80)
                    .offset(x: 100, y: 200)
            }
            .ignoresSafeArea()
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                orbPulse = true
            }
            Task {
                try? await Task.sleep(for: .milliseconds(200))
                withAnimation { phase = 1 }
                try? await Task.sleep(for: .milliseconds(600))
                withAnimation { phase = 2 }
                try? await Task.sleep(for: .milliseconds(800))
                withAnimation { phase = 3 }
            }
        }
    }
}

struct SummerCountdownView: View {
    let daysUntilSummer: Int
    @State private var phase: Int = 0
    @State private var now: Date = Date()
    @State private var timerActive: Bool = false

    private var summerDate: Date {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        var components = DateComponents()
        components.month = 6
        components.day = 21
        components.year = year
        if let summer = calendar.date(from: components), summer > Date() {
            return summer
        }
        components.year = year + 1
        return calendar.date(from: components) ?? Date()
    }

    private var timeRemaining: (days: Int, hours: Int, minutes: Int) {
        let interval = max(summerDate.timeIntervalSince(now), 0)
        let totalMinutes = Int(interval) / 60
        let days = totalMinutes / 1440
        let hours = (totalMinutes % 1440) / 60
        let minutes = totalMinutes % 60
        return (days, hours, minutes)
    }

    private var urgencyColor: Color {
        if daysUntilSummer < 60 { return Color(red: 0.95, green: 0.2, blue: 0.2) }
        if daysUntilSummer < 120 { return AppTheme.orange }
        return Color(red: 1.0, green: 0.7, blue: 0.2)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                Text("SUMMER COUNTDOWN")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.5))
                    .tracking(6)
                    .shadow(color: .white.opacity(0.15), radius: 10)
                    .opacity(phase >= 1 ? 1 : 0)
                    .animation(.easeIn(duration: 0.4), value: phase)

                HStack(spacing: 12) {
                    liveCountdownUnit(value: timeRemaining.days, label: "DAYS")
                    colonSeparator
                    liveCountdownUnit(value: timeRemaining.hours, label: "HOURS")
                    colonSeparator
                    liveCountdownUnit(value: timeRemaining.minutes, label: "MIN")
                }
                .opacity(phase >= 1 ? 1 : 0)
                .animation(.easeIn(duration: 0.5), value: phase)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 6)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [urgencyColor, urgencyColor.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: phase >= 2 ? geo.size.width * max(1.0 - Double(daysUntilSummer) / 365.0, 0.08) : 0, height: 6)
                            .shadow(color: urgencyColor.opacity(0.5), radius: 8)
                    }
                }
                .frame(height: 6)
                .animation(.spring(duration: 1.0), value: phase)

                if phase >= 3 {
                    VStack(spacing: 16) {
                        Text("The clock is ticking.")
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundStyle(.white)

                        Text("Every day you wait is a day wasted.\nEvery hour that passes is gone forever.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.35))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: phase)
        .onAppear {
            startLiveTimer()
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                withAnimation { phase = 1 }
                try? await Task.sleep(for: .seconds(1.4))
                withAnimation { phase = 2 }
                try? await Task.sleep(for: .milliseconds(700))
                withAnimation(.easeIn(duration: 0.6)) { phase = 3 }
            }
        }
    }

    private func liveCountdownUnit(value: Int, label: String) -> some View {
        VStack(spacing: 8) {
            Text(String(format: "%02d", value))
                .font(.system(size: 58, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
                .shadow(color: .white.opacity(0.4), radius: 12)
                .shadow(color: .white.opacity(0.15), radius: 30)
                .contentTransition(.numericText())
                .animation(.snappy, value: value)
            Text(label)
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(3)
        }
        .frame(maxWidth: .infinity)
    }

    private var colonSeparator: some View {
        Text(":")
            .font(.system(size: 48, weight: .black, design: .monospaced))
            .foregroundStyle(.white.opacity(0.3))
            .shadow(color: .white.opacity(0.2), radius: 8)
            .offset(y: -12)
    }

    private func startLiveTimer() {
        guard !timerActive else { return }
        timerActive = true
        Task {
            while timerActive {
                try? await Task.sleep(for: .seconds(1))
                now = Date()
            }
        }
    }
}

struct ShirtOffView: View {
    @State private var phase: Int = 0

    private let killedHabits = [
        "Hiding at the pool",
        "Shirt on at the beach",
        "Making excuses",
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 40) {
                Text("THIS SUMMER")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(AppTheme.muted)
                    .tracking(6)
                    .opacity(phase >= 1 ? 1 : 0)
                    .animation(.easeIn(duration: 0.5), value: phase)

                VStack(spacing: 4) {
                    Text("You won't be")
                        .font(.system(size: 30, weight: .black))
                        .foregroundStyle(.white)

                    Text("anxious")
                        .font(.system(size: 46, weight: .black))
                        .foregroundStyle(AppTheme.primaryAccent)
                        .shadow(color: AppTheme.primaryAccent.opacity(0.5), radius: 24)

                    Text("taking your shirt off.")
                        .font(.system(size: 30, weight: .black))
                        .foregroundStyle(.white)
                }
                .multilineTextAlignment(.center)
                .opacity(phase >= 2 ? 1 : 0)
                .animation(.easeIn(duration: 0.6), value: phase)

                if phase >= 3 {
                    VStack(spacing: 12) {
                        ForEach(killedHabits, id: \.self) { item in
                            Text(item)
                                .font(.callout.weight(.medium))
                                .foregroundStyle(AppTheme.destructive.opacity(0.4))
                                .strikethrough(true, color: AppTheme.destructive.opacity(0.6))
                        }
                    }
                    .transition(.opacity)
                }

                if phase >= 4 {
                    Text("Never again.")
                        .font(.title3.weight(.black))
                        .foregroundStyle(.white)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 28)

            Spacer()
        }
        .onAppear {
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                withAnimation { phase = 1 }
                try? await Task.sleep(for: .milliseconds(500))
                withAnimation { phase = 2 }
                try? await Task.sleep(for: .seconds(1.0))
                withAnimation(.easeIn(duration: 0.5)) { phase = 3 }
                try? await Task.sleep(for: .milliseconds(900))
                withAnimation(.easeIn(duration: 0.4)) { phase = 4 }
            }
        }
    }
}

struct FeelConfidentView: View {
    @State private var phase: Int = 0
    @State private var glowPulse: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                Text("It's time to feel")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .opacity(phase >= 1 ? 1 : 0)
                    .animation(.easeIn(duration: 0.6), value: phase)

                Text("CONFIDENT")
                    .font(.system(size: 50, weight: .black))
                    .foregroundStyle(.white)
                    .shadow(color: AppTheme.primaryAccent.opacity(glowPulse ? 0.7 : 0.15), radius: glowPulse ? 35 : 12)
                    .opacity(phase >= 2 ? 1 : 0)
                    .scaleEffect(phase >= 2 ? 1 : 0.85)
                    .animation(.spring(duration: 0.6, bounce: 0.15), value: phase)

                Text("in your own body.")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .opacity(phase >= 2 ? 1 : 0)
                    .animation(.easeIn(duration: 0.5).delay(0.15), value: phase)

                Capsule()
                    .fill(AppTheme.primaryAccent)
                    .frame(width: phase >= 3 ? 40 : 0, height: 3)
                    .animation(.spring(duration: 0.6), value: phase)
                    .padding(.top, 8)

                Text("You deserve to look in the mirror\nand actually love what you see.")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(AppTheme.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(phase >= 3 ? 1 : 0)
                    .animation(.easeIn(duration: 0.6), value: phase)
            }
            .padding(.horizontal, 36)

            Spacer()
        }
        .onAppear {
            Task {
                try? await Task.sleep(for: .milliseconds(400))
                withAnimation { phase = 1 }
                try? await Task.sleep(for: .milliseconds(600))
                withAnimation { phase = 2 }
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    glowPulse = true
                }
                try? await Task.sleep(for: .milliseconds(900))
                withAnimation { phase = 3 }
            }
        }
    }
}

// MARK: - Dark Theme Survey Screens

struct SurveyGenderView: View {
    @Binding var gender: Gender

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("What's your gender?")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 20)
                .padding(.horizontal, 24)

            Text("This helps us calculate your metabolism.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
                .padding(.top, 8)
                .padding(.horizontal, 24)

            VStack(spacing: 10) {
                ForEach(Gender.allCases, id: \.self) { g in
                    Button {
                        gender = g
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: g == .male ? "figure.stand" : "figure.stand.dress")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(gender == g ? .white : AppTheme.secondaryText)
                                .frame(width: 44, height: 44)
                                .background(gender == g ? AppTheme.primaryAccent : AppTheme.cardSurface)
                                .clipShape(.rect(cornerRadius: 12))

                            Text(g.rawValue)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(gender == g ? .white : AppTheme.secondaryText)

                            Spacer()

                            if gender == g {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.primaryAccent)
                            }
                        }
                        .padding(16)
                        .background(AppTheme.cardSurface)
                        .clipShape(.rect(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(gender == g ? AppTheme.primaryAccent.opacity(0.6) : AppTheme.border.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .sensoryFeedback(.selection, trigger: gender)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)

            Spacer()
        }
    }
}

struct SurveyAbsFrequencyView: View {
    @Binding var frequency: AbsTrainingFrequency

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("How many times do you\ntrain abs weekly?")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 20)
                .padding(.horizontal, 24)

            Text("This helps us tailor your program intensity.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
                .padding(.top, 8)
                .padding(.horizontal, 24)

            VStack(spacing: 10) {
                ForEach(AbsTrainingFrequency.allCases, id: \.self) { f in
                    Button {
                        frequency = f
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: f.icon)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(frequency == f ? .white : AppTheme.secondaryText)
                                .frame(width: 44, height: 44)
                                .background(frequency == f ? AppTheme.primaryAccent : AppTheme.cardSurface)
                                .clipShape(.rect(cornerRadius: 12))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(f.rawValue)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(frequency == f ? .white : AppTheme.secondaryText)

                                Text(f.detail)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.muted)
                            }

                            Spacer()

                            if frequency == f {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.primaryAccent)
                            }
                        }
                        .padding(16)
                        .background(AppTheme.cardSurface)
                        .clipShape(.rect(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(frequency == f ? AppTheme.primaryAccent.opacity(0.6) : AppTheme.border.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .sensoryFeedback(.selection, trigger: frequency)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)

            Spacer()
        }
    }
}

struct SurveyAgeView: View {
    @Binding var dateOfBirth: Date

    private var age: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 25
    }

    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let min = calendar.date(byAdding: .year, value: -80, to: Date()) ?? Date()
        let max = calendar.date(byAdding: .year, value: -13, to: Date()) ?? Date()
        return min...max
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("How old are you?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("Your age affects your calorie needs.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 20)
            .padding(.horizontal, 24)

            VStack(spacing: 8) {
                Text("\(age)")
                    .font(.system(size: 72, weight: .black, design: .default))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: age)

                Text("years old")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.muted)
            }
            .padding(.top, 24)

            DatePicker(
                "Date of Birth",
                selection: $dateOfBirth,
                in: dateRange,
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxHeight: 160)
            .padding(.horizontal, 24)
            .padding(.top, 8)

            Spacer()
        }
    }
}

struct SurveyHeightWeightView: View {
    @Binding var heightFeet: Int
    @Binding var heightInches: Int
    @Binding var weightLbs: Double
    @Binding var useMetric: Bool

    @State private var weightText: String = ""
    @State private var heightCmText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your measurements")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("Used to calculate your daily calories.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 20)
            .padding(.horizontal, 24)

            Picker("", selection: $useMetric) {
                Text("Imperial").tag(false)
                Text("Metric").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 24)
            .padding(.top, 20)

            if useMetric {
                metricInputs
            } else {
                imperialInputs
            }

            Spacer()
        }
        .onAppear {
            weightText = "\(Int(weightLbs))"
            heightCmText = "\(heightFeet)"
        }
        .onChange(of: useMetric) { _, newValue in
            if newValue {
                let cm = Double(heightFeet) * 30.48 + Double(heightInches) * 2.54
                heightFeet = Int(cm)
                heightInches = 0
                let kg = weightLbs * 0.453592
                weightLbs = kg.rounded()
                weightText = "\(Int(weightLbs))"
                heightCmText = "\(heightFeet)"
            } else {
                let totalInches = Double(heightFeet) / 2.54
                heightFeet = Int(totalInches / 12)
                heightInches = Int(totalInches.truncatingRemainder(dividingBy: 12))
                weightLbs = (weightLbs / 0.453592).rounded()
                weightText = "\(Int(weightLbs))"
            }
        }
    }

    private var imperialInputs: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("HEIGHT")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.muted)
                    .tracking(2)

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Picker("Feet", selection: $heightFeet) {
                            ForEach(4...7, id: \.self) { ft in
                                Text("\(ft)").tag(ft)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 60, height: 120)
                        Text("ft")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.muted)
                    }

                    HStack(spacing: 4) {
                        Picker("Inches", selection: $heightInches) {
                            ForEach(0...11, id: \.self) { inch in
                                Text("\(inch)").tag(inch)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 60, height: 120)
                        Text("in")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.muted)
                    }
                }
            }
            .padding(20)
            .background(AppTheme.cardSurface)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppTheme.border.opacity(0.4), lineWidth: 1)
            )

            VStack(spacing: 8) {
                Text("WEIGHT")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.muted)
                    .tracking(2)

                HStack(spacing: 8) {
                    TextField("170", text: $weightText)
                        .font(.system(size: 36, weight: .bold, design: .default))
                        .foregroundStyle(.white)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 120)
                        .onChange(of: weightText) { _, newValue in
                            if let val = Double(newValue) {
                                weightLbs = val
                            }
                        }
                    Text("lbs")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.muted)
                }
            }
            .padding(20)
            .background(AppTheme.cardSurface)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppTheme.border.opacity(0.4), lineWidth: 1)
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private var metricInputs: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("HEIGHT")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.muted)
                    .tracking(2)

                HStack(spacing: 8) {
                    TextField("175", text: $heightCmText)
                        .font(.system(size: 36, weight: .bold, design: .default))
                        .foregroundStyle(.white)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 120)
                        .onChange(of: heightCmText) { _, newValue in
                            if let val = Int(newValue) {
                                heightFeet = val
                            }
                        }
                    Text("cm")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.muted)
                }
            }
            .padding(20)
            .background(AppTheme.cardSurface)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppTheme.border.opacity(0.4), lineWidth: 1)
            )

            VStack(spacing: 8) {
                Text("WEIGHT")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.muted)
                    .tracking(2)

                HStack(spacing: 8) {
                    TextField("77", text: $weightText)
                        .font(.system(size: 36, weight: .bold, design: .default))
                        .foregroundStyle(.white)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 120)
                        .onChange(of: weightText) { _, newValue in
                            if let val = Double(newValue) {
                                weightLbs = val
                            }
                        }
                    Text("kg")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.muted)
                }
            }
            .padding(20)
            .background(AppTheme.cardSurface)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppTheme.border.opacity(0.4), lineWidth: 1)
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
}

struct SurveyGoalView: View {
    @Binding var goal: AbsGoal

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("What's your goal?")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 20)
                .padding(.horizontal, 24)

            Text("This determines your calorie target.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
                .padding(.top, 8)
                .padding(.horizontal, 24)

            VStack(spacing: 10) {
                ForEach(AbsGoal.allCases, id: \.self) { g in
                    Button {
                        goal = g
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: g.icon)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(goal == g ? .white : AppTheme.secondaryText)
                                .frame(width: 44, height: 44)
                                .background(goal == g ? AppTheme.primaryAccent : AppTheme.cardSurface)
                                .clipShape(.rect(cornerRadius: 12))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(g.rawValue)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(goal == g ? .white : AppTheme.secondaryText)
                                Text(g.calorieHint)
                                    .font(.caption)
                                    .foregroundStyle(goal == g ? AppTheme.secondaryText : AppTheme.muted)
                            }

                            Spacer()

                            if goal == g {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.primaryAccent)
                            }
                        }
                        .padding(16)
                        .background(AppTheme.cardSurface)
                        .clipShape(.rect(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(goal == g ? AppTheme.primaryAccent.opacity(0.6) : AppTheme.border.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .sensoryFeedback(.selection, trigger: goal)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)

            Spacer()
        }
    }
}

struct SurveyBodyTypeView: View {
    @Binding var category: BodyFatCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("What does your body\nlook like right now?")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 20)
                .padding(.horizontal, 24)

            Text("Be honest — no judgment here.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
                .padding(.top, 8)
                .padding(.horizontal, 24)

            VStack(spacing: 10) {
                ForEach(BodyFatCategory.allCases, id: \.self) { cat in
                    Button {
                        category = cat
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: cat.icon)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(category == cat ? .white : AppTheme.secondaryText)
                                .frame(width: 44, height: 44)
                                .background(category == cat ? AppTheme.primaryAccent : AppTheme.cardSurface)
                                .clipShape(.rect(cornerRadius: 12))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(cat.rawValue)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(category == cat ? .white : AppTheme.secondaryText)
                                Text(cat.rangeText + " body fat")
                                    .font(.caption)
                                    .foregroundStyle(category == cat ? AppTheme.secondaryText : AppTheme.muted)
                            }

                            Spacer()

                            if category == cat {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.primaryAccent)
                            }
                        }
                        .padding(16)
                        .background(AppTheme.cardSurface)
                        .clipShape(.rect(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(category == cat ? AppTheme.primaryAccent.opacity(0.6) : AppTheme.border.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .sensoryFeedback(.selection, trigger: category)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)

            Spacer()
        }
    }
}

struct SurveyActivityView: View {
    @Binding var level: ActivityLevel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("How active are you?")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 20)
                .padding(.horizontal, 24)

            Text("No judgment. Just data.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
                .padding(.top, 8)
                .padding(.horizontal, 24)

            VStack(spacing: 10) {
                ForEach(ActivityLevel.allCases, id: \.self) { activity in
                    Button {
                        level = activity
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: activityIcon(activity))
                                .font(.body.weight(.semibold))
                                .foregroundStyle(level == activity ? .white : AppTheme.secondaryText)
                                .frame(width: 44, height: 44)
                                .background(level == activity ? AppTheme.primaryAccent : AppTheme.cardSurface)
                                .clipShape(.rect(cornerRadius: 12))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(activity.rawValue)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(level == activity ? .white : AppTheme.secondaryText)
                                Text(activity.description)
                                    .font(.caption)
                                    .foregroundStyle(level == activity ? AppTheme.secondaryText : AppTheme.muted)
                            }

                            Spacer()

                            if level == activity {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.primaryAccent)
                            }
                        }
                        .padding(16)
                        .background(AppTheme.cardSurface)
                        .clipShape(.rect(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(level == activity ? AppTheme.primaryAccent.opacity(0.6) : AppTheme.border.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .sensoryFeedback(.selection, trigger: level)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)

            Spacer()
        }
    }

    private func activityIcon(_ activity: ActivityLevel) -> String {
        switch activity {
        case .sedentary: return "figure.stand"
        case .lightlyActive: return "figure.walk"
        case .moderate, .moderatelyActive: return "figure.run"
        case .veryActive: return "flame.fill"
        case .extraActive: return "flame.circle.fill"
        }
    }
}

// MARK: - Pain Point Questions (Dark Theme)

struct PainPointQuestionView: View {
    let question: String
    let subtitle: String
    let options: [(icon: String, text: String)]
    @Binding var selected: String

    @State private var appeared: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(question)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .lineSpacing(2)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
            }
            .padding(.top, 20)
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .animation(.easeIn(duration: 0.4), value: appeared)

            VStack(spacing: 10) {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    let isSelected = selected == option.text
                    Button {
                        selected = option.text
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: option.icon)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(isSelected ? .white : AppTheme.secondaryText)
                                .frame(width: 44, height: 44)
                                .background(isSelected ? AppTheme.primaryAccent : AppTheme.cardSurface)
                                .clipShape(.rect(cornerRadius: 12))

                            Text(option.text)
                                .font(.body.weight(.medium))
                                .foregroundStyle(isSelected ? .white : AppTheme.secondaryText)
                                .multilineTextAlignment(.leading)

                            Spacer()

                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.primaryAccent)
                            }
                        }
                        .padding(16)
                        .background(AppTheme.cardSurface)
                        .clipShape(.rect(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(isSelected ? AppTheme.primaryAccent.opacity(0.6) : AppTheme.border.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .sensoryFeedback(.selection, trigger: selected)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.3).delay(0.05 + Double(index) * 0.04), value: appeared)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)

            Spacer()
        }
        .onAppear { appeared = true }
    }
}

// MARK: - Username Screen

struct SurveyUsernameView: View {
    @Binding var username: String
    @FocusState private var isFocused: Bool
    @State private var appeared: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What should we\ncall you?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .lineSpacing(2)

                Text("Your coach needs to know your name.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
            }
            .padding(.top, 20)
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .animation(.easeIn(duration: 0.4), value: appeared)

            VStack(spacing: 16) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(username.isEmpty ? AppTheme.cardSurface : AppTheme.primaryAccent)
                            .frame(width: 44, height: 44)
                        Image(systemName: "person.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(username.isEmpty ? AppTheme.secondaryText : .white)
                    }

                    TextField("", text: $username, prompt: Text("Enter your name").foregroundStyle(AppTheme.muted))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .focused($isFocused)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                }
                .padding(16)
                .background(AppTheme.cardSurface)
                .clipShape(.rect(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isFocused ? AppTheme.primaryAccent.opacity(0.6) : AppTheme.border.opacity(0.4),
                            lineWidth: isFocused ? 1.5 : 1
                        )
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .opacity(appeared ? 1 : 0)
            .animation(.easeIn(duration: 0.4).delay(0.1), value: appeared)

            Spacer()
        }
        .onAppear {
            appeared = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
    }
}

// MARK: - Dark Theme Screens (Generating, Chart, Social Proof)

struct GeneratingProgramView: View {
    let profile: UserProfile
    let onComplete: () -> Void
    @State private var progress: Double = 0
    @State private var currentItemIndex: Int = 0
    @State private var isComplete: Bool = false
    @State private var showPersonalized: Bool = false

    private var items: [String] {
        [
            "Analyzing \(profile.displayName)'s responses",
            "Mapping your \(profile.bodyFatCategory.rawValue.lowercased()) body type",
            "Building \(profile.goal.rawValue.lowercased()) plan",
            "Calibrating \(Int(profile.tdee)) cal metabolism",
            "Setting your \(profile.estimatedWeeksToAbs)-week timeline",
            "Personalizing everything",
        ]
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            AppTheme.onboardingGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                if isComplete {
                    VStack(spacing: 24) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(AppTheme.success)
                            .shadow(color: AppTheme.success.opacity(0.3), radius: 20)

                        VStack(spacing: 6) {
                            Text("\(profile.displayName), your")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(.white)
                            Text("program is ready.")
                                .font(.system(size: 30, weight: .black))
                                .foregroundStyle(AppTheme.success)
                        }

                        if showPersonalized {
                            HStack(spacing: 16) {
                                programStat(value: "\(profile.calculatedCalorieGoal)", label: "kcal/day", icon: "flame.fill")
                                programStat(value: "~\(profile.estimatedWeeksToAbs)wk", label: "timeline", icon: "clock.fill")
                                programStat(value: "\(Int(profile.calculatedProteinGoal))g", label: "protein", icon: "fish.fill")
                            }
                            .padding(.horizontal, 8)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .transition(.opacity)
                } else {
                    VStack(spacing: 48) {
                        ZStack {
                            Circle()
                                .stroke(AppTheme.border.opacity(0.1), lineWidth: 5)
                                .frame(width: 130, height: 130)

                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(
                                    AppTheme.accentGradient,
                                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                                )
                                .frame(width: 130, height: 130)
                                .rotationEffect(.degrees(-90))

                            Text("\(Int(progress * 100))")
                                .font(.system(size: 36, weight: .black, design: .default))
                                .foregroundStyle(.white)
                                .contentTransition(.numericText())
                                .animation(.snappy, value: Int(progress * 100))
                        }

                        VStack(spacing: 10) {
                            Text(items[currentItemIndex])
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)
                                .contentTransition(.opacity)
                                .id(currentItemIndex)

                            Text("This takes a moment")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AppTheme.muted)
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 32)
            .sensoryFeedback(.impact(weight: .light), trigger: currentItemIndex)
            .onAppear { startBuilding() }
        }
    }

    private func startBuilding() {
        Task {
            for index in 0..<items.count {
                withAnimation(.snappy) { currentItemIndex = index }
                let stepProgress = Double(index + 1) / Double(items.count)
                withAnimation(.easeInOut(duration: 0.7)) { progress = stepProgress }
                try? await Task.sleep(for: .milliseconds(950))
            }
            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.spring(duration: 0.6)) { isComplete = true }
            try? await Task.sleep(for: .milliseconds(600))
            withAnimation(.spring(duration: 0.4)) { showPersonalized = true }
            try? await Task.sleep(for: .seconds(1.8))
            onComplete()
        }
    }

    private func programStat(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.primaryAccent)
            Text(value)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(AppTheme.border, lineWidth: 1)
        )
    }
}

struct WithWithoutChartView: View {
    let estimatedWeeks: Int
    @State private var phase: Int = 0
    @State private var barProgress: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Text("Your Projected Results")
                        .font(.system(size: 24, weight: .black))
                        .foregroundStyle(.white)
                    Text("Based on your profile")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.muted)
                }
                .opacity(phase >= 1 ? 1 : 0)
                .animation(.easeIn(duration: 0.4), value: phase)

                HStack(spacing: 20) {
                    VStack(spacing: 16) {
                        Text("WITHOUT")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(AppTheme.destructive)
                            .tracking(2)

                        VStack(spacing: 4) {
                            ForEach(0..<4, id: \.self) { i in
                                let heights: [CGFloat] = [30, 28, 26, 24]
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AppTheme.destructive.opacity(0.15))
                                    .frame(width: 44, height: barProgress * heights[i])
                            }
                        }
                        .frame(height: 130, alignment: .bottom)

                        Image(systemName: "xmark")
                            .font(.caption2.bold())
                            .foregroundStyle(AppTheme.destructive.opacity(0.6))
                    }

                    Rectangle()
                        .fill(AppTheme.border.opacity(0.15))
                        .frame(width: 1, height: 180)

                    VStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Text("WITH")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundStyle(AppTheme.success)
                                .tracking(2)
                            Text("ABMAXX")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundStyle(AppTheme.primaryAccent)
                                .tracking(1)
                        }

                        VStack(spacing: 4) {
                            ForEach(0..<4, id: \.self) { i in
                                let heights: [CGFloat] = [28, 50, 80, 120]
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [AppTheme.primaryAccent, AppTheme.success],
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                    .frame(width: 44, height: barProgress * heights[i])
                                    .shadow(color: AppTheme.primaryAccent.opacity(0.2), radius: 6)
                            }
                        }
                        .frame(height: 130, alignment: .bottom)

                        Image(systemName: "checkmark")
                            .font(.caption2.bold())
                            .foregroundStyle(AppTheme.success.opacity(0.7))
                    }
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
                .background(AppTheme.cardSurface.opacity(0.5))
                .clipShape(.rect(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(AppTheme.border.opacity(0.25), lineWidth: 1)
                )
                .opacity(phase >= 2 ? 1 : 0)
                .animation(.easeIn(duration: 0.3), value: phase)

                HStack(spacing: 8) {
                    Text("~\(estimatedWeeks) weeks")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(AppTheme.primaryAccent)
                    Text("to visible abs")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .opacity(phase >= 3 ? 1 : 0)
                .animation(.easeIn(duration: 0.5), value: phase)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .onAppear {
            Task {
                try? await Task.sleep(for: .milliseconds(200))
                withAnimation { phase = 1 }
                try? await Task.sleep(for: .milliseconds(400))
                withAnimation { phase = 2 }
                withAnimation(.spring(duration: 1.2)) { barProgress = 1 }
                try? await Task.sleep(for: .seconds(1.0))
                withAnimation { phase = 3 }
            }
        }
    }
}

struct SocialProofView: View {
    @State private var appeared: Bool = false

    private let reviews: [(String, String, String)] = [
        ("Alex M.", "Went from no abs to a visible six-pack in 3 months. The daily routines are perfect.", "19"),
        ("Luca R.", "The scan feature keeps me motivated. Seeing my score go up every phase is addicting.", "21"),
        ("Calvin T.", "I was skeptical but the results speak for themselves. Down 12% body fat.", "18"),
        ("Jake P.", "Finally stopped making excuses. This app held me accountable.", "20"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 10) {
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.body)
                                .foregroundStyle(AppTheme.orange)
                        }
                    }

                    HStack(spacing: 6) {
                        Text("4.9")
                            .font(.system(size: 56, weight: .black, design: .default))
                            .foregroundStyle(.white)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("out of 5")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.muted)
                            Text("50K+ ratings")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.muted)
                        }
                    }
                }
                .padding(.top, 16)

                VStack(spacing: 8) {
                    ForEach(Array(reviews.enumerated()), id: \.offset) { index, review in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(review.0)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.white)

                                Text("·")
                                    .foregroundStyle(AppTheme.border)

                                Text("Age \(review.2)")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(AppTheme.muted)

                                Spacer()

                                HStack(spacing: 1) {
                                    ForEach(0..<5, id: \.self) { _ in
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 7))
                                            .foregroundStyle(AppTheme.orange)
                                    }
                                }
                            }

                            Text(review.1)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
                                .lineSpacing(2)
                        }
                        .padding(16)
                        .background(AppTheme.cardSurface.opacity(0.5))
                        .clipShape(.rect(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(AppTheme.border.opacity(0.2), lineWidth: 1)
                        )
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeIn(duration: 0.3).delay(Double(index) * 0.07), value: appeared)
                    }
                }
                .padding(.horizontal, 24)

                HStack(spacing: 8) {
                    Text("Verified results")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.muted)
                    Text("·")
                        .foregroundStyle(AppTheme.border)
                    Text("AI powered")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.muted)
                    Text("·")
                        .foregroundStyle(AppTheme.border)
                    Text("50K+ users")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.muted)
                }
                .padding(.top, 4)

                Spacer().frame(height: 80)
            }
        }
        .scrollIndicators(.hidden)
        .onAppear { appeared = true }
    }
}

struct SurveyEquipmentView: View {
    @Binding var equipment: EquipmentSetting

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Where will you\ntrain abs?")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 20)
                .padding(.horizontal, 24)

            Text("We'll filter exercises to match your setup.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
                .padding(.top, 8)
                .padding(.horizontal, 24)

            VStack(spacing: 10) {
                ForEach(EquipmentSetting.allCases, id: \.self) { setting in
                    Button {
                        equipment = setting
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: setting.icon)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(equipment == setting ? .white : AppTheme.secondaryText)
                                .frame(width: 44, height: 44)
                                .background(equipment == setting ? AppTheme.primaryAccent : AppTheme.cardSurface)
                                .clipShape(.rect(cornerRadius: 12))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(setting.rawValue)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(equipment == setting ? .white : AppTheme.secondaryText)

                                Text(setting.detail)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.muted)
                                    .lineLimit(2)
                            }

                            Spacer()

                            if equipment == setting {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.primaryAccent)
                            }
                        }
                        .padding(16)
                        .background(AppTheme.cardSurface)
                        .clipShape(.rect(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(equipment == setting ? AppTheme.primaryAccent.opacity(0.6) : AppTheme.border.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .sensoryFeedback(.selection, trigger: equipment)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)

            if equipment == .home {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryAccent)
                    Text("You'll get bodyweight-only exercises \u{2014} no equipment needed")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.primaryAccent.opacity(0.06))
                .clipShape(.rect(cornerRadius: 12))
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }

            Spacer()
        }
    }
}
