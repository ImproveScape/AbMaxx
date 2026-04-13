import SwiftUI
import AVKit

struct ExerciseFormGuideView: View {
    let exercise: Exercise
    var showFullGuide: Bool = true
    var regionScore: Int = 0

    @State private var currentStepIndex: Int = 0
    @State private var isAnimating: Bool = false
    @State private var stepProgress: Double = 0

    private var regionColor: Color {
        AppTheme.subscoreColor(for: regionScore)
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color(AppTheme.cardSurfaceElevated)

                AsyncImage(url: URL(string: exercise.demoImageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .allowsHitTesting(false)
                    case .failure:
                        exercisePlaceholder
                    case .empty:
                        ProgressView().tint(regionColor)
                    @unknown default:
                        exercisePlaceholder
                    }
                }

                if showFullGuide {
                    VStack {
                        Spacer()

                        HStack(spacing: 4) {
                            ForEach(0..<exercise.steps.count, id: \.self) { i in
                                Capsule()
                                    .fill(i <= currentStepIndex ? regionColor : Color.white.opacity(0.3))
                                    .frame(height: 3)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                    }
                }
            }
            .clipShape(.rect(cornerRadius: 16))

            if showFullGuide && !exercise.steps.isEmpty {
                formStepCard
                    .padding(.top, 12)
            }
        }
        .onAppear {
            if showFullGuide {
                startStepAnimation()
            }
        }
    }

    private var formStepCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "figure.core.training")
                        .font(.system(size: 10, weight: .bold))
                    Text("FORM GUIDE")
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(1)
                }
                .foregroundStyle(regionColor)

                Spacer()

                Text("Step \(currentStepIndex + 1)/\(exercise.steps.count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
            }

            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(regionColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Text("\(currentStepIndex + 1)")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(regionColor)
                }

                Text(exercise.steps[currentStepIndex])
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineSpacing(3)
                    .id(currentStepIndex)
                    .transition(.push(from: .trailing))
                    .animation(.easeInOut(duration: 0.3), value: currentStepIndex)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 3)
                    Capsule()
                        .fill(regionColor)
                        .frame(width: geo.size.width * stepProgress, height: 3)
                        .animation(.linear(duration: 3.0), value: stepProgress)
                }
            }
            .frame(height: 3)
        }
        .padding(14)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(regionColor.opacity(0.15), lineWidth: 1)
        )
    }

    private var exercisePlaceholder: some View {
        VStack(spacing: 10) {
            Image(systemName: exercise.region.icon)
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(regionColor.opacity(0.3))
            Text(exercise.name)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    private func startStepAnimation() {
        guard !exercise.steps.isEmpty else { return }
        isAnimating = true
        Task {
            while isAnimating {
                stepProgress = 0
                withAnimation(.linear(duration: 3.0)) {
                    stepProgress = 1.0
                }
                try? await Task.sleep(for: .seconds(3))
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStepIndex = (currentStepIndex + 1) % exercise.steps.count
                    stepProgress = 0
                }
            }
        }
    }
}
