import SwiftUI
import AVKit
import AVFoundation

struct WelcomeView: View {
    let onStart: () -> Void
    var onSignIn: (() -> Void)? = nil

    @State private var phoneOffsetX: CGFloat = 200
    @State private var phoneOffsetY: CGFloat = 500
    @State private var phoneRotation: Double = 8
    @State private var phoneOpacity: Double = 0
    @State private var videoPlayerID: Int = 0
    @State private var animationTask: Task<Void, Never>?


    private enum PhonePhase {
        case hidden, entering, visible, exiting
    }
    @State private var phase: PhonePhase = .hidden

    var body: some View {
        ZStack {
            BackgroundView()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                phoneMockup
                    .offset(x: phoneOffsetX, y: phoneOffsetY)
                    .rotationEffect(.degrees(phoneRotation))
                    .opacity(phoneOpacity)
                    .padding(.horizontal, 80)

                Spacer()

                VStack(spacing: 24) {
                    Text("Unlock Your\nFull Abs Potential")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(AppTheme.primaryText)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 16) {
                        Button(action: onStart) {
                            Text("Start My Transformation")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(AppTheme.primaryAccent)
                                .clipShape(.capsule)
                        }
                        .padding(.horizontal, 24)

                        Text("Ready To Reveal Your Abs?")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.primaryAccent)
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            startAnimationLoop()
        }
        .onDisappear {
            animationTask?.cancel()
        }
    }

    private func startAnimationLoop() {
        animationTask?.cancel()
        animationTask = Task {
            while !Task.isCancelled {
                phoneOffsetX = 200
                phoneOffsetY = 500
                phoneRotation = 8
                phoneOpacity = 0
                videoPlayerID += 1

                try? await Task.sleep(for: .seconds(0.5))
                if Task.isCancelled { return }

                withAnimation(.spring(duration: 0.9, bounce: 0.12)) {
                    phoneOffsetX = 0
                    phoneOffsetY = 0
                    phoneRotation = 0
                    phoneOpacity = 1
                }

                try? await Task.sleep(for: .seconds(8.0))
                if Task.isCancelled { return }

                withAnimation(.easeInOut(duration: 0.8)) {
                    phoneOffsetX = -200
                    phoneOffsetY = 500
                    phoneRotation = -8
                    phoneOpacity = 0
                }

                try? await Task.sleep(for: .seconds(1.8))
                if Task.isCancelled { return }
            }
        }
    }

    private var phoneMockup: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32)
                .fill(Color(red: 14/255, green: 14/255, blue: 28/255))
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: AppTheme.primaryAccent.opacity(0.12), radius: 40, y: 10)
                .shadow(color: .black.opacity(0.5), radius: 30, y: 15)

            WelcomeLoopingVideoPlayer()
                .id(videoPlayerID)
                .clipShape(.rect(cornerRadius: 32))
        }
        .aspectRatio(0.50, contentMode: .fit)
    }
}

struct WelcomeLoopingVideoPlayer: UIViewRepresentable {
    func makeUIView(context: Context) -> WelcomeVideoUIView {
        let view = WelcomeVideoUIView()
        return view
    }

    func updateUIView(_ uiView: WelcomeVideoUIView, context: Context) {}
}

class WelcomeVideoUIView: UIView {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var loopObserver: Any?

    init() {
        super.init(frame: .zero)
        setupPlayer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPlayer() {
        let playerItem: AVPlayerItem
        if let preloadedAsset = OnboardingPreloader.shared.videoAsset {
            playerItem = AVPlayerItem(asset: preloadedAsset)
        } else {
            let url = URL(string: OnboardingPreloader.videoURL)!
            playerItem = AVPlayerItem(url: url)
        }
        let avPlayer = AVPlayer(playerItem: playerItem)
        avPlayer.isMuted = true
        avPlayer.play()

        let layer = AVPlayerLayer(player: avPlayer)
        layer.videoGravity = .resizeAspectFill
        self.layer.addSublayer(layer)

        self.player = avPlayer
        self.playerLayer = layer

        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
        }
    }

    nonisolated override func layoutSubviews() {
        MainActor.assumeIsolated {
            super.layoutSubviews()
            playerLayer?.frame = bounds
        }
    }

    deinit {
        if let observer = loopObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        player?.pause()
    }
}
