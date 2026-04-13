import SwiftUI

struct ExerciseCompletionOverlay: View {
    let exerciseName: String
    let repsCompleted: Int
    let targetReps: Int
    let onContinue: () -> Void

    @State private var showCheck: Bool = false
    @State private var showText: Bool = false
    @State private var showButton: Bool = false
    @State private var ringScale: CGFloat = 0.3
    @State private var confettiPhase: Int = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            confettiLayer

            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(AppTheme.success.opacity(0.1))
                        .frame(width: 180, height: 180)
                        .scaleEffect(ringScale)

                    Circle()
                        .fill(AppTheme.success.opacity(0.05))
                        .frame(width: 240, height: 240)
                        .scaleEffect(ringScale * 0.9)

                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [AppTheme.success, AppTheme.primaryAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 6
                        )
                        .frame(width: 130, height: 130)
                        .scaleEffect(showCheck ? 1 : 0.5)
                        .opacity(showCheck ? 1 : 0)

                    Image(systemName: "checkmark")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(AppTheme.success)
                        .scaleEffect(showCheck ? 1 : 0.3)
                        .opacity(showCheck ? 1 : 0)
                }

                if showText {
                    VStack(spacing: 12) {
                        Text("CRUSHED IT!")
                            .font(.system(size: 28, weight: .black))
                            .foregroundStyle(.white)
                            .tracking(3)

                        Text("\(repsCompleted) REPS COMPLETED")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppTheme.primaryAccent)
                            .tracking(1)

                        Text(exerciseName.uppercased())
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.muted)
                            .tracking(0.5)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()

                if showButton {
                    Button {
                        onContinue()
                    } label: {
                        HStack(spacing: 10) {
                            Text("Next Exercise")
                                .font(.system(size: 17, weight: .bold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(AppTheme.accentGradient)
                        .clipShape(.capsule)
                        .shadow(color: AppTheme.primaryAccent.opacity(0.4), radius: 20, y: 6)
                    }
                    .padding(.horizontal, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()
                    .frame(height: 50)
            }
        }
        .sensoryFeedback(.success, trigger: showCheck)
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.3)) {
                showCheck = true
                ringScale = 1.0
            }
            withAnimation(.spring(duration: 0.5, bounce: 0.2).delay(0.4)) {
                showText = true
            }
            withAnimation(.spring(duration: 0.4, bounce: 0.2).delay(0.8)) {
                showButton = true
            }
            confettiPhase = 1
        }
    }

    private var confettiLayer: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                guard confettiPhase > 0 else { return }

                for i in 0..<40 {
                    let seed = Double(i) * 137.508
                    let x = (sin(seed) * 0.5 + 0.5) * size.width
                    let startY = -20.0
                    let speed = 80 + sin(seed * 2) * 40
                    let y = startY + (time.truncatingRemainder(dividingBy: 4.0)) * speed
                    let rotation = Angle.degrees(time * (60 + seed.truncatingRemainder(dividingBy: 30)))

                    guard y < size.height + 20 else { continue }

                    let colors: [Color] = [AppTheme.primaryAccent, AppTheme.success, AppTheme.orange, .white, AppTheme.secondaryAccent]
                    let color = colors[i % colors.count]

                    let w: CGFloat = CGFloat(4 + sin(seed * 3) * 3)
                    let h: CGFloat = CGFloat(8 + cos(seed * 2) * 4)
                    let rect = CGRect(x: x - w/2, y: y - h/2, width: w, height: h)

                    context.opacity = max(0, 1 - y / size.height)
                    context.rotate(by: rotation)
                    context.fill(
                        RoundedRectangle(cornerRadius: 1).path(in: rect),
                        with: .color(color)
                    )
                    context.rotate(by: -rotation)
                }
            }
        }
        .allowsHitTesting(false)
    }
}
