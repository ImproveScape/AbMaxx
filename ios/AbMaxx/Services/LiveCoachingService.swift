import Foundation

@Observable
class LiveCoachingService {
    var currentTip: String = ""
    var tipCategory: TipCategory = .form
    private var tipTimer: Task<Void, Never>?
    private var exerciseId: String = ""
    private var tipIndex: Int = 0
    private var lastPoseFeedback: String = ""
    private var lastPoseFeedbackTime: Date = .distantPast
    private var consecutiveGoodFrames: Int = 0
    private var consecutiveBadFrames: Int = 0

    nonisolated enum TipCategory: Sendable {
        case form
        case tempo
        case breathing
        case motivation
        case correction
    }

    func updateWithPoseFeedback(_ feedback: FormFeedback?, repCount: Int) {
        guard let feedback else { return }

        let now = Date()
        guard now.timeIntervalSince(lastPoseFeedbackTime) > 1.5 else { return }

        switch feedback.quality {
        case .bad:
            consecutiveBadFrames += 1
            consecutiveGoodFrames = 0
            if consecutiveBadFrames > 3 {
                currentTip = feedback.message
                tipCategory = .correction
                lastPoseFeedbackTime = now
                consecutiveBadFrames = 0
            }
        case .warning:
            consecutiveBadFrames += 1
            consecutiveGoodFrames = 0
            if consecutiveBadFrames > 5 {
                currentTip = feedback.message
                tipCategory = .form
                lastPoseFeedbackTime = now
                consecutiveBadFrames = 0
            }
        case .good:
            consecutiveGoodFrames += 1
            consecutiveBadFrames = 0
            if consecutiveGoodFrames > 8 {
                currentTip = feedback.message
                tipCategory = .motivation
                lastPoseFeedbackTime = now
                consecutiveGoodFrames = 0
            }
        }

        if repCount > 0 && repCount % 5 == 0 && now.timeIntervalSince(lastPoseFeedbackTime) > 3 {
            let motivations = [
                "\(repCount) reps — keep pushing!",
                "Feeling the burn yet?",
                "Solid \(repCount) reps!",
                "Don't stop now!",
            ]
            currentTip = motivations[repCount / 5 % motivations.count]
            tipCategory = .motivation
            lastPoseFeedbackTime = now
        }
    }

    private static let exerciseCoaching: [String: [(String, TipCategory)]] = [
        "plank": [
            ("Squeeze glutes tight", .form),
            ("Keep hips level", .form),
            ("Breathe steady", .breathing),
            ("Don't let hips sag", .form),
            ("Brace your core hard", .form),
            ("Shoulders over elbows", .form),
            ("You're locked in", .motivation),
        ],
        "dead_bug": [
            ("Lower back stays flat", .form),
            ("Move slow and controlled", .tempo),
            ("Exhale as you extend", .breathing),
            ("Opposite arm, opposite leg", .form),
            ("Keep core braced", .form),
            ("Great stability work", .motivation),
        ],
        "bird_dog": [
            ("Keep hips level", .form),
            ("No rotation in your torso", .form),
            ("Pause at full extension", .tempo),
            ("Squeeze at the top", .form),
            ("Breathe through it", .breathing),
        ],
        "hollow_hold": [
            ("Press lower back down", .form),
            ("Squeeze everything tight", .form),
            ("Arms by your ears", .form),
            ("Legs 6 inches off floor", .form),
            ("Keep breathing", .breathing),
            ("Hold that tension", .motivation),
        ],
        "stomach_vacuum": [
            ("Pull belly button to spine", .form),
            ("Breathe through your chest", .breathing),
            ("Hold the contraction", .form),
            ("Feel the deep core engage", .form),
        ],
        "side_plank": [
            ("Stack your feet", .form),
            ("Hips up, don't sag", .form),
            ("Squeeze obliques", .form),
            ("Elbow under shoulder", .form),
            ("Breathe steady", .breathing),
        ],
        "slow_mountain_climbers": [
            ("3 seconds per leg", .tempo),
            ("Keep hips low", .form),
            ("Core stays braced", .form),
            ("Slow and controlled", .tempo),
            ("No rushing", .tempo),
        ],
        "crunches": [
            ("Lift shoulder blades up", .form),
            ("Squeeze at the top", .form),
            ("Don't pull your neck", .form),
            ("Slow on the way down", .tempo),
            ("Exhale as you crunch", .breathing),
            ("Feel the upper abs burn", .motivation),
        ],
        "sit_ups": [
            ("Control the descent", .tempo),
            ("Don't use momentum", .form),
            ("Exhale going up", .breathing),
            ("3 seconds down", .tempo),
            ("Core stays tight", .form),
        ],
        "toe_touch_control": [
            ("Reach past your toes", .form),
            ("Shoulders off the ground", .form),
            ("Slow and controlled", .tempo),
            ("Feel the peak contraction", .form),
        ],
        "cable_crunch": [
            ("Round your spine", .form),
            ("Don't hinge at hips", .form),
            ("Squeeze abs hard", .form),
            ("Control the return", .tempo),
        ],
        "decline_crunch": [
            ("Stop at 30 degrees", .form),
            ("Squeeze at the top", .form),
            ("Slow negative", .tempo),
            ("Upper abs doing the work", .form),
        ],
        "crunch_hold": [
            ("Keep shoulders up", .form),
            ("Breathe through it", .breathing),
            ("Maintain the squeeze", .form),
            ("Don't let shoulders drop", .form),
        ],
        "weighted_crunch": [
            ("Weight on chest, not neck", .form),
            ("Squeeze hard at top", .form),
            ("2 second hold at peak", .tempo),
            ("Slow descent", .tempo),
        ],
        "ab_rollout": [
            ("Don't let hips sag", .form),
            ("Core tight the whole time", .form),
            ("Go as far as you can", .form),
            ("Pull back with your abs", .form),
        ],
        "v_ups": [
            ("Reach past your toes", .form),
            ("Balance on tailbone", .form),
            ("Control the descent", .tempo),
            ("Full range of motion", .form),
        ],
        "pulse_crunches": [
            ("Never touch the ground", .form),
            ("Constant tension", .form),
            ("Quick rhythm", .tempo),
            ("Feel that burn", .motivation),
        ],
        "hanging_leg_raises": [
            ("No swinging", .form),
            ("Curl your pelvis up", .form),
            ("Slow on the way down", .tempo),
            ("Control is everything", .tempo),
            ("Lower abs doing the work", .motivation),
        ],
        "reverse_crunches": [
            ("Curl hips, not knees", .form),
            ("Squeeze lower abs", .form),
            ("No momentum", .tempo),
            ("Slow and controlled", .tempo),
        ],
        "flutter_kicks": [
            ("Lower back stays flat", .form),
            ("Small rapid movements", .tempo),
            ("Don't touch the ground", .form),
            ("Keep core tight", .form),
            ("Breathe through it", .breathing),
        ],
        "scissor_kicks": [
            ("Keep range small", .form),
            ("Lower back pressed down", .form),
            ("Core stays braced", .form),
            ("Controlled crossing", .tempo),
        ],
        "leg_raises": [
            ("3 seconds on the way down", .tempo),
            ("Lower back stays flat", .form),
            ("Don't touch the ground", .form),
            ("Control the descent", .tempo),
            ("Lower abs are working", .motivation),
        ],
        "l_sit_hold": [
            ("Press through your hands", .form),
            ("Legs parallel to floor", .form),
            ("Core fully braced", .form),
            ("Keep breathing", .breathing),
        ],
        "mountain_climbers": [
            ("Hips stay low", .form),
            ("Drive knees to chest", .form),
            ("Keep the rhythm", .tempo),
            ("Core braced throughout", .form),
        ],
        "toe_raise_lying": [
            ("Toes to the ceiling", .form),
            ("Squeeze lower abs", .form),
            ("Slow descent", .tempo),
            ("Lift hips 1 inch at top", .form),
        ],
        "bench_leg_raises": [
            ("Lean back slightly", .form),
            ("Focus on the curl", .form),
            ("Don't swing", .form),
            ("Control the movement", .tempo),
        ],
        "reverse_crunch_pulse": [
            ("Tiny pulses only", .tempo),
            ("2 inches max", .form),
            ("Constant tension", .form),
            ("Don't drop between pulses", .form),
        ],
        "russian_twists": [
            ("Slow down — 3 sec per rep", .tempo),
            ("Rotate your ribcage", .form),
            ("Feet off the ground", .form),
            ("Touch the ground each side", .form),
            ("Obliques are burning", .motivation),
        ],
        "bicycle_crunch": [
            ("Rotate your whole ribcage", .form),
            ("Control, not speed", .tempo),
            ("Full extension each rep", .form),
            ("Elbow to opposite knee", .form),
        ],
        "side_plank_dips": [
            ("Full range of motion", .form),
            ("Hip to floor and back up", .form),
            ("Squeeze at the top", .form),
            ("Don't rush", .tempo),
        ],
        "oblique_crunch": [
            ("Squeeze at the top for 2s", .tempo),
            ("Lateral crunch motion", .form),
            ("Feel the side abs work", .form),
            ("Slow descent", .tempo),
        ],
        "heel_taps": [
            ("Shoulders stay off ground", .form),
            ("Reach for your heel", .form),
            ("Constant oblique tension", .form),
            ("Side to side rhythm", .tempo),
        ],

        "cross_body_mountain_climbers": [
            ("Knee past your midline", .form),
            ("Drive to opposite elbow", .form),
            ("Keep hips low", .form),
            ("Controlled rhythm", .tempo),
        ],
        "windshield_wipers": [
            ("Control the descent", .tempo),
            ("Don't touch the ground", .form),
            ("Slow side to side", .tempo),
            ("Obliques control the motion", .form),
        ],
        "twisting_sit_ups": [
            ("Pause at the top", .tempo),
            ("Full rotation each rep", .form),
            ("Alternate sides", .form),
            ("Control the descent", .tempo),
        ],

    ]

    private static let genericCoaching: [(String, TipCategory)] = [
        ("Keep your core braced", .form),
        ("Breathe through it", .breathing),
        ("Control the movement", .tempo),
        ("You're doing great", .motivation),
        ("Stay focused", .motivation),
        ("Quality over speed", .tempo),
    ]

    func start(for exerciseId: String) {
        self.exerciseId = exerciseId
        tipIndex = 0
        consecutiveGoodFrames = 0
        consecutiveBadFrames = 0
        lastPoseFeedbackTime = .distantPast
        let tips = Self.exerciseCoaching[exerciseId] ?? Self.genericCoaching
        guard !tips.isEmpty else { return }

        currentTip = tips[0].0
        tipCategory = tips[0].1

        tipTimer?.cancel()
        tipTimer = Task {
            var idx = 1
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(6))
                guard !Task.isCancelled else { return }
                let tip = tips[idx % tips.count]
                currentTip = tip.0
                tipCategory = tip.1
                idx += 1
            }
        }
    }

    func stop() {
        tipTimer?.cancel()
        tipTimer = nil
        currentTip = ""
        consecutiveGoodFrames = 0
        consecutiveBadFrames = 0
    }
}
