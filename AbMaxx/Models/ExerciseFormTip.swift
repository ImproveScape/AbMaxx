import Foundation

nonisolated struct ExerciseFormTip: Sendable {
    let exerciseId: String
    let region: AbRegion
    let tip: String

    static let tips: [ExerciseFormTip] = [
        ExerciseFormTip(exerciseId: "russian_twists", region: .obliques, tip: "Most people rush Russian Twists. Slow down to 3 seconds per rep — that's what grows obliques."),
        ExerciseFormTip(exerciseId: "bicycle_crunch", region: .obliques, tip: "Don't just touch elbow to knee — focus on rotating your entire ribcage. That's where oblique activation lives."),
        ExerciseFormTip(exerciseId: "side_plank_dips", region: .obliques, tip: "Drop your hip all the way to the floor before driving up. Full range = full oblique engagement."),
        ExerciseFormTip(exerciseId: "oblique_crunch", region: .obliques, tip: "Squeeze at the top for 2 seconds. Most people skip the hold — that's where the growth stimulus is."),
        ExerciseFormTip(exerciseId: "heel_taps", region: .obliques, tip: "Keep your shoulders off the ground the entire set. The moment they drop, oblique tension disappears."),
        ExerciseFormTip(exerciseId: "windshield_wipers", region: .obliques, tip: "Control the descent — if your legs fall to the side, you're using momentum, not obliques."),
        ExerciseFormTip(exerciseId: "cross_body_mountain_climbers", region: .obliques, tip: "Drive your knee past your midline toward the opposite elbow. Half-reps won't hit the obliques."),
        ExerciseFormTip(exerciseId: "twisting_sit_ups", region: .obliques, tip: "Pause at the top of the twist. If you can't hold it for 1 second, you're going too fast."),

        ExerciseFormTip(exerciseId: "reverse_crunches", region: .lowerAbs, tip: "Curl your pelvis up, not your knees. Think about tilting your hips toward your ribcage."),
        ExerciseFormTip(exerciseId: "hanging_leg_raises", region: .lowerAbs, tip: "Don't swing. Dead hang, then curl your pelvis upward. The moment you swing, hip flexors take over."),
        ExerciseFormTip(exerciseId: "flutter_kicks", region: .lowerAbs, tip: "Press your lower back into the floor. If it arches, raise your legs slightly higher until you can maintain contact."),
        ExerciseFormTip(exerciseId: "leg_raises", region: .lowerAbs, tip: "The lowering phase is where your lower abs work hardest. Take 3 seconds to lower — don't just drop."),
        ExerciseFormTip(exerciseId: "scissor_kicks", region: .lowerAbs, tip: "Keep the range small and controlled. Big sweeping motions shift the load to your hip flexors."),
        ExerciseFormTip(exerciseId: "mountain_climbers", region: .lowerAbs, tip: "Keep your hips low and level. If they pike up, you lose lower ab tension entirely."),
        ExerciseFormTip(exerciseId: "l_sit_hold", region: .lowerAbs, tip: "Can't hold legs straight? Start with bent knees. The goal is posterior pelvic tilt, not leg height."),
        ExerciseFormTip(exerciseId: "bench_leg_raises", region: .lowerAbs, tip: "Lean back slightly and focus on the curl at the top. Don't just lift and drop."),
        ExerciseFormTip(exerciseId: "reverse_crunch_pulse", region: .lowerAbs, tip: "Each pulse should be tiny — 2 inches max. Constant tension is the point."),
        ExerciseFormTip(exerciseId: "toe_raise_lying", region: .lowerAbs, tip: "At the top, push your toes toward the ceiling by lifting your hips 1 inch. That extra curl hits deep lower abs."),

        ExerciseFormTip(exerciseId: "crunches", region: .upperAbs, tip: "Lift your shoulder blades completely off the ground. Half-crunches barely activate the upper abs."),
        ExerciseFormTip(exerciseId: "sit_ups", region: .upperAbs, tip: "Slow the descent to 3 seconds. The eccentric phase builds upper ab thickness faster than the up phase."),
        ExerciseFormTip(exerciseId: "cable_crunch", region: .upperAbs, tip: "Round your spine, don't hinge at the hips. You should feel your abs crunch, not your back fold."),
        ExerciseFormTip(exerciseId: "v_ups", region: .upperAbs, tip: "Reach past your toes, not just toward them. That extra 2 inches of reach maximizes peak contraction."),
        ExerciseFormTip(exerciseId: "ab_rollout", region: .upperAbs, tip: "Never let your hips sag. The moment your lower back arches, stop — you've gone past your range."),
        ExerciseFormTip(exerciseId: "weighted_crunch", region: .upperAbs, tip: "Hold the weight on your chest, not behind your head. Behind the head loads your neck, not your abs."),
        ExerciseFormTip(exerciseId: "decline_crunch", region: .upperAbs, tip: "Don't come all the way up — stop at 30 degrees. Going higher shifts tension to hip flexors."),
        ExerciseFormTip(exerciseId: "crunch_hold", region: .upperAbs, tip: "Breathe through the hold. Holding your breath reduces time under tension and kills the set early."),
        ExerciseFormTip(exerciseId: "pulse_crunches", region: .upperAbs, tip: "Never let your shoulders touch the ground. Constant tension is the entire point of pulses."),
        ExerciseFormTip(exerciseId: "toe_touch_control", region: .upperAbs, tip: "Reach with your chest, not just your arms. Your shoulder blades should fully clear the floor."),

        ExerciseFormTip(exerciseId: "plank", region: .deepCore, tip: "Squeeze your glutes and brace like someone's about to punch your stomach. Passive planks build nothing."),
        ExerciseFormTip(exerciseId: "dead_bug", region: .deepCore, tip: "Your lower back must stay glued to the floor. If it lifts, reduce the range until you can maintain contact."),
        ExerciseFormTip(exerciseId: "bird_dog", region: .deepCore, tip: "Place a water bottle on your lower back. If it falls, your hips are rotating — that means your deep core isn't engaged."),
        ExerciseFormTip(exerciseId: "hollow_hold", region: .deepCore, tip: "Think about pulling your belly button to the floor. The tighter you squeeze, the more effective the hold."),
        ExerciseFormTip(exerciseId: "stomach_vacuum", region: .deepCore, tip: "Practice on all fours first — gravity assists the pull-in. Standing vacuums are the progression, not the start."),
        ExerciseFormTip(exerciseId: "side_plank", region: .deepCore, tip: "Stack your feet and squeeze your top hip toward the ceiling. Sagging hips = zero deep core activation."),
        ExerciseFormTip(exerciseId: "slow_mountain_climbers", region: .deepCore, tip: "3 seconds per leg, minimum. If you're going faster, you're doing regular mountain climbers, not slow ones."),

    ]

    static func tip(for exerciseId: String, weakZone: AbRegion) -> ExerciseFormTip? {
        tips.first { $0.exerciseId == exerciseId && $0.region == weakZone }
    }

    static func tipForExercise(_ exerciseId: String) -> ExerciseFormTip? {
        tips.first { $0.exerciseId == exerciseId }
    }
}
