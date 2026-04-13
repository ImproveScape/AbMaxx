import SwiftUI
import AuthenticationServices

struct SignInView: View {
    let onComplete: () -> Void
    let onSkip: () -> Void
    let isReturningUser: Bool
    var onBack: (() -> Void)?

    @State private var isSigningIn: Bool = false
    @State private var isSigningInGoogle: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var signInSuccess: Bool = false
    @State private var checkmarkScale: Double = 0
    @State private var appeared: Bool = false

    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            AppTheme.onboardingGradient.ignoresSafeArea()

            StandardBackgroundOrbs()

            if signInSuccess {
                successContent
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            } else {
                mainContent
            }
        }
        .animation(.spring(duration: 0.5), value: signInSuccess)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                appeared = true
            }
        }
        .alert("Sign In Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    private var mainContent: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                HStack {
                    Button {
                        if let onBack {
                            onBack()
                        } else {
                            onSkip()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 44, height: 44)
                            .background(.white.opacity(0.06), in: Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer()

                headerSection
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)

                Spacer()

                VStack(spacing: 20) {
                    signInButtons
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)

                    termsFooter
                        .opacity(appeared ? 1 : 0)
                }
                .padding(.bottom, max(geo.safeAreaInsets.bottom, 16) + 20)
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(AppTheme.primaryAccent.opacity(0.08))
                    .frame(width: 88, height: 88)

                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(AppTheme.primaryAccent)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(spacing: 10) {
                Text("Welcome Back")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppTheme.primaryText)

                Text("Sign in to restore your progress")
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }

    private var signInButtons: some View {
        VStack(spacing: 12) {
            Button(action: performAppleSignIn) {
                HStack(spacing: 12) {
                    if isSigningIn {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 18, weight: .medium))
                        Text("Continue with Apple")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(.white.opacity(0.1))
                .clipShape(.rect(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                )
            }
            .disabled(isSigningIn || isSigningInGoogle)

            Button(action: performGoogleSignIn) {
                HStack(spacing: 12) {
                    if isSigningInGoogle {
                        ProgressView()
                            .tint(.white)
                    } else {
                        googleIcon
                        Text("Continue with Google")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(.white.opacity(0.06))
                .clipShape(.rect(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                )
            }
            .disabled(isSigningIn || isSigningInGoogle)
        }
        .padding(.horizontal, 24)
    }

    private var googleIcon: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let cx = w / 2
            let cy = h / 2
            let r = min(w, h) / 2 * 0.88
            let inner = r * 0.55

            var bluePath = Path()
            bluePath.move(to: CGPoint(x: cx, y: cy))
            bluePath.addArc(center: CGPoint(x: cx, y: cy), radius: r, startAngle: .degrees(-45), endAngle: .degrees(10), clockwise: false)
            bluePath.closeSubpath()
            context.fill(bluePath, with: .color(Color(red: 0.26, green: 0.52, blue: 0.96)))

            var greenPath = Path()
            greenPath.move(to: CGPoint(x: cx, y: cy))
            greenPath.addArc(center: CGPoint(x: cx, y: cy), radius: r, startAngle: .degrees(10), endAngle: .degrees(120), clockwise: false)
            greenPath.closeSubpath()
            context.fill(greenPath, with: .color(Color(red: 0.20, green: 0.66, blue: 0.33)))

            var yellowPath = Path()
            yellowPath.move(to: CGPoint(x: cx, y: cy))
            yellowPath.addArc(center: CGPoint(x: cx, y: cy), radius: r, startAngle: .degrees(120), endAngle: .degrees(210), clockwise: false)
            yellowPath.closeSubpath()
            context.fill(yellowPath, with: .color(Color(red: 0.98, green: 0.74, blue: 0.02)))

            var redPath = Path()
            redPath.move(to: CGPoint(x: cx, y: cy))
            redPath.addArc(center: CGPoint(x: cx, y: cy), radius: r, startAngle: .degrees(210), endAngle: .degrees(315), clockwise: false)
            redPath.closeSubpath()
            context.fill(redPath, with: .color(Color(red: 0.92, green: 0.26, blue: 0.21)))

            let centerCircle = Path(ellipseIn: CGRect(x: cx - inner, y: cy - inner, width: inner * 2, height: inner * 2))
            context.fill(centerCircle, with: .color(.white))

            let barRect = CGRect(x: cx, y: cy - r * 0.25, width: r, height: r * 0.5)
            context.fill(Path(barRect), with: .color(Color(red: 0.26, green: 0.52, blue: 0.96)))

            let innerBarRect = CGRect(x: cx, y: cy - inner * 0.55, width: inner * 1.1, height: inner * 1.1)
            context.fill(Path(innerBarRect), with: .color(.white))
        }
        .frame(width: 18, height: 18)
    }

    private var termsFooter: some View {
        VStack(spacing: 4) {
            Text("By continuing, you agree to our")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.secondaryText.opacity(0.6))
            HStack(spacing: 4) {
                Button("Terms of Service") {
                    if let url = URL(string: "https://abmaxxterms.carrd.co") {
                        openURL(url)
                    }
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.primaryAccent)
                Text("and")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.secondaryText.opacity(0.6))
                Button("Privacy Policy") {
                    if let url = URL(string: "https://abmaxxprivacypolicy.carrd.co") {
                        openURL(url)
                    }
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.primaryAccent)
            }
        }
        .padding(.horizontal, 24)
    }

    private var successContent: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(AppTheme.success.opacity(0.1))
                    .frame(width: 110, height: 110)

                Circle()
                    .fill(AppTheme.success.opacity(0.05))
                    .frame(width: 140, height: 140)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(AppTheme.success)
                    .scaleEffect(checkmarkScale)
                    .shadow(color: AppTheme.success.opacity(0.4), radius: 30)
            }

            VStack(spacing: 10) {
                Text("Welcome Back!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppTheme.primaryText)

                Text("Restoring your progress...")
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }

    private func performAppleSignIn() {
        isSigningIn = true
        Task {
            let success = await AuthenticationService.shared.signInWithApple()
            isSigningIn = false

            if success {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation(.spring(duration: 0.5)) {
                    signInSuccess = true
                }
                withAnimation(.spring(duration: 0.5, bounce: 0.3).delay(0.15)) {
                    checkmarkScale = 1.0
                }
                try? await Task.sleep(for: .seconds(1.5))
                onComplete()
            } else if let err = AuthenticationService.shared.error {
                errorMessage = err
                showError = true
            }
        }
    }

    private func performGoogleSignIn() {
        isSigningInGoogle = true
        Task {
            let success = await AuthenticationService.shared.signInWithGoogle()
            isSigningInGoogle = false

            if success {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation(.spring(duration: 0.5)) {
                    signInSuccess = true
                }
                withAnimation(.spring(duration: 0.5, bounce: 0.3).delay(0.15)) {
                    checkmarkScale = 1.0
                }
                try? await Task.sleep(for: .seconds(1.5))
                onComplete()
            } else if let err = AuthenticationService.shared.error {
                errorMessage = err
                showError = true
            }
        }
    }
}
