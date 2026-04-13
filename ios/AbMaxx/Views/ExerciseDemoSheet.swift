import SwiftUI

struct ExerciseDemoSheet: View {
    let exercise: Exercise
    var regionScore: Int = 0
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep: Int = 0
    @State private var isPlaying: Bool = true
    @State private var stepProgress: Double = 0
    @State private var animationTask: Task<Void, Never>?
    @State private var showDetails: Bool = false

    private let stepDuration: Double = 4.0

    private var regionColor: Color {
        AppTheme.subscoreColor(for: regionScore)
    }

    private var detailInfo: ExerciseDetailInfo {
        ExerciseDetailData.info(for: exercise.id)
    }

    var body: some View {
        ZStack {
            BackgroundView().ignoresSafeArea()
            StandardBackgroundOrbs()

            ScrollView {
                VStack(spacing: 0) {
                    videoPlayerSection
                    contentSection
                    Color.clear.frame(height: 40)
                }
            }
            .scrollIndicators(.hidden)

            VStack {
                headerBar
                Spacer()
            }
        }
        .onAppear { startAutoPlay() }
        .onDisappear { animationTask?.cancel() }
    }

    private var headerBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }

            Spacer()

            Text("EXERCISE DEMO")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(2)

            Spacer()

            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var videoPlayerSection: some View {
        VStack(spacing: 0) {
            ZStack {
                Color(AppTheme.cardSurfaceElevated)
                    .frame(height: 340)
                    .overlay {
                        AsyncImage(url: URL(string: exercise.demoImageURL)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .allowsHitTesting(false)
                            case .failure:
                                imagePlaceholder
                            case .empty:
                                ProgressView().tint(regionColor)
                            @unknown default:
                                imagePlaceholder
                            }
                        }
                    }
                    .clipShape(.rect(cornerRadius: 0))

                VStack {
                    Spacer()

                    LinearGradient(
                        colors: [.clear, AppTheme.background.opacity(0.9), AppTheme.background],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()

                        HStack(spacing: 6) {
                            Image(systemName: exercise.region.icon)
                                .font(.system(size: 10, weight: .bold))
                            Text(exercise.region.rawValue.uppercased())
                                .font(.system(size: 10, weight: .black))
                                .tracking(1)
                        }
                        .foregroundStyle(regionColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(regionColor.opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(regionColor.opacity(0.2), lineWidth: 1))
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }

            VStack(spacing: 8) {
                Text(exercise.name.uppercased())
                    .font(.system(size: 30, weight: .black))
                    .foregroundStyle(.white)
                    .tracking(1)

                HStack(spacing: 12) {
                    infoPill(icon: "flame.fill", text: exercise.difficulty.rawValue)
                    infoPill(icon: "dumbbell.fill", text: exercise.equipmentLabel)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
    }

    private func infoPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(text)
                .font(.system(size: 14, weight: .bold))
        }
        .foregroundStyle(.white.opacity(0.5))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.06))
        .clipShape(Capsule())
    }

    private var contentSection: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text(exercise.instructions)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineSpacing(4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            stepByStepSection

            musclesSection

            if !detailInfo.commonMistakes.isEmpty {
                mistakesSection
            }

            if !detailInfo.breathingTips.isEmpty {
                breathingSection
            }

            benefitsSection
        }
    }

    private var stepByStepSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader(icon: "play.circle.fill", title: "HOW TO DO IT", color: regionColor)

                Spacer()

                Button {
                    isPlaying.toggle()
                    if isPlaying {
                        startAutoPlay()
                    } else {
                        animationTask?.cancel()
                    }
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(regionColor)
                        .frame(width: 30, height: 30)
                        .background(regionColor.opacity(0.12))
                        .clipShape(Circle())
                }
            }

            HStack(spacing: 3) {
                ForEach(0..<exercise.steps.count, id: \.self) { i in
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                            if i < currentStep {
                                Capsule().fill(regionColor)
                            } else if i == currentStep {
                                Capsule()
                                    .fill(regionColor)
                                    .frame(width: geo.size.width * stepProgress)
                            }
                        }
                    }
                    .frame(height: 3)
                }
            }
            .animation(.linear(duration: 0.3), value: currentStep)

            ForEach(Array(exercise.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(index <= currentStep ? regionColor : Color.white.opacity(0.08))
                            .frame(width: 32, height: 32)

                        if index < currentStep {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(.white)
                        } else {
                            Text("\(index + 1)")
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(index == currentStep ? .white : .white.opacity(0.3))
                        }
                    }

                    Text(step)
                        .font(.system(size: 17, weight: index == currentStep ? .semibold : .medium))
                        .foregroundStyle(index == currentStep ? .white : .white.opacity(0.45))
                        .lineSpacing(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 4)
                .animation(.spring(duration: 0.3), value: currentStep)
            }
        }
        .padding(16)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(regionColor.opacity(0.12), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    private var musclesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "figure.strengthtraining.traditional", title: "MUSCLES WORKED", color: AppTheme.primaryAccent)

            let primary = detailInfo.focusMuscles.filter(\.isPrimary)
            let secondary = detailInfo.focusMuscles.filter { !$0.isPrimary }

            if !primary.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Primary")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(AppTheme.primaryAccent)
                        .tracking(1)

                    FlowLayout(spacing: 6) {
                        ForEach(primary, id: \.name) { muscle in
                            musclePill(muscle.name, isPrimary: true)
                        }
                    }
                }
            }

            if !secondary.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Secondary")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.white.opacity(0.35))
                        .tracking(1)

                    FlowLayout(spacing: 6) {
                        ForEach(secondary, id: \.name) { muscle in
                            musclePill(muscle.name, isPrimary: false)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppTheme.border, lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    private func musclePill(_ name: String, isPrimary: Bool) -> some View {
        Text(name)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(isPrimary ? .white : .white.opacity(0.5))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isPrimary ? AppTheme.primaryAccent.opacity(0.15) : Color.white.opacity(0.06))
            .clipShape(Capsule())
            .overlay(
                Capsule().strokeBorder(isPrimary ? AppTheme.primaryAccent.opacity(0.2) : Color.white.opacity(0.08), lineWidth: 1)
            )
    }

    private var mistakesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "exclamationmark.triangle.fill", title: "COMMON MISTAKES", color: AppTheme.destructive)

            ForEach(Array(detailInfo.commonMistakes.enumerated()), id: \.offset) { _, mistake in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.destructive.opacity(0.7))
                        .padding(.top, 1)

                    Text(mistake)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                        .lineSpacing(3)
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppTheme.destructive.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    private var breathingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "wind", title: "BREATHING", color: AppTheme.success)

            ForEach(Array(detailInfo.breathingTips.enumerated()), id: \.offset) { _, tip in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.success.opacity(0.7))
                        .padding(.top, 1)

                    Text(tip)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                        .lineSpacing(3)
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppTheme.success.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "bolt.fill", title: "BENEFITS", color: AppTheme.warning)

            ForEach(Array(exercise.benefits.enumerated()), id: \.offset) { _, benefit in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.warning.opacity(0.7))
                        .padding(.top, 1)

                    Text(benefit)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                        .lineSpacing(3)
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppTheme.warning.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    private func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(color)
                .tracking(1.5)
        }
    }

    private var imagePlaceholder: some View {
        VStack(spacing: 10) {
            Image(systemName: exercise.region.icon)
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(regionColor.opacity(0.3))
            Text(exercise.name)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    private func startAutoPlay() {
        animationTask?.cancel()
        animationTask = Task {
            while !Task.isCancelled {
                stepProgress = 0
                withAnimation(.linear(duration: stepDuration)) {
                    stepProgress = 1.0
                }
                try? await Task.sleep(for: .seconds(stepDuration))
                guard !Task.isCancelled else { return }
                withAnimation(.spring(duration: 0.3)) {
                    currentStep = (currentStep + 1) % exercise.steps.count
                    stepProgress = 0
                }
            }
        }
    }
}

