import Foundation

nonisolated struct ExerciseDetailInfo: Sendable {
    let commonMistakes: [String]
    let breathingTips: [String]
    let focusMuscles: [MuscleHighlight]
}

nonisolated struct MuscleHighlight: Sendable {
    let name: String
    let isPrimary: Bool
}

nonisolated enum ExerciseDetailData {
    static func info(for exerciseId: String) -> ExerciseDetailInfo {
        switch exerciseId {
        case "plank":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Letting your hips sag toward the floor, reducing core activation",
                    "Piking your hips too high, shifting work away from your abs",
                    "Holding your breath instead of breathing steadily"
                ],
                breathingTips: [
                    "Breathe in slowly through your nose for 3-4 seconds",
                    "Exhale through your mouth while maintaining core tension",
                    "Never hold your breath — steady breathing keeps muscles oxygenated"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Transverse Abdominis", isPrimary: true),
                    MuscleHighlight(name: "Rectus Abdominis", isPrimary: true),
                    MuscleHighlight(name: "Obliques", isPrimary: false),
                    MuscleHighlight(name: "Shoulders", isPrimary: false)
                ]
            )
        case "dead_bug":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Arching your lower back off the floor as you extend",
                    "Moving too fast and using momentum instead of control",
                    "Not fully extending the arm and leg on each rep"
                ],
                breathingTips: [
                    "Exhale as you extend the opposite arm and leg",
                    "Inhale as you return to the starting position",
                    "Keep your core braced throughout each breath"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Transverse Abdominis", isPrimary: true),
                    MuscleHighlight(name: "Rectus Abdominis", isPrimary: true),
                    MuscleHighlight(name: "Hip Flexors", isPrimary: false)
                ]
            )
        case "bird_dog":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Rotating your hips as you extend — keep them square to the floor",
                    "Rushing through reps without pausing at full extension",
                    "Letting your lower back arch excessively"
                ],
                breathingTips: [
                    "Inhale in the starting position on all fours",
                    "Exhale as you extend the opposite arm and leg",
                    "Inhale as you return to the start"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Transverse Abdominis", isPrimary: true),
                    MuscleHighlight(name: "Erector Spinae", isPrimary: true),
                    MuscleHighlight(name: "Glutes", isPrimary: false)
                ]
            )
        case "hollow_hold":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Letting your lower back lift off the floor",
                    "Bending your knees or arms to make it easier",
                    "Holding your breath during the hold"
                ],
                breathingTips: [
                    "Take shallow, controlled breaths while holding",
                    "Focus on exhaling to maintain core compression",
                    "Don't let breathing break your body position"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Rectus Abdominis", isPrimary: true),
                    MuscleHighlight(name: "Transverse Abdominis", isPrimary: true),
                    MuscleHighlight(name: "Hip Flexors", isPrimary: false)
                ]
            )
        case "stomach_vacuum":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Not fully exhaling before pulling your belly in",
                    "Using your chest muscles instead of your deep core",
                    "Holding the position for too short a time"
                ],
                breathingTips: [
                    "Exhale all the air from your lungs before pulling in",
                    "Breathe shallowly through your chest while holding",
                    "Release the vacuum with a full inhale before repeating"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Transverse Abdominis", isPrimary: true)
                ]
            )
        case "side_plank":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Letting your hips drop toward the floor",
                    "Placing your elbow too far from your shoulder",
                    "Rotating your torso forward or backward"
                ],
                breathingTips: [
                    "Breathe steadily — don't hold your breath",
                    "Exhale to tighten your obliques during the hold",
                    "Inhale through your nose to maintain stability"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Obliques", isPrimary: true),
                    MuscleHighlight(name: "Transverse Abdominis", isPrimary: true),
                    MuscleHighlight(name: "Glutes", isPrimary: false)
                ]
            )
        case "slow_mountain_climbers":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Going too fast — the point is slow, controlled reps",
                    "Letting your hips pike up as you bring the knee in",
                    "Not fully extending the leg back on each rep"
                ],
                breathingTips: [
                    "Exhale as you drive each knee toward your chest",
                    "Inhale as you extend the leg back",
                    "Keep a steady rhythm matching your breath to movement"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Transverse Abdominis", isPrimary: true),
                    MuscleHighlight(name: "Hip Flexors", isPrimary: false),
                    MuscleHighlight(name: "Shoulders", isPrimary: false)
                ]
            )
        case "crunches":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Pulling your neck with your hands instead of using your abs",
                    "Using momentum to swing up rather than controlled contraction",
                    "Not lifting your shoulder blades fully off the ground"
                ],
                breathingTips: [
                    "Exhale as you crunch up and contract your abs",
                    "Inhale as you lower back down with control",
                    "Proper breathing engages the core and stabilizes your spine"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Rectus Abdominis", isPrimary: true),
                    MuscleHighlight(name: "Obliques", isPrimary: false)
                ]
            )
        case "sit_ups":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Using your hip flexors to pull yourself up instead of your abs",
                    "Jerking your neck forward at the start of the movement",
                    "Dropping back down without control on the descent"
                ],
                breathingTips: [
                    "Exhale as you sit up, engaging your core throughout",
                    "Inhale as you lower back down slowly",
                    "Maintain steady breathing to avoid dizziness"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Rectus Abdominis", isPrimary: true),
                    MuscleHighlight(name: "Hip Flexors", isPrimary: false)
                ]
            )
        case "toe_touch_control":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Bending your knees to make reaching easier",
                    "Using momentum to swing your arms toward your toes",
                    "Not fully lifting your shoulder blades off the floor"
                ],
                breathingTips: [
                    "Exhale forcefully as you reach for your toes",
                    "Inhale as you lower your shoulders back to the floor",
                    "The exhale helps compress your abs for a stronger contraction"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Rectus Abdominis", isPrimary: true),
                    MuscleHighlight(name: "Hip Flexors", isPrimary: false)
                ]
            )
        case "cable_crunch":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Sitting back on your heels instead of crunching your spine",
                    "Using your arms to pull the cable instead of your abs",
                    "Not squeezing at the bottom of the movement"
                ],
                breathingTips: [
                    "Exhale as you crunch down, squeezing your abs",
                    "Inhale as you return to the starting position",
                    "Focus on a controlled exhale for maximum contraction"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Rectus Abdominis", isPrimary: true),
                    MuscleHighlight(name: "Transverse Abdominis", isPrimary: false)
                ]
            )
        case "decline_crunch":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Coming up too high, turning it into a sit-up",
                    "Using momentum from the decline angle",
                    "Not controlling the descent back down"
                ],
                breathingTips: [
                    "Exhale as you curl up against gravity",
                    "Inhale as you slowly lower back to the decline",
                    "Keep breathing rhythmic to maintain core engagement"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Rectus Abdominis", isPrimary: true)
                ]
            )
        case "crunch_hold":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Letting your shoulders slowly sink back to the floor",
                    "Tensing your neck instead of your abs",
                    "Holding your breath during the isometric hold"
                ],
                breathingTips: [
                    "Breathe shallowly while holding the crunch position",
                    "Each exhale should tighten your ab contraction",
                    "Don't let breathing cause your shoulders to drop"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Rectus Abdominis", isPrimary: true)
                ]
            )
        case "weighted_crunch":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Using too heavy a weight that pulls you up with momentum",
                    "Letting the weight shift during the movement",
                    "Not squeezing at the top for the full 2 seconds"
                ],
                breathingTips: [
                    "Exhale as you crunch up with the weight",
                    "Inhale on the controlled descent",
                    "Brace your core before each rep for spine protection"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Rectus Abdominis", isPrimary: true),
                    MuscleHighlight(name: "Transverse Abdominis", isPrimary: false)
                ]
            )
        case "ab_rollout":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Letting your lower back arch as you extend",
                    "Going too far out and losing core tension",
                    "Using your arms to pull back instead of your abs"
                ],
                breathingTips: [
                    "Inhale as you roll out, keeping your core tight",
                    "Exhale forcefully as you pull the wheel back to start",
                    "The exhale on the return helps maximally engage your abs"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Rectus Abdominis", isPrimary: true),
                    MuscleHighlight(name: "Transverse Abdominis", isPrimary: true),
                    MuscleHighlight(name: "Lats", isPrimary: false),
                    MuscleHighlight(name: "Shoulders", isPrimary: false)
                ]
            )
        case "v_ups":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Using momentum to swing up instead of controlled contraction",
                    "Bending your knees during the movement",
                    "Not reaching full extension at the top"
                ],
                breathingTips: [
                    "Exhale explosively as you lift into the V position",
                    "Inhale as you lower back down with control",
                    "Time your breath with the movement for maximum power"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Rectus Abdominis", isPrimary: true),
                    MuscleHighlight(name: "Hip Flexors", isPrimary: false),
                    MuscleHighlight(name: "Transverse Abdominis", isPrimary: false)
                ]
            )
        case "pulse_crunches":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Pulsing too large — keep the range of motion small",
                    "Relaxing between pulses and losing tension",
                    "Pulling on your neck with your hands"
                ],
                breathingTips: [
                    "Use quick exhales with each pulse upward",
                    "Don't hold your breath — keep a rapid breathing rhythm",
                    "Short sharp exhales help maintain constant ab tension"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Rectus Abdominis", isPrimary: true)
                ]
            )
        case "hanging_leg_raises":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Swinging your body to generate momentum",
                    "Only lifting your legs halfway instead of to parallel",
                    "Dropping your legs down instead of lowering with control"
                ],
                breathingTips: [
                    "Exhale as you raise your legs, curling your pelvis",
                    "Inhale as you lower your legs with slow control",
                    "Engage your core before each rep with a deep breath"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Rectus Abdominis", isPrimary: true),
                    MuscleHighlight(name: "Hip Flexors", isPrimary: false)
                ]
            )
        case "reverse_crunches":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Using momentum to swing your knees up",
                    "Not curling your hips off the floor enough",
                    "Letting your legs drop back too quickly"
                ],
                breathingTips: [
                    "Exhale as you curl your hips up toward your chest",
                    "Inhale as you lower your hips back to the floor",
                    "Focus the exhale on squeezing your lower abs"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Rectus Abdominis", isPrimary: true),
                    MuscleHighlight(name: "Transverse Abdominis", isPrimary: false)
                ]
            )
        case "flutter_kicks":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Arching your lower back off the floor",
                    "Kicking too high — keep the range small and controlled",
                    "Letting your feet touch the ground between kicks"
                ],
                breathingTips: [
                    "Breathe steadily throughout — don't hold your breath",
                    "Use short, rhythmic breaths matching your kick tempo",
                    "Exhale to maintain core compression during the set"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Rectus Abdominis", isPrimary: true),
                    MuscleHighlight(name: "Hip Flexors", isPrimary: false)
                ]
            )
        case "scissor_kicks":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Lifting your lower back off the floor",
                    "Crossing your legs too high — keep them low",
                    "Moving too fast and losing core engagement"
                ],
                breathingTips: [
                    "Maintain steady breathing throughout the set",
                    "Short exhales help keep your core compressed",
                    "Don't hold your breath — keep oxygen flowing"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Rectus Abdominis", isPrimary: true),
                    MuscleHighlight(name: "Hip Flexors", isPrimary: false),
                    MuscleHighlight(name: "Adductors", isPrimary: false)
                ]
            )
        case "leg_raises":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Arching your lower back as you lower your legs",
                    "Using momentum to swing your legs up",
                    "Lowering your legs too fast on the descent"
                ],
                breathingTips: [
                    "Exhale as you raise your legs to vertical",
                    "Inhale slowly as you lower them back down",
                    "The slow inhale on descent keeps your core braced"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Rectus Abdominis", isPrimary: true),
                    MuscleHighlight(name: "Hip Flexors", isPrimary: false)
                ]
            )
        case "l_sit_hold":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Bending your knees instead of keeping legs straight",
                    "Letting your shoulders shrug up toward your ears",
                    "Not pressing hard enough through your palms"
                ],
                breathingTips: [
                    "Breathe shallowly while holding the position",
                    "Exhale to tighten your core during the hold",
                    "Don't let breathing break your form"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Rectus Abdominis", isPrimary: true),
                    MuscleHighlight(name: "Hip Flexors", isPrimary: true),
                    MuscleHighlight(name: "Triceps", isPrimary: false),
                    MuscleHighlight(name: "Shoulders", isPrimary: false)
                ]
            )
        case "mountain_climbers":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Bouncing your hips up and down during the movement",
                    "Not bringing your knees far enough toward your chest",
                    "Letting your form break down as you fatigue"
                ],
                breathingTips: [
                    "Breathe rhythmically — exhale every two knee drives",
                    "Don't hold your breath even as the pace increases",
                    "Steady breathing helps maintain endurance"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Rectus Abdominis", isPrimary: true),
                    MuscleHighlight(name: "Hip Flexors", isPrimary: false),
                    MuscleHighlight(name: "Shoulders", isPrimary: false),
                    MuscleHighlight(name: "Quads", isPrimary: false)
                ]
            )
        case "toe_raise_lying":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Using momentum to swing your legs up",
                    "Not pausing at the top of the movement",
                    "Letting your lower back lift off the floor"
                ],
                breathingTips: [
                    "Exhale as you raise your legs toward the ceiling",
                    "Inhale as you lower them back with control",
                    "Press your lower back into the floor on each exhale"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Rectus Abdominis", isPrimary: true),
                    MuscleHighlight(name: "Hip Flexors", isPrimary: false)
                ]
            )
        case "bench_leg_raises":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Swinging your legs instead of controlled raises",
                    "Gripping the bench too hard and using your arms",
                    "Leaning too far back, reducing ab engagement"
                ],
                breathingTips: [
                    "Exhale as you raise your legs toward horizontal",
                    "Inhale as you lower with control",
                    "Brace your core with each breath cycle"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Rectus Abdominis", isPrimary: true),
                    MuscleHighlight(name: "Hip Flexors", isPrimary: false)
                ]
            )
        case "reverse_crunch_pulse":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Making the pulses too big — keep them small and tight",
                    "Using momentum from your legs instead of your abs",
                    "Relaxing between pulses and losing tension"
                ],
                breathingTips: [
                    "Short exhales with each pulse upward",
                    "Keep breathing rhythmic and rapid",
                    "Don't hold your breath during the pulsing set"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Rectus Abdominis", isPrimary: true),
                    MuscleHighlight(name: "Transverse Abdominis", isPrimary: false)
                ]
            )
        case "russian_twists":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Only moving your arms instead of rotating your torso",
                    "Rounding your back instead of keeping chest proud",
                    "Going too fast and losing the mind-muscle connection"
                ],
                breathingTips: [
                    "Exhale as you rotate to each side",
                    "Inhale as you pass through center",
                    "Controlled breathing helps maintain your lean-back angle"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Obliques", isPrimary: true),
                    MuscleHighlight(name: "Rectus Abdominis", isPrimary: false)
                ]
            )
        case "bicycle_crunch":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Pulling your neck with your hands on each rotation",
                    "Moving too fast — slow and controlled wins",
                    "Not fully extending the opposite leg on each rep"
                ],
                breathingTips: [
                    "Exhale as you bring your elbow to the opposite knee",
                    "Inhale as you switch sides through center",
                    "Match your breathing to the alternating rhythm"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Obliques", isPrimary: true),
                    MuscleHighlight(name: "Rectus Abdominis", isPrimary: true),
                    MuscleHighlight(name: "Hip Flexors", isPrimary: false)
                ]
            )
        case "side_plank_dips":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Dipping too low and losing tension in the obliques",
                    "Not driving your hip high enough at the top",
                    "Rotating your torso during the dip"
                ],
                breathingTips: [
                    "Inhale as you dip your hip down",
                    "Exhale as you drive your hip back up and squeeze",
                    "Steady breathing prevents you from holding your breath"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Obliques", isPrimary: true),
                    MuscleHighlight(name: "Transverse Abdominis", isPrimary: false)
                ]
            )
        case "oblique_crunch":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Using your arm to pull yourself up instead of your obliques",
                    "Not squeezing at the top of the crunch",
                    "Moving your hips instead of isolating your side abs"
                ],
                breathingTips: [
                    "Exhale as you crunch sideways, squeezing your obliques",
                    "Inhale as you lower back to the starting position",
                    "Focus the exhale on maximum side contraction"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Obliques", isPrimary: true)
                ]
            )
        case "heel_taps":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Dropping your shoulders back to the floor between taps",
                    "Bending at the waist instead of laterally flexing",
                    "Going too fast and losing the oblique contraction"
                ],
                breathingTips: [
                    "Exhale as you reach to tap each heel",
                    "Inhale as you return through center",
                    "Keep your shoulder blades lifted throughout with steady breathing"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Obliques", isPrimary: true)
                ]
            )

        case "cross_body_mountain_climbers":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Not crossing your knee far enough toward the opposite elbow",
                    "Letting your hips rise too high during the movement",
                    "Going too fast and losing the cross-body rotation"
                ],
                breathingTips: [
                    "Exhale as you drive each knee across your body",
                    "Inhale as you return the leg to start",
                    "Rhythmic breathing helps maintain pace and form"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Obliques", isPrimary: true),
                    MuscleHighlight(name: "Hip Flexors", isPrimary: false),
                    MuscleHighlight(name: "Shoulders", isPrimary: false)
                ]
            )
        case "windshield_wipers":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Letting your legs drop too low to the sides",
                    "Bending your knees to make it easier",
                    "Not using your arms for enough stability"
                ],
                breathingTips: [
                    "Exhale as you lower your legs to each side",
                    "Inhale as you bring them back to center",
                    "Controlled breathing helps maintain the slow tempo"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Obliques", isPrimary: true),
                    MuscleHighlight(name: "Rectus Abdominis", isPrimary: false),
                    MuscleHighlight(name: "Hip Flexors", isPrimary: false)
                ]
            )
        case "twisting_sit_ups":
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Twisting too early before sitting up fully",
                    "Using momentum to throw yourself into the twist",
                    "Not alternating sides evenly"
                ],
                breathingTips: [
                    "Exhale as you sit up and twist to the side",
                    "Inhale as you lower back down with control",
                    "The exhale during the twist maximizes oblique engagement"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Obliques", isPrimary: true),
                    MuscleHighlight(name: "Rectus Abdominis", isPrimary: true),
                    MuscleHighlight(name: "Hip Flexors", isPrimary: false)
                ]
            )
        default:
            return ExerciseDetailInfo(
                commonMistakes: [
                    "Using momentum instead of controlled movements",
                    "Not engaging your core throughout the exercise",
                    "Holding your breath during the movement"
                ],
                breathingTips: [
                    "Exhale during the exertion phase of the movement",
                    "Inhale during the return or relaxation phase",
                    "Keep breathing steady and controlled throughout"
                ],
                focusMuscles: [
                    MuscleHighlight(name: "Core", isPrimary: true)
                ]
            )
        }
    }
}
