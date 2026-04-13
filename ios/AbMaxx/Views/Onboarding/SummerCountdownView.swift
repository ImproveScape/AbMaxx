import SwiftUI

struct SummerCountdownView: View {
    let daysUntilSummer: Int
    let onContinue: () -> Void

    @State private var phase: Int = 0
    @State private var now: Date = Date()
    @State private var timerActive: Bool = false
    @State private var secondsPulse: Bool = false
    @State private var ringRotation: Double = 0
    @State private var glowIntensity: Double = 0.3

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

    private var timeRemaining: (days: Int, hours: Int, minutes: Int, seconds: Int) {
        let interval = max(summerDate.timeIntervalSince(now), 0)
        let totalSeconds = Int(interval)
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return (days, hours, minutes, seconds)
    }

    private var daysProgress: CGFloat {
        CGFloat(max(1.0 - Double(daysUntilSummer) / 365.0, 0.05))
    }

    private let warmAccent = Color(red: 1.0, green: 0.55, blue: 0.2)

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer()

                clockRing
                    .padding(.bottom, 40)
                    .opacity(phase >= 1 ? 1 : 0)
                    .scaleEffect(phase >= 1 ? 1 : 0.7)
                    .animation(.spring(duration: 0.8, bounce: 0.15), value: phase)

                countdownDigits
                    .padding(.bottom, 36)
                    .opacity(phase >= 2 ? 1 : 0)
                    .offset(y: phase >= 2 ? 0 : 20)
                    .animation(.easeOut(duration: 0.6), value: phase)

                motivationText
                    .padding(.horizontal, 32)
                    .opacity(phase >= 3 ? 1 : 0)
                    .offset(y: phase >= 3 ? 0 : 12)
                    .animation(.easeOut(duration: 0.5), value: phase)

                Spacer()

                Button(action: onContinue) {
                    Text("I'm Ready")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(AppTheme.accentGradient)
                        .clipShape(.capsule)
                        .shadow(color: AppTheme.primaryAccent.opacity(0.5), radius: 24, y: 6)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .opacity(phase >= 4 ? 1 : 0)
                .offset(y: phase >= 4 ? 0 : 20)
                .animation(.easeOut(duration: 0.4), value: phase)
            }
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: phase == 2)
        .onAppear {
            startLiveTimer()
            withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowIntensity = 0.8
            }
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                withAnimation { phase = 1 }
                try? await Task.sleep(for: .milliseconds(800))
                withAnimation { phase = 2 }
                try? await Task.sleep(for: .milliseconds(600))
                withAnimation { phase = 3 }
                try? await Task.sleep(for: .milliseconds(500))
                withAnimation { phase = 4 }
            }
        }
    }

    private var clockRing: some View {
        ZStack {
            Circle()
                .fill(warmAccent.opacity(0.04))
                .frame(width: 200, height: 200)
                .blur(radius: 40)

            Circle()
                .stroke(Color.white.opacity(0.04), lineWidth: 3)
                .frame(width: 160, height: 160)

            Circle()
                .trim(from: 0, to: daysProgress)
                .stroke(
                    AngularGradient(
                        colors: [warmAccent.opacity(0.1), warmAccent, warmAccent.opacity(0.6)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))
                .shadow(color: warmAccent.opacity(glowIntensity * 0.5), radius: 12)

            ForEach(0..<60, id: \.self) { tick in
                let isMajor = tick % 5 == 0
                Rectangle()
                    .fill(Color.white.opacity(isMajor ? 0.2 : 0.06))
                    .frame(width: isMajor ? 1.5 : 0.5, height: isMajor ? 10 : 5)
                    .offset(y: -70)
                    .rotationEffect(.degrees(Double(tick) * 6))
            }

            sweepHand

            VStack(spacing: 4) {
                Text("\(timeRemaining.days)")
                    .font(.system(size: 48, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: timeRemaining.days)

                Text("DAYS LEFT")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(warmAccent.opacity(0.8))
                    .tracking(3)
            }
        }
    }

    private var sweepHand: some View {
        let secondAngle = Double(timeRemaining.seconds) * 6.0
        return Rectangle()
            .fill(
                LinearGradient(
                    colors: [warmAccent, warmAccent.opacity(0.3)],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: 1.5, height: 55)
            .offset(y: -27.5)
            .rotationEffect(.degrees(secondAngle))
            .animation(.linear(duration: 0.3), value: timeRemaining.seconds)
    }

    private var countdownDigits: some View {
        HStack(spacing: 6) {
            countdownUnit(value: timeRemaining.hours, label: "HRS")
            digitSeparator
            countdownUnit(value: timeRemaining.minutes, label: "MIN")
            digitSeparator
            countdownUnit(value: timeRemaining.seconds, label: "SEC")
        }
        .padding(.horizontal, 24)
    }

    private func countdownUnit(value: Int, label: String) -> some View {
        VStack(spacing: 6) {
            Text(String(format: "%02d", value))
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.9))
                .contentTransition(.numericText())
                .animation(.snappy, value: value)

            Text(label)
                .font(.system(size: 9, weight: .heavy))
                .foregroundStyle(.white.opacity(0.3))
                .tracking(2)
        }
        .frame(maxWidth: .infinity)
    }

    private var digitSeparator: some View {
        Text(":")
            .font(.system(size: 24, weight: .bold, design: .monospaced))
            .foregroundStyle(.white.opacity(secondsPulse ? 0.4 : 0.15))
            .offset(y: -6)
            .animation(.easeInOut(duration: 0.5), value: secondsPulse)
    }

    private var motivationText: some View {
        VStack(spacing: 10) {
            Text("Summer doesn't wait.")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)

            Text("Start now and walk into summer\nwith abs you built yourself.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.35))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    private func startLiveTimer() {
        guard !timerActive else { return }
        timerActive = true
        Task {
            while timerActive {
                try? await Task.sleep(for: .seconds(1))
                now = Date()
                secondsPulse.toggle()
            }
        }
    }
}
