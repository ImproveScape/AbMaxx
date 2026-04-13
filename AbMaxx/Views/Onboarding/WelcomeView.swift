import SwiftUI

struct WelcomeView: View {
    let onStart: () -> Void
    var onSignIn: (() -> Void)?

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            AppTheme.onboardingGradient.ignoresSafeArea()

            StandardBackgroundOrbs()

            VStack(spacing: 0) {
                Spacer(minLength: 20)

                phoneMockup
                    .padding(.horizontal, 40)

                Spacer(minLength: 24)

                VStack(spacing: 8) {
                    Text("Your abs are hiding.")
                        .font(.system(size: 32, weight: .black))
                        .foregroundStyle(.white)

                    Text("Let's reveal them.")
                        .font(.system(size: 32, weight: .black))
                        .foregroundStyle(AppTheme.primaryAccent)
                        .shadow(color: AppTheme.primaryAccent.opacity(0.3), radius: 15)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

                Spacer().frame(height: 32)

                Button(action: onStart) {
                    Text("Start My Transformation")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(AppTheme.primaryAccent)
                        .clipShape(.rect(cornerRadius: 14))
                        .shadow(color: AppTheme.primaryAccent.opacity(0.4), radius: 20, y: 6)
                }
                .padding(.horizontal, 24)

                if let onSignIn {
                    Button(action: onSignIn) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(AppTheme.primaryAccent.opacity(0.8))
                            Text("Already have an account?")
                                .foregroundStyle(.white.opacity(0.5))
                            Text("Log in")
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.primaryAccent)
                        }
                        .font(.system(size: 14))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.06))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.top, 16)
                }

                Spacer().frame(height: 36)
            }
        }
    }

    private var phoneMockup: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 36)
                .fill(Color(red: 14/255, green: 14/255, blue: 28/255))
                .overlay(
                    RoundedRectangle(cornerRadius: 36)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: AppTheme.primaryAccent.opacity(0.15), radius: 40, y: 10)

            VStack(spacing: 0) {
                mockStatusBar
                    .padding(.top, 12)
                    .padding(.horizontal, 20)

                mockDashboardContent
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                Spacer(minLength: 0)

                mockTabBar
                    .padding(.bottom, 8)
            }
            .clipShape(.rect(cornerRadius: 36))
        }
        .aspectRatio(0.49, contentMode: .fit)
    }

    private var mockStatusBar: some View {
        HStack {
            Text("9:41")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "cellularbars")
                    .font(.system(size: 9))
                Image(systemName: "wifi")
                    .font(.system(size: 10))
                Image(systemName: "battery.100")
                    .font(.system(size: 11))
            }
            .foregroundStyle(.white.opacity(0.5))
        }
    }

    private var mockDashboardContent: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("AbMaxx Score")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                    Text("78")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(AppTheme.primaryText)
                }
                Spacer()
                mockScoreRing
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.cardSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(AppTheme.border, lineWidth: 1)
                    )
            )

            HStack(spacing: 8) {
                mockZoneCard(name: "Upper", score: 82, color: AppTheme.primaryAccent)
                mockZoneCard(name: "Lower", score: 71, color: Color(red: 0.55, green: 0.30, blue: 1.0))
            }

            HStack(spacing: 8) {
                mockZoneCard(name: "Obliques", score: 76, color: AppTheme.success)
                mockZoneCard(name: "Core", score: 68, color: AppTheme.orange)
            }

            mockSessionCard
        }
    }

    private var mockScoreRing: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.border, lineWidth: 4)
                .frame(width: 44, height: 44)
            Circle()
                .trim(from: 0, to: 0.78)
                .stroke(
                    AppTheme.primaryAccent,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 44, height: 44)
                .rotationEffect(.degrees(-90))
            Text("78")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.primaryText)
        }
    }

    private func mockZoneCard(name: String, score: Int, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 28, height: 28)
                .overlay(
                    Text("\(score)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(color)
                )
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                Text("\(score)/100")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryText)
            }
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.cardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(AppTheme.border, lineWidth: 1)
                )
        )
    }

    private var mockSessionCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "flame.fill")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.primaryAccent)
            VStack(alignment: .leading, spacing: 1) {
                Text("Today's Session")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryText)
                Text("4 exercises \u{2022} 12 min")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
            Text("Start")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AppTheme.primaryAccent)
                .clipShape(.capsule)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.cardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(AppTheme.blueBorder, lineWidth: 1)
                )
        )
    }

    private var mockTabBar: some View {
        HStack(spacing: 0) {
            mockTabItem(icon: "house.fill", label: "Home", active: true)
            mockTabItem(icon: "chart.bar.fill", label: "Stats", active: false)
            mockTabItem(icon: "gearshape.fill", label: "Settings", active: false)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(
            AppTheme.cardSurface.opacity(0.9)
        )
    }

    private func mockTabItem(icon: String, label: String, active: Bool) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 14))
            Text(label)
                .font(.system(size: 8, weight: .medium))
        }
        .foregroundStyle(active ? AppTheme.primaryAccent : AppTheme.secondaryText)
        .frame(maxWidth: .infinity)
    }
}
