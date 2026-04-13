import SwiftUI

struct RecoveryView: View {
    @Bindable var vm: AppViewModel
    @State private var sorenessLevel: Int = 0
    @State private var sleepHours: Double = 7.0
    @State private var saved: Bool = false

    private var todaysRecovery: RecoveryDay? {
        let calendar = Calendar.current
        return vm.recoveryDays.first { calendar.isDateInToday($0.date) }
    }

    private var isRestDay: Bool {
        vm.isRestDay
    }

    private var weeklyRecoveryScore: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recent = vm.recoveryDays.filter { $0.date >= weekAgo }
        guard !recent.isEmpty else { return 75 }
        return recent.reduce(0) { $0 + $1.recoveryScore } / recent.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        restDayBanner
                        recoveryScoreCard
                        logRecoveryCard
                        weeklyOverview
                        recoveryTips
                        Color.clear.frame(height: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Recovery")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                if let today = todaysRecovery {
                    sorenessLevel = today.sorenessLevel
                    sleepHours = today.sleepHours
                }
            }
        }
    }

    private var restDayBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isRestDay ? AppTheme.success.opacity(0.15) : AppTheme.primaryAccent.opacity(0.12))
                    .frame(width: 50, height: 50)
                Image(systemName: isRestDay ? "bed.double.fill" : "figure.core.training")
                    .font(.body.bold())
                    .foregroundStyle(isRestDay ? AppTheme.success : AppTheme.primaryAccent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(isRestDay ? "Rest Day" : "Training Day")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                Text(isRestDay ? "Your muscles grow during rest. Take it easy today." : "Day \(vm.profile.daysOnProgram) of your ab journey")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
        }
        .padding(16)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: AppTheme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .strokeBorder((isRestDay ? AppTheme.success : AppTheme.primaryAccent).opacity(0.3), lineWidth: 1)
        )
    }

    private var recoveryScoreCard: some View {
        HStack(spacing: 0) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(AppTheme.border.opacity(0.3), lineWidth: 6)
                        .frame(width: 80, height: 80)
                    Circle()
                        .trim(from: 0, to: Double(weeklyRecoveryScore) / 100.0)
                        .stroke(recoveryColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    Text("\(weeklyRecoveryScore)")
                        .font(.system(size: 22, weight: .bold, design: .default))
                        .foregroundStyle(.white)
                }
                Text("Recovery Score")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.muted)
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 10) {
                recoveryMetric(icon: "moon.fill", label: "Avg Sleep", value: String(format: "%.1fh", avgSleep), color: Color(red: 0.5, green: 0.4, blue: 1.0))
                recoveryMetric(icon: "flame.fill", label: "Streak", value: "\(vm.profile.streakDays)d", color: AppTheme.orange)
                recoveryMetric(icon: "heart.fill", label: "Rest Days", value: "\(restDaysThisWeek)/wk", color: AppTheme.destructive)
            }
            .frame(maxWidth: .infinity)
        }
        .cardStyle(highlighted: true)
    }

    private func recoveryMetric(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 18)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.muted)
            Spacer()
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(.white)
        }
    }

    private var logRecoveryCard: some View {
        VStack(spacing: 18) {
            HStack {
                Text("Log Today's Recovery")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                Spacer()
                if saved {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text("Saved")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(AppTheme.success)
                    .transition(.scale.combined(with: .opacity))
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Soreness Level")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.secondaryText)
                HStack(spacing: 8) {
                    ForEach(0..<5) { level in
                        Button {
                            sorenessLevel = level
                            saveRecovery()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: sorenessIcon(level))
                                    .font(.title3)
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
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Sleep")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                    Spacer()
                    Text(String(format: "%.1f hours", sleepHours))
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                }
                Slider(value: $sleepHours, in: 3...12, step: 0.5)
                    .tint(AppTheme.primaryAccent)
                    .onChange(of: sleepHours) { _, _ in saveRecovery() }
            }
        }
        .cardStyle()
    }

    private var weeklyOverview: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("This Week")
                .font(.headline.bold())
                .foregroundStyle(.white)

            HStack(spacing: 6) {
                let calendar = Calendar.current
                let weekday = calendar.component(.weekday, from: Date())
                let weekStart = calendar.date(byAdding: .day, value: -(weekday - 1), to: Date()) ?? Date()

                ForEach(0..<7) { i in
                    let day = calendar.date(byAdding: .day, value: i, to: weekStart)!
                    let isToday = calendar.isDateInToday(day)
                    let recovery = vm.recoveryDays.first { calendar.isDate($0.date, inSameDayAs: day) }
                    let dayName = calendar.shortWeekdaySymbols[i]

                    VStack(spacing: 6) {
                        Text(dayName.prefix(1).uppercased())
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(isToday ? .white : AppTheme.muted)

                        ZStack {
                            Circle()
                                .fill(recovery != nil ? AppTheme.primaryAccent.opacity(0.15) : AppTheme.cardSurfaceElevated)
                                .frame(width: 36, height: 36)
                            if isToday {
                                Circle()
                                    .strokeBorder(AppTheme.primaryAccent, lineWidth: 2)
                                    .frame(width: 36, height: 36)
                            }
                            if let r = recovery {
                                Text("\(r.recoveryScore)")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.white)
                            } else if day <= Date() {
                                Circle()
                                    .fill(AppTheme.muted.opacity(0.3))
                                    .frame(width: 6, height: 6)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .cardStyle()
    }

    private var recoveryTips: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recovery Tips")
                .font(.headline.bold())
                .foregroundStyle(.white)

            recoveryTipRow(icon: "moon.fill", text: "Aim for 7-9 hours of quality sleep", color: Color(red: 0.5, green: 0.4, blue: 1.0))
            recoveryTipRow(icon: "drop.fill", text: "Stay hydrated — dehydration slows recovery", color: Color(red: 0.3, green: 0.7, blue: 1.0))
            recoveryTipRow(icon: "figure.walk", text: "Light walking on rest days improves blood flow", color: AppTheme.success)
            recoveryTipRow(icon: "fork.knife", text: "Protein within 2 hours of training aids repair", color: AppTheme.orange)
        }
        .cardStyle()
    }

    private func recoveryTipRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundStyle(color)
                .frame(width: 24)
            Text(text)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.secondaryText)
        }
    }

    private func saveRecovery() {
        vm.logRecovery(sorenessLevel: sorenessLevel, sleepHours: sleepHours)
        withAnimation(.spring(duration: 0.3)) { saved = true }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { saved = false }
        }
    }

    private var recoveryColor: Color {
        if weeklyRecoveryScore >= 80 { return AppTheme.success }
        if weeklyRecoveryScore >= 60 { return AppTheme.warning }
        return AppTheme.destructive
    }

    private var avgSleep: Double {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recent = vm.recoveryDays.filter { $0.date >= weekAgo }
        guard !recent.isEmpty else { return 0 }
        return recent.reduce(0) { $0 + $1.sleepHours } / Double(recent.count)
    }

    private var restDaysThisWeek: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return vm.recoveryDays.filter { $0.date >= weekAgo && $0.isRestDay }.count
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
