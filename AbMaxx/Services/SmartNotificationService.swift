import Foundation
import UserNotifications

@MainActor
class SmartNotificationService {
    static let shared = SmartNotificationService()

    private let center = UNUserNotificationCenter.current()
    private let defaults = UserDefaults.standard

    private var dateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            defaults.set(granted, forKey: "notificationsEnabled")
            return granted
        } catch {
            return false
        }
    }

    func scheduleAllNotifications(
        streakDays: Int,
        hasCompletedTodayWorkout: Bool,
        isTodayRestDay: Bool,
        todayTargetLabel: String,
        exerciseCount: Int,
        scanAvailable: Bool,
        bodyFatPercent: Double?,
        overallScore: Int?,
        weakestZone: String,
        caloriesRemaining: Int,
        proteinProgress: Double,
        waterGlasses: Int,
        waterGoal: Int,
        programDayNumber: Int,
        username: String
    ) {
        center.removeAllPendingNotificationRequests()

        let name = username.isEmpty ? "Champ" : username

        scheduleMorningWorkoutReminder(
            name: name,
            isTodayRestDay: isTodayRestDay,
            todayTargetLabel: todayTargetLabel,
            exerciseCount: exerciseCount,
            streakDays: streakDays,
            programDayNumber: programDayNumber
        )

        scheduleAfternoonNudge(
            name: name,
            hasCompletedTodayWorkout: hasCompletedTodayWorkout,
            isTodayRestDay: isTodayRestDay,
            streakDays: streakDays
        )

        scheduleStreakProtection(
            name: name,
            streakDays: streakDays,
            hasCompletedTodayWorkout: hasCompletedTodayWorkout,
            isTodayRestDay: isTodayRestDay
        )

        scheduleNutritionReminders(
            name: name,
            caloriesRemaining: caloriesRemaining,
            proteinProgress: proteinProgress,
            waterGlasses: waterGlasses,
            waterGoal: waterGoal
        )

        if scanAvailable {
            scheduleScanReminder(name: name, overallScore: overallScore)
        }

        scheduleMilestoneMotivation(
            name: name,
            streakDays: streakDays,
            programDayNumber: programDayNumber,
            overallScore: overallScore,
            bodyFatPercent: bodyFatPercent
        )

        scheduleReEngagement(name: name, streakDays: streakDays)

        scheduleWeeklyRecap(
            name: name,
            programDayNumber: programDayNumber,
            weakestZone: weakestZone
        )
    }

    // MARK: - Morning Workout Reminder (8:00 AM)

    private func scheduleMorningWorkoutReminder(
        name: String,
        isTodayRestDay: Bool,
        todayTargetLabel: String,
        exerciseCount: Int,
        streakDays: Int,
        programDayNumber: Int
    ) {
        let content = UNMutableNotificationContent()
        content.sound = .default

        if isTodayRestDay {
            let restMessages = [
                ("Recovery Day", "\(name), your muscles are rebuilding. Stretch, hydrate, and come back stronger tomorrow."),
                ("Rest = Growth", "Your abs grow during rest, not just training. Enjoy the recovery — you've earned it."),
                ("Active Recovery", "Light stretching and deep breathing today. Your body is adapting and getting stronger.")
            ]
            let pick = restMessages[programDayNumber % restMessages.count]
            content.title = pick.0
            content.body = pick.1
        } else {
            let morningMessages: [(String, String)]
            if streakDays >= 14 {
                morningMessages = [
                    ("Day \(programDayNumber) — \(todayTargetLabel)", "\(name), \(streakDays)-day streak. \(exerciseCount) exercises locked and loaded. Let's keep building."),
                    ("\(todayTargetLabel) Day", "\(exerciseCount) exercises. \(streakDays) days strong. The version of you from Day 1 wouldn't believe where you are now."),
                    ("Your abs are waiting", "\(name), \(todayTargetLabel) — \(exerciseCount) exercises. At \(streakDays) days, quitting isn't even an option anymore.")
                ]
            } else if streakDays >= 3 {
                morningMessages = [
                    ("\(todayTargetLabel) — Day \(programDayNumber)", "\(name), \(exerciseCount) exercises today. \(streakDays)-day streak building. Consistency is the cheat code."),
                    ("Time to train", "\(todayTargetLabel) is on deck. \(exerciseCount) exercises, \(streakDays) days in. Don't break the chain."),
                    ("Your body is adapting", "\(name), Day \(programDayNumber). Your \(todayTargetLabel.lowercased()) session is ready. Show up and results follow.")
                ]
            } else {
                morningMessages = [
                    ("\(todayTargetLabel) Today", "\(name), \(exerciseCount) exercises waiting for you. Every rep gets you closer to visible abs."),
                    ("Day \(programDayNumber) — Let's go", "Your \(todayTargetLabel.lowercased()) workout is ready. \(exerciseCount) exercises. Start building that streak."),
                    ("Abs are made daily", "\(name), today's \(todayTargetLabel.lowercased()) session has \(exerciseCount) exercises. Tap to begin.")
                ]
            }
            let pick = morningMessages[programDayNumber % morningMessages.count]
            content.title = pick.0
            content.body = pick.1
        }

        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        center.add(UNNotificationRequest(identifier: "morning_workout", content: content, trigger: trigger))
    }

    // MARK: - Afternoon Nudge (2:00 PM)

    private func scheduleAfternoonNudge(
        name: String,
        hasCompletedTodayWorkout: Bool,
        isTodayRestDay: Bool,
        streakDays: Int
    ) {
        guard !hasCompletedTodayWorkout && !isTodayRestDay else { return }

        let content = UNMutableNotificationContent()
        content.sound = .default

        if streakDays >= 7 {
            content.title = "Don't lose your \(streakDays)-day streak"
            content.body = "\(name), you haven't trained yet today. A \(streakDays)-day streak is rare — protect it."
        } else if streakDays >= 3 {
            content.title = "Still time to train"
            content.body = "\(name), your workout is still waiting. \(streakDays) days of momentum — don't let it slip."
        } else {
            content.title = "Halfway through the day"
            content.body = "\(name), your ab session takes less than 15 minutes. Squeeze it in now before the day gets away."
        }

        var components = DateComponents()
        components.hour = 14
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        center.add(UNNotificationRequest(identifier: "afternoon_nudge", content: content, trigger: trigger))
    }

    // MARK: - Streak Protection (8:30 PM)

    private func scheduleStreakProtection(
        name: String,
        streakDays: Int,
        hasCompletedTodayWorkout: Bool,
        isTodayRestDay: Bool
    ) {
        guard !hasCompletedTodayWorkout && !isTodayRestDay && streakDays >= 2 else { return }

        let content = UNMutableNotificationContent()
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        if streakDays >= 30 {
            content.title = "\(streakDays)-DAY STREAK IN DANGER"
            content.body = "\(name), you've trained \(streakDays) days straight. That's elite discipline. Don't let tonight be the end — 10 minutes is all it takes."
        } else if streakDays >= 14 {
            content.title = "Your \(streakDays)-day streak expires tonight"
            content.body = "\(name), \(streakDays) days of work. Gone if you don't train before midnight. You've come too far."
        } else if streakDays >= 7 {
            content.title = "Streak alert: \(streakDays) days at risk"
            content.body = "\(name), a full week of consistency is on the line. Quick session before bed — you won't regret it."
        } else {
            content.title = "Your streak is about to break"
            content.body = "\(name), \(streakDays) days in and building momentum. A quick 10-minute session saves your streak."
        }

        var components = DateComponents()
        components.hour = 20
        components.minute = 30
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        center.add(UNNotificationRequest(identifier: "streak_protection", content: content, trigger: trigger))
    }

    // MARK: - Nutrition Reminders

    private func scheduleNutritionReminders(
        name: String,
        caloriesRemaining: Int,
        proteinProgress: Double,
        waterGlasses: Int,
        waterGoal: Int
    ) {
        let lunchContent = UNMutableNotificationContent()
        lunchContent.sound = .default

        if proteinProgress < 0.3 {
            lunchContent.title = "Protein check"
            lunchContent.body = "\(name), you're behind on protein. Prioritize lean protein at lunch — your muscles need it to recover from training."
        } else {
            lunchContent.title = "Log your lunch"
            lunchContent.body = "\(name), \(caloriesRemaining) calories remaining today. Log your meal to stay on track."
        }

        var lunchComponents = DateComponents()
        lunchComponents.hour = 12
        lunchComponents.minute = 30
        let lunchTrigger = UNCalendarNotificationTrigger(dateMatching: lunchComponents, repeats: false)
        center.add(UNNotificationRequest(identifier: "lunch_nutrition", content: lunchContent, trigger: lunchTrigger))

        if waterGlasses < waterGoal / 2 {
            let waterContent = UNMutableNotificationContent()
            waterContent.title = "Hydration check"
            waterContent.body = "\(name), you've had \(waterGlasses)/\(waterGoal) glasses. Dehydration kills ab definition — drink up."
            waterContent.sound = .default

            var waterComponents = DateComponents()
            waterComponents.hour = 15
            waterComponents.minute = 0
            let waterTrigger = UNCalendarNotificationTrigger(dateMatching: waterComponents, repeats: false)
            center.add(UNNotificationRequest(identifier: "water_reminder", content: waterContent, trigger: waterTrigger))
        }

        let dinnerContent = UNMutableNotificationContent()
        dinnerContent.sound = .default
        dinnerContent.title = "Evening nutrition"
        if caloriesRemaining > 500 {
            dinnerContent.body = "\(name), you still have \(caloriesRemaining) cal left. Make dinner count — high protein, moderate carbs."
        } else if caloriesRemaining > 0 {
            dinnerContent.body = "\(name), \(caloriesRemaining) cal remaining. A light, protein-rich dinner will close the day perfectly."
        } else {
            dinnerContent.body = "\(name), you've hit your calorie goal. If you're still hungry, stick to veggies and lean protein."
        }

        var dinnerComponents = DateComponents()
        dinnerComponents.hour = 18
        dinnerComponents.minute = 0
        let dinnerTrigger = UNCalendarNotificationTrigger(dateMatching: dinnerComponents, repeats: false)
        center.add(UNNotificationRequest(identifier: "dinner_nutrition", content: dinnerContent, trigger: dinnerTrigger))
    }

    // MARK: - Scan Reminder

    private func scheduleScanReminder(name: String, overallScore: Int?) {
        let content = UNMutableNotificationContent()
        content.sound = .default
        content.title = "Your scan window is open"

        if let score = overallScore {
            content.body = "\(name), your last score was \(score). Time to see if your hard work moved the needle. Scan now."
        } else {
            content.body = "\(name), it's been a week since your last scan. Check your ab progress — you might be surprised."
        }

        var components = DateComponents()
        components.hour = 10
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        center.add(UNNotificationRequest(identifier: "scan_reminder", content: content, trigger: trigger))
    }

    // MARK: - Milestone Motivation (9:00 PM)

    private func scheduleMilestoneMotivation(
        name: String,
        streakDays: Int,
        programDayNumber: Int,
        overallScore: Int?,
        bodyFatPercent: Double?
    ) {
        let milestones = [3, 7, 14, 21, 30, 50, 60, 75, 90, 100, 150, 200, 365]
        let upcomingStreak = milestones.first(where: { $0 == streakDays + 1 })

        if let milestone = upcomingStreak {
            let content = UNMutableNotificationContent()
            content.sound = .default
            content.title = "Tomorrow is Day \(milestone)"

            switch milestone {
            case 7:
                content.body = "\(name), one full week tomorrow. Most people quit before Day 3. You're different."
            case 14:
                content.body = "\(name), two weeks of consistency. Your body is already changing — even if you can't see it yet."
            case 30:
                content.body = "\(name), 30 days tomorrow. A full month of building abs. The transformation is real."
            case 60:
                content.body = "\(name), two months of grinding. At this point, it's not discipline — it's identity."
            case 90:
                content.body = "\(name), 90 days. A full quarter of relentless work. The results speak for themselves."
            case 100:
                content.body = "\(name), triple digits tomorrow. 100 days of building your dream physique. Legendary."
            case 365:
                content.body = "\(name), ONE FULL YEAR tomorrow. 365 days of commitment. You're in the top 0.1%."
            default:
                content.body = "\(name), Day \(milestone) milestone incoming. Keep the momentum — results are compounding."
            }

            var components = DateComponents()
            components.hour = 21
            components.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            center.add(UNNotificationRequest(identifier: "milestone_motivation", content: content, trigger: trigger))
        }
    }

    // MARK: - Re-Engagement (next day 10 AM, day after 6 PM)

    private func scheduleReEngagement(name: String, streakDays: Int) {
        let content1 = UNMutableNotificationContent()
        content1.sound = .default
        content1.title = "We miss you"
        if streakDays > 0 {
            content1.body = "\(name), you had a \(streakDays)-day streak going. One session and you're back on track. Your abs don't build themselves."
        } else {
            content1.body = "\(name), your workout plan is ready and waiting. One session is all it takes to restart the momentum."
        }

        let trigger1 = UNTimeIntervalNotificationTrigger(timeInterval: 36 * 60 * 60, repeats: false)
        center.add(UNNotificationRequest(identifier: "reengage_1", content: content1, trigger: trigger1))

        let content2 = UNMutableNotificationContent()
        content2.sound = .default
        content2.title = "Your abs are losing progress"
        content2.body = "\(name), every day off is a day your competitors are getting ahead. Open the app and get one session done."

        let trigger2 = UNTimeIntervalNotificationTrigger(timeInterval: 60 * 60 * 60, repeats: false)
        center.add(UNNotificationRequest(identifier: "reengage_2", content: content2, trigger: trigger2))
    }

    // MARK: - Weekly Recap (Sunday 9 AM)

    private func scheduleWeeklyRecap(
        name: String,
        programDayNumber: Int,
        weakestZone: String
    ) {
        let weekNumber = (programDayNumber - 1) / 7 + 1

        let content = UNMutableNotificationContent()
        content.sound = .default
        content.title = "Week \(weekNumber) complete"
        content.body = "\(name), new week starts today. Your \(weakestZone) is the #1 priority. This week's plan is locked in — let's attack it."

        var components = DateComponents()
        components.weekday = 1
        components.hour = 9
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        center.add(UNNotificationRequest(identifier: "weekly_recap", content: content, trigger: trigger))
    }

    // MARK: - Post-Workout Celebration

    func schedulePostWorkoutCelebration(
        name: String,
        streakDays: Int,
        exercisesCompleted: Int,
        todayTargetLabel: String
    ) {
        let content = UNMutableNotificationContent()
        content.sound = .default

        let celebrations = [
            ("Session crushed", "\(name), \(exercisesCompleted) exercises done. \(todayTargetLabel) — dominated. Day \(streakDays) in the books."),
            ("Workout complete", "\(exercisesCompleted) exercises. \(streakDays)-day streak. \(name), your future self thanks you."),
            ("Another one down", "\(name), \(todayTargetLabel) session complete. That's \(streakDays) days of building the physique you want.")
        ]
        let pick = celebrations[streakDays % celebrations.count]
        content.title = pick.0
        content.body = pick.1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2 * 60 * 60, repeats: false)
        center.add(UNNotificationRequest(identifier: "post_workout", content: content, trigger: trigger))
    }

    // MARK: - Cancel Re-engagement (user opened app)

    func cancelReEngagementNotifications() {
        center.removePendingNotificationRequests(withIdentifiers: ["reengage_1", "reengage_2"])
    }

    func disableAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }
}
