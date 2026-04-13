import SwiftUI

struct VoiceLogView: View {
    @Bindable var viewModel: NutritionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var voiceService = VoiceLogService()
    @State private var selectedMeal: MealType = .breakfast
    @State private var pulseAnimation: Bool = false
    @State private var spinnerRotation: Double = 0
    @State private var detent: PresentationDetent = .height(260)

    private let brandOrange = Color(red: 1.0, green: 0.45, blue: 0.18)
    private let deepOrange = Color(red: 0.7, green: 0.28, blue: 0.05)
    private let darkOrange = Color(red: 0.45, green: 0.18, blue: 0.02)

    var body: some View {
        VStack(spacing: 0) {
            topBar
            mealChips
            contentForPhase
        }
        .presentationDetents([.height(260), .large], selection: $detent)
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
        .presentationBackground {
            Color(red: 0.08, green: 0.06, blue: 0.04)
                .overlay {
                    RadialGradient(
                        colors: [brandOrange.opacity(0.08), .clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 200
                    )
                }
        }
        .presentationContentInteraction(.scrolls)
        .onAppear {
            voiceService.startRecording()
            pulseAnimation = true
        }
        .onDisappear {
            voiceService.reset()
        }
        .onChange(of: voiceService.currentPhase) { _, newPhase in
            if newPhase == .results {
                withAnimation(.spring(duration: 0.3)) {
                    detent = .large
                }
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                voiceService.reset()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(width: 26, height: 26)
                    .background(.white.opacity(0.07), in: Circle())
            }

            Spacer()

            HStack(spacing: 5) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(brandOrange)
                Text("VOICE LOG")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Color.clear.frame(width: 26, height: 26)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    private var mealChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 4) {
                ForEach(MealType.allCases, id: \.self) { meal in
                    Button {
                        withAnimation(.spring(duration: 0.25)) {
                            selectedMeal = meal
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: meal.icon)
                                .font(.system(size: 8, weight: .semibold))
                            Text(meal.rawValue)
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(selectedMeal == meal ? .white : .white.opacity(0.35))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background {
                            if selectedMeal == meal {
                                Capsule()
                                    .fill(brandOrange.opacity(0.85))
                            } else {
                                Capsule()
                                    .fill(.white.opacity(0.05))
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 6)
        }
        .contentMargins(.horizontal, 16)
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private var contentForPhase: some View {
        switch voiceService.currentPhase {
        case .idle:
            idleView
        case .recording:
            recordingView
        case .transcribing:
            processingView(title: "Transcribing...", subtitle: "Converting speech to text")
        case .analyzing:
            processingView(title: "Analyzing food...", subtitle: "\"\(voiceService.transcribedText)\"")
        case .results:
            resultsView
        }
    }

    private var idleView: some View {
        VStack(spacing: 10) {
            Spacer()
            ProgressView()
                .tint(brandOrange)
                .scaleEffect(0.9)
            Text("Preparing mic...")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.35))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var recordingView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 4) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(brandOrange)
                        .frame(width: 5, height: 5)
                        .opacity(pulseAnimation ? 0.3 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseAnimation)
                    Text("Listening")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(brandOrange)
                }

                Text("Tell me what you ate")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.bottom, 14)

            HStack(spacing: 0) {
                waveformVisualizer
                    .frame(maxWidth: .infinity)

                Button {
                    pulseAnimation = false
                    Task {
                        await voiceService.stopRecordingAndProcess()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(brandOrange)
                            .frame(width: 44, height: 44)
                            .shadow(color: brandOrange.opacity(0.35), radius: 10, y: 2)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(.white)
                            .frame(width: 14, height: 14)
                    }
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: voiceService.isRecording)
                .padding(.leading, 12)
            }
            .padding(.horizontal, 24)

            if let error = voiceService.errorMessage {
                errorBanner(error)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var waveformVisualizer: some View {
        HStack(spacing: 2.5) {
            ForEach(0..<32, id: \.self) { index in
                let level = CGFloat(voiceService.audioLevels[index])
                let barHeight = max(3, level * 36)
                let opacity = 0.3 + level * 0.7

                Capsule()
                    .fill(brandOrange.opacity(opacity))
                    .frame(width: 3, height: barHeight)
                    .animation(.easeOut(duration: 0.08), value: voiceService.audioLevels[index])
            }
        }
        .frame(height: 36)
    }

    private func processingView(title: String, subtitle: String) -> some View {
        VStack(spacing: 14) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(darkOrange.opacity(0.15), lineWidth: 2.5)
                    .frame(width: 48, height: 48)

                Circle()
                    .stroke(darkOrange.opacity(0.06), lineWidth: 8)
                    .frame(width: 48, height: 48)
                    .scaleEffect(pulseAnimation ? 1.5 : 1.0)
                    .opacity(pulseAnimation ? 0 : 0.4)
                    .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: pulseAnimation)

                Circle()
                    .trim(from: 0, to: 0.65)
                    .stroke(
                        AngularGradient(
                            colors: [brandOrange, brandOrange.opacity(0.6), brandOrange.opacity(0.1), .clear],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                    )
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(spinnerRotation))

                Circle()
                    .fill(brandOrange)
                    .frame(width: 5, height: 5)
                    .offset(y: -24)
                    .rotationEffect(.degrees(spinnerRotation))
            }
            .onAppear {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    spinnerRotation = 360
                }
                pulseAnimation = true
            }

            processingDots(title: title)

            Text(subtitle)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.3))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 20)

            if let error = voiceService.errorMessage {
                errorBanner(error)
                    .padding(.horizontal, 16)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func processingDots(title: String) -> some View {
        HStack(spacing: 2) {
            Text(title.replacingOccurrences(of: "...", with: ""))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))

            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(.white.opacity(0.8))
                        .frame(width: 3, height: 3)
                        .offset(y: pulseAnimation ? -3 : 0)
                        .animation(
                            .easeInOut(duration: 0.4)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.15),
                            value: pulseAnimation
                        )
                }
            }
            .padding(.leading, 1)
            .padding(.bottom, -2)
        }
    }

    private var resultsView: some View {
        VStack(spacing: 0) {
            if !voiceService.transcribedText.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(brandOrange)
                        .frame(width: 24, height: 24)
                        .background(brandOrange.opacity(0.15), in: .rect(cornerRadius: 6))

                    Text("\"\(voiceService.transcribedText)\"")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                        .lineLimit(2)

                    Spacer(minLength: 4)

                    Button {
                        voiceService.reset()
                        voiceService.startRecording()
                        pulseAnimation = true
                        detent = .height(320)
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(brandOrange)
                            .frame(width: 26, height: 26)
                            .background(brandOrange.opacity(0.12), in: Circle())
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
            }

            if let error = voiceService.errorMessage {
                errorBanner(error)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 6)
            }

            if voiceService.nutritionResults.isEmpty && voiceService.errorMessage == nil {
                VStack(spacing: 10) {
                    Spacer()
                    ProgressView()
                        .tint(brandOrange)
                    Text("Generating nutrition data...")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(Array(voiceService.nutritionResults.enumerated()), id: \.offset) { _, result in
                            Button {
                                viewModel.addFoodFromAIResult(result, mealType: selectedMeal)
                                dismiss()
                            } label: {
                                resultCard(result)
                            }
                        }

                        if voiceService.nutritionResults.count > 1 {
                            Button {
                                for result in voiceService.nutritionResults {
                                    viewModel.addFoodFromAIResult(result, mealType: selectedMeal)
                                }
                                dismiss()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 13))
                                    Text("Add All Items")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [brandOrange, deepOrange],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    in: .rect(cornerRadius: 12)
                                )
                                .shadow(color: brandOrange.opacity(0.3), radius: 8, y: 3)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 32)
                    .padding(.top, 2)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private func resultCard(_ result: NutritionLookupResult) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(result.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    macroChip("P", value: result.protein, color: .cyan)
                    macroChip("C", value: result.carbs, color: brandOrange)
                    macroChip("F", value: result.fat, color: .purple)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text("\(result.calories)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(brandOrange)
                Text("cal")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.3))
            }

            Image(systemName: "plus.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(brandOrange)
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.06), Color.white.opacity(0.03)],
                startPoint: .top,
                endPoint: .bottom
            ),
            in: .rect(cornerRadius: 14)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(brandOrange.opacity(0.12), lineWidth: 0.5)
        )
    }

    private func macroChip(_ label: String, value: Double, color: Color) -> some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(color)
            Text("\(Int(value))g")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.1), in: Capsule())
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 11))
            Text(message)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.08), in: .rect(cornerRadius: 8))
    }
}
