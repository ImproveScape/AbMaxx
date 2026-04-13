import Foundation

nonisolated enum AbRegion: String, Codable, CaseIterable, Sendable, Identifiable {
    var id: String { rawValue }
    case deepCore = "Deep Core"
    case upperAbs = "Upper Abs"
    case lowerAbs = "Lower Abs"
    case obliques = "Obliques"

    var icon: String {
        switch self {
        case .deepCore: "circle.grid.cross.fill"
        case .upperAbs: "chevron.up.2"
        case .lowerAbs: "chevron.down.2"
        case .obliques: "arrow.left.and.right"
        }
    }

    var color: String {
        switch self {
        case .deepCore: "purple"
        case .upperAbs: "blue"
        case .lowerAbs: "green"
        case .obliques: "orange"
        }
    }
}

nonisolated enum ExerciseDifficulty: String, Codable, Sendable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var color: String {
        switch self {
        case .beginner: "green"
        case .intermediate: "yellow"
        case .advanced: "red"
        }
    }
}

nonisolated enum ExerciseEquipment: String, Codable, Sendable {
    case none = "None"
    case minimal = "Minimal"
    case gym = "Gym"
}

nonisolated struct Exercise: Identifiable, Codable, Sendable {
    let id: String
    let name: String
    let region: AbRegion
    let reps: String
    let xp: Int
    let instructions: String
    let steps: [String]
    let benefits: [String]
    let difficulty: ExerciseDifficulty
    let musclesWorked: [String]
    let demoImageURL: String

    static let allExercises: [Exercise] = [
        // MARK: - Deep Core
        Exercise(id: "plank", name: "Plank", region: .deepCore, reps: "45 sec × 3 sets", xp: 25,
                 instructions: "The classic core builder. A properly executed plank with max tension builds the deep stability that gives abs their sharp, defined look.",
                 steps: ["Place forearms on the ground, elbows directly under shoulders", "Extend legs back, toes on the floor, body in a straight line", "Squeeze your glutes and brace your core like you're about to get punched", "Keep your hips level — don't let them sag or pike up", "Breathe steadily and maintain maximum tension"],
                 benefits: ["Builds endurance in the deep stabilizer muscles", "Creates the core foundation needed for all advanced ab work", "Improves posture which makes your abs more visible"],
                 difficulty: .beginner, musclesWorked: ["Transverse Abdominis", "Rectus Abdominis", "Obliques", "Shoulders"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/75604391-838f-433a-b884-a26834f6a173.png"),
        Exercise(id: "dead_bug", name: "Dead Bug", region: .deepCore, reps: "15 reps × 3 sets", xp: 25,
                 instructions: "A foundational anti-extension exercise that teaches your core to stabilize while your limbs move independently.",
                 steps: ["Lie flat on your back with arms extended toward the ceiling", "Lift your knees to 90 degrees so shins are parallel to the floor", "Slowly extend your right arm overhead while straightening your left leg", "Keep your lower back pressed firmly into the floor throughout", "Return to start and repeat on the opposite side"],
                 benefits: ["Builds deep core stability without spinal flexion", "Teaches anti-extension — crucial for visible abs", "Fixes left-right imbalances in your core"],
                 difficulty: .beginner, musclesWorked: ["Transverse Abdominis", "Rectus Abdominis", "Hip Flexors"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/614ad320-0a5c-469a-ab0b-b6302e39cd96.png"),
        Exercise(id: "bird_dog", name: "Bird Dog", region: .deepCore, reps: "15 reps × 3 sets", xp: 25,
                 instructions: "A deceptively challenging stability exercise that builds the mind-muscle connection for deep core engagement.",
                 steps: ["Start on all fours, hands under shoulders, knees under hips", "Simultaneously extend your right arm forward and left leg back", "Keep your hips level and core braced — no rotation", "Pause at full extension for 2 seconds", "Return to start and repeat on the opposite side"],
                 benefits: ["Develops core stability and balance simultaneously", "Strengthens the lower back to support heavier ab training", "Improves the neural connection to your deep core muscles"],
                 difficulty: .beginner, musclesWorked: ["Transverse Abdominis", "Erector Spinae", "Glutes"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/d68e6ee4-4c09-471f-90c5-14a0f912dab2.png"),
        Exercise(id: "hollow_hold", name: "Hollow Body Hold", region: .deepCore, reps: "45 sec × 3 sets", xp: 30,
                 instructions: "The gymnast's secret weapon for abs. This isometric hold creates extreme tension across your entire core.",
                 steps: ["Lie on your back and press your lower back into the floor", "Lift your shoulders off the ground, tucking your chin slightly", "Extend your arms overhead by your ears", "Raise your legs 6 inches off the floor, keeping them straight", "Hold this banana-shaped position — squeeze everything tight"],
                 benefits: ["Develops the 'always on' core tension that makes abs pop", "Directly strengthens the rectus abdominis in a lengthened position", "Transfers to better performance in every other ab exercise"],
                 difficulty: .intermediate, musclesWorked: ["Rectus Abdominis", "Transverse Abdominis", "Hip Flexors"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/526d41ad-54b1-4097-9e26-d32f6bca4127.png"),
        Exercise(id: "stomach_vacuum", name: "Stomach Vacuum", region: .deepCore, reps: "30 sec × 5 sets", xp: 25,
                 instructions: "An old-school bodybuilding technique that targets the transverse abdominis — the deep muscle that pulls your waist in tight.",
                 steps: ["Stand upright or kneel on all fours", "Exhale all the air from your lungs completely", "Pull your belly button in toward your spine as hard as you can", "Hold the contraction while breathing shallowly through your chest", "Release and repeat after a full breath"],
                 benefits: ["Directly targets the transverse abdominis for a tighter waist", "Improves mind-muscle connection to deep core", "Can be done anywhere with no equipment"],
                 difficulty: .beginner, musclesWorked: ["Transverse Abdominis"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/4536035f-c9ba-4f69-8712-c0cec0ef88f6.png"),
        Exercise(id: "side_plank", name: "Side Plank", region: .deepCore, reps: "45 sec each side × 3 sets", xp: 30,
                 instructions: "An isometric hold that builds deep lateral core strength and stability while also hitting the obliques.",
                 steps: ["Lie on your side with your forearm on the ground, elbow under shoulder", "Stack your feet on top of each other", "Lift your hips off the ground until your body forms a straight line", "Squeeze your obliques and glutes — don't let your hips drop", "Hold for the prescribed time, then switch sides"],
                 benefits: ["Builds isometric oblique and deep core strength", "Develops lateral stability that sharpens your waistline", "Low impact but highly effective"],
                 difficulty: .intermediate, musclesWorked: ["Transverse Abdominis", "Obliques", "Glutes"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/6d3f25d5-16c7-43e0-b136-fc066204f087.png"),
        Exercise(id: "slow_mountain_climbers", name: "Slow Mountain Climbers", region: .deepCore, reps: "40 sec × 3 sets", xp: 30,
                 instructions: "A controlled version of mountain climbers that maximizes deep core engagement by eliminating momentum.",
                 steps: ["Start in a high plank position, hands under shoulders", "Slowly drive your right knee toward your chest", "Pause briefly, squeezing your core", "Slowly return and repeat on the left side", "Maintain a slow, controlled rhythm throughout"],
                 benefits: ["Maximizes time under tension for the deep core", "Builds anti-extension strength", "Improves hip flexor mobility and core coordination"],
                 difficulty: .intermediate, musclesWorked: ["Transverse Abdominis", "Hip Flexors", "Shoulders"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/c0b04d68-0553-4a13-b227-94c405bebb63.png"),

        // MARK: - Upper Abs
        Exercise(id: "crunches", name: "Crunches", region: .upperAbs, reps: "25 reps × 3 sets", xp: 25,
                 instructions: "The classic upper ab builder. When done with intention and full contraction, crunches directly target the upper blocks of your six-pack.",
                 steps: ["Lie on your back with knees bent, feet flat on the floor", "Place your fingertips behind your ears — don't pull your neck", "Curl your upper body up by contracting your abs", "Lift your shoulder blades completely off the ground", "Squeeze hard at the top for 1 second, then lower slowly"],
                 benefits: ["Directly isolates the upper rectus abdominis", "Builds the top blocks of the six-pack", "Easy to progressively overload with tempo and holds"],
                 difficulty: .beginner, musclesWorked: ["Upper Rectus Abdominis"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/2b5d970f-db90-4bfd-bff4-35ffd05eb89a.png"),
        Exercise(id: "sit_ups", name: "Sit Ups", region: .upperAbs, reps: "20 reps × 3 sets", xp: 25,
                 instructions: "A full-range upper ab movement that engages the entire rectus abdominis through a complete sit-up motion.",
                 steps: ["Lie on your back with knees bent, feet anchored or flat", "Cross your arms over your chest or place hands behind ears", "Curl your torso all the way up until your chest meets your thighs", "Lower back down with control — don't just drop", "Keep your core engaged throughout the entire movement"],
                 benefits: ["Full range of motion for upper ab development", "Builds functional core strength", "Engages hip flexors for compound movement"],
                 difficulty: .beginner, musclesWorked: ["Rectus Abdominis", "Hip Flexors"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/71e311cc-437e-43b9-9c09-0e5fb4523057.png"),
        Exercise(id: "toe_touch_control", name: "Toe Touch Control", region: .upperAbs, reps: "15 reps × 3 sets", xp: 25,
                 instructions: "A peak contraction exercise that forces your upper abs to work through their full range with controlled tempo.",
                 steps: ["Lie on your back with legs extended straight up toward the ceiling", "Reach both hands up toward your toes", "Lift your shoulder blades off the ground using only your abs", "Touch or reach past your toes at the top with a slow, controlled motion", "Lower back down with control — don't just drop"],
                 benefits: ["Maximizes peak contraction of the upper abs", "The vertical leg position increases time under tension", "Builds the mind-muscle connection for better ab control"],
                 difficulty: .beginner, musclesWorked: ["Upper Rectus Abdominis", "Hip Flexors"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/7ae6bdfe-120e-471e-9a5a-7565af730f62.png"),
        Exercise(id: "cable_crunch", name: "Cable Crunch", region: .upperAbs, reps: "15 reps × 3 sets", xp: 30,
                 instructions: "A weighted crunch variation using a cable machine for constant tension throughout the movement.",
                 steps: ["Kneel in front of a cable machine with a rope attachment at the top", "Hold the rope behind your head with both hands", "Crunch down by flexing your spine, bringing elbows toward your knees", "Squeeze your abs hard at the bottom of the movement", "Slowly return to the starting position with control"],
                 benefits: ["Constant cable tension for superior ab activation", "Easily progressive — just increase the weight", "Builds thick, visible upper ab blocks"],
                 difficulty: .intermediate, musclesWorked: ["Upper Rectus Abdominis", "Transverse Abdominis"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/0f65535d-c8b9-47d2-b237-b43b4288b5d4.png"),
        Exercise(id: "decline_crunch", name: "Decline Crunch", region: .upperAbs, reps: "15 reps × 3 sets", xp: 30,
                 instructions: "Gravity-enhanced crunches on a decline bench for increased upper ab activation.",
                 steps: ["Secure your legs at the top of a decline bench", "Cross arms over your chest or place hands behind ears", "Curl your upper body up against gravity", "Squeeze at the top and hold briefly", "Lower back with slow control"],
                 benefits: ["Increased resistance from the decline angle", "Greater range of motion than flat crunches", "Builds upper ab thickness effectively"],
                 difficulty: .intermediate, musclesWorked: ["Upper Rectus Abdominis"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/8f3b0a3c-dd84-401b-be72-2b1f43fa0e64.png"),
        Exercise(id: "crunch_hold", name: "Crunch Hold", region: .upperAbs, reps: "30 sec × 3 sets", xp: 25,
                 instructions: "An isometric crunch variation that builds endurance and peak contraction strength in the upper abs.",
                 steps: ["Lie on your back with knees bent, feet flat", "Perform a crunch and lift shoulder blades off the ground", "Hold at the top position with abs fully contracted", "Keep breathing while maintaining the squeeze", "Don't let your shoulders drop until the time is up"],
                 benefits: ["Builds isometric upper ab strength", "Increases time under tension dramatically", "Improves mind-muscle connection"],
                 difficulty: .beginner, musclesWorked: ["Upper Rectus Abdominis"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/fc0356e5-bdc9-49e0-927f-a0f7bb26be39.png"),
        Exercise(id: "weighted_crunch", name: "Weighted Crunch", region: .upperAbs, reps: "10 reps × 3 sets", xp: 35,
                 instructions: "Adding external resistance to crunches for maximum upper ab hypertrophy and thickness.",
                 steps: ["Lie on your back with knees bent, holding a weight plate on your chest", "Curl your upper body up by contracting your abs", "Keep the weight stable against your chest throughout", "Squeeze hard at the top for 2 seconds", "Lower slowly with control"],
                 benefits: ["Progressive overload for ab hypertrophy", "Builds thick, blocky upper abs", "Time-efficient — fewer reps, more results"],
                 difficulty: .advanced, musclesWorked: ["Upper Rectus Abdominis", "Transverse Abdominis"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/aa841478-f6a1-4796-9b49-463a97b890e5.png"),
        Exercise(id: "ab_rollout", name: "Ab Rollout", region: .upperAbs, reps: "15 reps × 3 sets", xp: 35,
                 instructions: "One of the most effective ab exercises ever studied. Creates extreme tension through the entire rectus abdominis.",
                 steps: ["Kneel on the floor holding an ab wheel with both hands", "Slowly roll the wheel forward, extending your body", "Go as far as you can while keeping your lower back from arching", "Squeeze your abs hard and pull yourself back to the start", "Keep your core engaged throughout — never let your hips sag"],
                 benefits: ["One of the highest ab activators per EMG studies", "Builds eccentric strength for thick, visible abs", "Strengthens the entire anterior chain"],
                 difficulty: .advanced, musclesWorked: ["Rectus Abdominis", "Transverse Abdominis", "Lats", "Shoulders"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/983ee87d-4669-4d96-a80a-a06ce2860925.png"),
        Exercise(id: "v_ups", name: "V-Ups", region: .upperAbs, reps: "15 reps × 3 sets", xp: 35,
                 instructions: "An advanced full-range ab exercise. The simultaneous lift of upper and lower body creates maximum tension.",
                 steps: ["Lie flat on your back with arms extended overhead", "Simultaneously lift your legs and upper body off the ground", "Reach your hands toward your toes at the top, forming a V shape", "Balance briefly on your tailbone at the peak", "Lower everything back down with control"],
                 benefits: ["Works the entire rectus abdominis through full range", "Builds explosive core strength and power", "One of the most efficient total ab exercises"],
                 difficulty: .advanced, musclesWorked: ["Rectus Abdominis", "Hip Flexors", "Transverse Abdominis"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/ada66eb8-23bf-4591-81df-2b9bac7d5195.png"),
        Exercise(id: "pulse_crunches", name: "Pulse Crunches", region: .upperAbs, reps: "30 reps × 3 sets", xp: 25,
                 instructions: "Rapid small-range crunches that keep constant tension on the upper abs for a massive burn.",
                 steps: ["Lie on your back with knees bent, hands behind ears", "Crunch up slightly so shoulder blades are off the ground", "Pulse up and down in a small range of motion — never fully relax", "Maintain constant tension and a quick rhythm", "Keep your core contracted the entire time"],
                 benefits: ["Constant tension for maximum upper ab burn", "High rep count builds muscular endurance", "Great finisher exercise for upper abs"],
                 difficulty: .beginner, musclesWorked: ["Upper Rectus Abdominis"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/cc280318-9bfc-4a6a-b192-970230bf06d1.png"),


        // MARK: - Lower Abs
        Exercise(id: "hanging_leg_raises", name: "Hanging Leg Raises", region: .lowerAbs, reps: "15 reps × 2 sets", xp: 35,
                 instructions: "The gold standard for lower ab development. Gravity works against you the entire time.",
                 steps: ["Hang from a pull-up bar with an overhand grip", "Keep your body still — no swinging", "Raise your legs by curling your pelvis upward", "Lift until your legs are parallel to the floor or higher", "Lower slowly with control — the negative is key"],
                 benefits: ["The single best exercise for lower ab development", "Gravity provides progressive resistance through full range", "Builds the lower V-line that frames your six-pack"],
                 difficulty: .advanced, musclesWorked: ["Lower Rectus Abdominis", "Hip Flexors", "Grip"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/7cbdd663-e76c-47bd-9241-41802c089ba7.png"),
        Exercise(id: "reverse_crunches", name: "Reverse Crunches", region: .lowerAbs, reps: "12 reps × 3 sets", xp: 30,
                 instructions: "By moving your hips instead of your shoulders, you shift all the work to your lower abs.",
                 steps: ["Lie on your back with knees bent at 90 degrees, feet off the floor", "Place your hands flat beside you for stability", "Curl your hips off the floor, bringing knees toward your chest", "Squeeze your lower abs hard at the top", "Slowly lower your hips back down — don't use momentum"],
                 benefits: ["Isolates the lower portion of the rectus abdominis", "Minimal hip flexor involvement compared to leg raises", "Builds the lower ab pop that completes the six-pack"],
                 difficulty: .beginner, musclesWorked: ["Lower Rectus Abdominis", "Transverse Abdominis"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/3bd00e21-4624-461e-af44-4346798adf42.png"),
        Exercise(id: "flutter_kicks", name: "Flutter Kicks", region: .lowerAbs, reps: "30 sec × 3 sets", xp: 25,
                 instructions: "A constant tension lower ab burner. The rapid alternating movement keeps your lower abs under continuous load.",
                 steps: ["Lie on your back with hands under your glutes for support", "Lift both legs a few inches off the ground", "Alternately kick your legs up and down in small, rapid movements", "Keep your core tight and lower back pressed into the floor", "Don't let your feet touch the ground until the set is done"],
                 benefits: ["Keeps the lower abs under constant tension", "Builds muscular endurance in the lower ab region", "The continuous movement increases calorie burn"],
                 difficulty: .beginner, musclesWorked: ["Lower Rectus Abdominis", "Hip Flexors"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/1cc10311-b48e-4fef-a21f-8a74fa70480c.png"),
        Exercise(id: "scissor_kicks", name: "Scissor Kicks", region: .lowerAbs, reps: "30 sec × 3 sets", xp: 25,
                 instructions: "A crossing variation of flutter kicks that adds an adductor component while hammering the lower abs.",
                 steps: ["Lie on your back with hands under your glutes", "Lift both legs a few inches off the ground", "Cross your legs over each other in a scissor motion", "Alternate which leg is on top with each rep", "Keep your lower back flat and core braced throughout"],
                 benefits: ["Constant lower ab tension with adductor engagement", "Builds coordination and lower core endurance", "Variations in leg path hit different lower ab fibers"],
                 difficulty: .beginner, musclesWorked: ["Lower Rectus Abdominis", "Hip Flexors", "Adductors"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/654006ad-51b2-46b6-a3d0-af4c44d34edb.png"),
        Exercise(id: "leg_raises", name: "Leg Raises", region: .lowerAbs, reps: "15 reps × 3 sets", xp: 25,
                 instructions: "A fundamental lower ab exercise. Control the descent — that's where your lower abs do the real work.",
                 steps: ["Lie flat on your back with legs straight and hands under your hips", "Keep your lower back pressed into the floor", "Raise both legs together until perpendicular to the floor", "Lower them back down slowly — stop just before feet touch the ground", "The slower you lower, the harder your lower abs work"],
                 benefits: ["Directly targets the hard-to-develop lower abs", "The eccentric phase builds thickness in the lower ab region", "Teaches pelvic control for better overall ab aesthetics"],
                 difficulty: .beginner, musclesWorked: ["Lower Rectus Abdominis", "Hip Flexors"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/b22b1777-9f2c-4543-9763-0c1fde897266.png"),
        Exercise(id: "l_sit_hold", name: "L-Sit Hold", region: .lowerAbs, reps: "30 sec × 3 sets", xp: 35,
                 instructions: "An advanced isometric hold that requires tremendous lower ab and hip flexor strength.",
                 steps: ["Sit on the floor with legs extended, hands on the ground beside your hips", "Press down through your hands and lift your entire body off the ground", "Keep your legs straight and parallel to the floor", "Hold the position with core fully braced", "If too difficult, start with bent knees and progress to straight legs"],
                 benefits: ["Extreme lower ab and hip flexor engagement", "Builds isometric core strength at a high level", "Impressive skill that demonstrates true core power"],
                 difficulty: .advanced, musclesWorked: ["Lower Rectus Abdominis", "Hip Flexors", "Triceps", "Shoulders"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/35d43349-6449-4427-b695-f57e86f6bfdc.png"),
        Exercise(id: "mountain_climbers", name: "Mountain Climbers", region: .lowerAbs, reps: "60 sec × 3 sets", xp: 30,
                 instructions: "A dynamic core-torcher that doubles as cardio. Burns fat while building lower ab strength.",
                 steps: ["Start in a high plank position, hands under shoulders", "Drive your right knee toward your chest explosively", "As you return it, immediately drive your left knee forward", "Keep your hips low and core braced the entire time", "Maintain a quick, controlled rhythm"],
                 benefits: ["Burns calories while building core strength", "Increases heart rate to accelerate fat loss", "Builds explosive lower core power"],
                 difficulty: .intermediate, musclesWorked: ["Lower Rectus Abdominis", "Hip Flexors", "Shoulders", "Quads"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/04a383d9-a5db-4287-8c5c-9a026651a306.png"),
        Exercise(id: "toe_raise_lying", name: "Toe Raise (Lying)", region: .lowerAbs, reps: "20 reps × 3 sets", xp: 25,
                 instructions: "A focused lower ab movement where you raise your legs to point toes toward the ceiling from a lying position.",
                 steps: ["Lie flat on your back with legs straight, arms at your sides", "Keep your lower back pressed into the floor", "Raise your legs straight up until toes point at the ceiling", "Pause briefly at the top, squeezing your lower abs", "Lower slowly with control back to starting position"],
                 benefits: ["Isolates the lower abs effectively", "Simple movement with high activation", "Great for building lower ab mind-muscle connection"],
                 difficulty: .beginner, musclesWorked: ["Lower Rectus Abdominis", "Hip Flexors"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/30f602c9-aba0-41d3-aa86-d249b2497127.png"),
        Exercise(id: "bench_leg_raises", name: "Bench Leg Raises", region: .lowerAbs, reps: "15 reps × 3 sets", xp: 30,
                 instructions: "Leg raises performed on a bench for increased range of motion and lower ab activation.",
                 steps: ["Sit on the edge of a bench, grip the sides for support", "Lean back slightly and extend your legs out in front", "Raise your legs up by contracting your lower abs", "Bring knees toward your chest or legs to horizontal", "Lower with control — don't swing"],
                 benefits: ["Greater range of motion than floor leg raises", "Bench support allows focus on pure ab contraction", "Builds lower ab definition and strength"],
                 difficulty: .intermediate, musclesWorked: ["Lower Rectus Abdominis", "Hip Flexors"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/9e79f321-8056-4a13-a09f-ac1012c5b419.png"),
        Exercise(id: "reverse_crunch_pulse", name: "Reverse Crunch Pulse", region: .lowerAbs, reps: "15 reps × 3 sets", xp: 30,
                 instructions: "A pulsing variation of reverse crunches that keeps constant tension on the lower abs.",
                 steps: ["Lie on your back with knees bent at 90 degrees, feet off floor", "Curl your hips up, bringing knees toward chest", "At the top, pulse your hips up in small, controlled movements", "Each pulse is one rep — maintain constant tension", "Lower back down after completing all pulses"],
                 benefits: ["Constant tension for maximum lower ab burn", "Pulsing recruits more muscle fibers", "Builds lower ab endurance and definition"],
                 difficulty: .intermediate, musclesWorked: ["Lower Rectus Abdominis", "Transverse Abdominis"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/52a488ea-7e1a-47f7-8368-ee40cf376b61.png"),



        // MARK: - Obliques
        Exercise(id: "russian_twists", name: "Russian Twists", region: .obliques, reps: "30 reps × 3 sets", xp: 30,
                 instructions: "The go-to rotational exercise for oblique development. The twisting motion carves out the lines that frame your six-pack.",
                 steps: ["Sit on the floor with knees bent, lean back to about 45 degrees", "Lift your feet slightly off the ground for added difficulty", "Clasp your hands together or hold a weight at your chest", "Rotate your torso to touch the ground on your right side", "Rotate to the left side — that's one rep each side"],
                 benefits: ["Directly targets the obliques for that V-cut look", "Rotational strength improves athletic performance", "Builds the intercostal lines between your abs"],
                 difficulty: .intermediate, musclesWorked: ["External Obliques", "Internal Obliques", "Rectus Abdominis"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/0c5b0a99-6b7f-46b5-a6d1-6826f2d9a781.png"),
        Exercise(id: "bicycle_crunch", name: "Bicycle Crunch", region: .obliques, reps: "20 reps × 3 sets", xp: 30,
                 instructions: "Ranked by ACE as one of the best ab exercises. The rotation hits both the rectus abdominis and obliques simultaneously.",
                 steps: ["Lie on your back with hands behind your head", "Lift both feet off the ground, knees at 90 degrees", "Bring your right elbow toward your left knee while extending your right leg", "Immediately switch — left elbow to right knee", "Move with control, not speed — feel each contraction"],
                 benefits: ["Activates more muscle fibers than standard crunches", "Hits both upper abs and obliques in one movement", "The rotation builds intercostal definition"],
                 difficulty: .intermediate, musclesWorked: ["Rectus Abdominis", "Obliques", "Hip Flexors"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/8640d530-ac1c-47c8-beee-1ba1212bbaff.png"),
        Exercise(id: "side_plank_dips", name: "Side Plank Dips", region: .obliques, reps: "12 each side × 3 sets", xp: 30,
                 instructions: "Adds dynamic movement to the side plank. The dipping motion creates a stretch-and-contract cycle for oblique thickness.",
                 steps: ["Get into a side plank on your forearm, feet stacked", "Your body should form a straight line from head to feet", "Lower your hip toward the ground in a controlled dip", "Drive your hip back up past the starting position — squeeze at the top", "Complete all reps on one side before switching"],
                 benefits: ["Builds oblique thickness through full range of motion", "The dip adds eccentric loading standard side planks miss", "Develops lateral core strength for a sharper V-taper"],
                 difficulty: .intermediate, musclesWorked: ["External Obliques", "Internal Obliques", "Quadratus Lumborum"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/345ba7e0-475e-449a-a6e3-116de0e817c4.png"),
        Exercise(id: "oblique_crunch", name: "Oblique Crunch", region: .obliques, reps: "15 each side × 3 sets", xp: 25,
                 instructions: "A targeted isolation exercise for the obliques. The lateral crunch directly hits the side abs.",
                 steps: ["Lie on your side with knees slightly bent", "Place your bottom arm on the floor for stability", "Place your top hand behind your head", "Crunch your upper body sideways, lifting shoulder toward hip", "Squeeze your obliques hard at the top, then lower slowly"],
                 benefits: ["Directly isolates the obliques", "Builds the side definition that frames your six-pack", "No equipment needed"],
                 difficulty: .beginner, musclesWorked: ["External Obliques", "Internal Obliques"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/72a2fd57-4da2-4002-ac11-6e6b6afe313a.png"),
        Exercise(id: "heel_taps", name: "Heel Taps", region: .obliques, reps: "30 reps × 3 sets", xp: 25,
                 instructions: "A simple but effective oblique exercise. The side-to-side reaching motion targets the obliques with constant tension.",
                 steps: ["Lie on your back with knees bent, feet flat on the floor", "Lift your shoulder blades slightly off the ground", "Reach your right hand down to tap your right heel", "Return to center and reach left hand to left heel", "Keep your core engaged and shoulders off the ground throughout"],
                 benefits: ["Constant oblique engagement throughout the set", "Beginner-friendly with high activation", "Great for building oblique endurance"],
                 difficulty: .beginner, musclesWorked: ["External Obliques", "Internal Obliques"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/a6c608e8-53bc-4f29-96f5-caad672cc1be.png"),
        Exercise(id: "cross_body_mountain_climbers", name: "Cross Body Mountain Climbers", region: .obliques, reps: "30 sec × 3 sets", xp: 30,
                 instructions: "Mountain climbers with a cross-body twist that targets the obliques while burning calories.",
                 steps: ["Start in a high plank position, hands under shoulders", "Drive your right knee toward your left elbow", "Return and drive your left knee toward your right elbow", "Keep your hips low and core braced", "Maintain a controlled, rhythmic pace"],
                 benefits: ["Combines cardio with oblique-targeted training", "The cross-body motion maximizes oblique recruitment", "Burns fat while building rotational core strength"],
                 difficulty: .intermediate, musclesWorked: ["External Obliques", "Internal Obliques", "Hip Flexors", "Shoulders"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/b8fa9bbc-9a5b-4f2c-91ac-03be49365e60.png"),
        Exercise(id: "windshield_wipers", name: "Windshield Wipers", region: .obliques, reps: "15 reps × 3 sets", xp: 35,
                 instructions: "An advanced oblique exercise that requires significant core control to rotate your legs side to side.",
                 steps: ["Lie on your back with arms extended to the sides for stability", "Raise your legs straight up, perpendicular to the floor", "Slowly lower both legs to one side, keeping them together", "Stop before your feet touch the ground", "Bring legs back to center and lower to the other side"],
                 benefits: ["Extreme oblique activation through full range", "Builds rotational control and anti-rotation strength", "One of the most challenging oblique exercises"],
                 difficulty: .advanced, musclesWorked: ["External Obliques", "Internal Obliques", "Rectus Abdominis", "Hip Flexors"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/d3bdf5c5-c095-4ff3-abb1-f433651e0887.png"),
        Exercise(id: "twisting_sit_ups", name: "Twisting Sit Ups", region: .obliques, reps: "12 reps × 3 sets", xp: 30,
                 instructions: "A sit-up variation with a twist at the top that combines upper ab and oblique training in one movement.",
                 steps: ["Lie on your back with knees bent, feet flat or anchored", "Place hands behind your head", "Sit up and rotate, bringing your right elbow toward your left knee", "Lower back down with control", "Alternate sides each rep"],
                 benefits: ["Combines upper ab and oblique work efficiently", "Full range of motion with rotational component", "Builds functional rotational strength"],
                 difficulty: .intermediate, musclesWorked: ["Rectus Abdominis", "External Obliques", "Internal Obliques", "Hip Flexors"],
                 demoImageURL: "https://r2-pub.rork.com/generated-images/043720a8-811c-46d1-ab93-d3ebfd2849f3.png"),

    ]

    var equipment: ExerciseEquipment {
        switch id {
        case "cable_crunch", "decline_crunch", "bench_leg_raises":
            return .gym
        case "hanging_leg_raises", "ab_rollout", "weighted_crunch", "l_sit_hold":
            return .minimal
        default:
            return .none
        }
    }

    var equipmentLabel: String {
        switch equipment {
        case .none: return "No Equipment"
        case .minimal: return "Pull-up Bar / Ab Wheel"
        case .gym: return "Gym Required"
        }
    }

    static func exercises(for region: AbRegion) -> [Exercise] {
        allExercises.filter { $0.region == region }
    }

    static func exercises(for region: AbRegion, equipment setting: EquipmentSetting) -> [Exercise] {
        allExercises.filter { $0.region == region && $0.isAvailable(for: setting) }
    }

    func isAvailable(for setting: EquipmentSetting) -> Bool {
        switch setting {
        case .home:
            return equipment == .none
        case .gym, .both:
            return true
        }
    }
}
