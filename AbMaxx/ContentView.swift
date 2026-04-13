import SwiftUI

struct ContentView: View {
    @State private var vm = AppViewModel()
    @State private var onboardingVM = OnboardingViewModel()
    @State private var store = StoreViewModel()
    @State private var showOnboarding: Bool = true
    @State private var showSplash: Bool = true
    @State private var showReturningSignIn: Bool = false
    @State private var isRestoringAccount: Bool = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            if showSplash && !vm.profile.hasCompletedOnboarding {
                SplashAnimationView {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showSplash = false
                    }
                }
                .transition(.opacity)
            } else if showReturningSignIn {
                SignInView(
                    onComplete: { handleReturningSignInComplete() },
                    onSkip: {
                        withAnimation(.snappy) {
                            showReturningSignIn = false
                        }
                    },
                    isReturningUser: true,
                    onBack: {
                        withAnimation(.snappy) {
                            showReturningSignIn = false
                        }
                    }
                )
                .transition(.opacity)
            } else if isRestoringAccount {
                ZStack {
                    Color.black.ignoresSafeArea()
                    AppTheme.onboardingGradient.ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(AppTheme.primaryAccent)
                            .scaleEffect(1.2)
                        Text("Restoring your account...")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
                .transition(.opacity)
            } else if showOnboarding && !vm.profile.hasCompletedOnboarding {
                OnboardingFlowView(
                    viewModel: onboardingVM,
                    store: store,
                    onComplete: { profile, scanResult in
                        vm.profile = profile
                        if let result = scanResult {
                            vm.addScanResult(result)
                        }
                        vm.recalculateNutrition()
                        vm.regenerateTrainingPlan()
                        vm.save()
                        vm.requestNotificationPermission()
                        Task {
                            await AuthenticationService.shared.saveProfileToCloud(
                                profile: vm.profile,
                                scanResults: vm.scanResults
                            )
                        }
                        withAnimation(.snappy) {
                            showOnboarding = false
                        }
                    },
                    onReturningSignIn: {
                        withAnimation(.snappy) {
                            showReturningSignIn = true
                        }
                    }
                )
                .transition(.opacity)
            } else if !store.isPremium {
                PaywallView(store: store) {
                    vm.profile.isSubscribed = true
                    vm.save()
                }
                .transition(.opacity)
            } else {
                MainTabView(vm: vm, store: store, onSignOut: {
                    withAnimation(.snappy) {
                        showOnboarding = true
                    }
                }, onDeleteAccount: {
                    Task {
                        await AuthenticationService.shared.deleteAccount()
                    }
                    withAnimation(.snappy) {
                        showOnboarding = true
                    }
                })
                    .transition(.opacity)
            }

            if vm.showBadgeUnlock, let badge = vm.unlockedBadge {
                BadgeUnlockView(oldBadge: vm.previousBadge, newBadge: badge) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        vm.showBadgeUnlock = false
                        vm.unlockedBadge = nil
                        vm.previousBadge = nil
                    }
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            vm.load()
            if vm.profile.hasCompletedOnboarding {
                showSplash = false
                showOnboarding = false
                vm.requestNotificationPermission()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            if vm.profile.hasCompletedOnboarding {
                vm.refreshSmartNotifications()
            }
        }
        .task {
            await store.checkStatus()
            await AuthenticationService.shared.ensureValidToken()
            if AuthenticationService.shared.authProvider == .apple {
                await AuthenticationService.shared.validateAppleCredential()
            }
        }
    }

    private func handleReturningSignInComplete() {
        withAnimation(.snappy) {
            showReturningSignIn = false
            isRestoringAccount = true
        }
        Task {
            if let (profile, scans) = await AuthenticationService.shared.restoreProfileFromCloud() {
                vm.profile = profile
                vm.profile.hasCompletedOnboarding = true
                for scan in scans {
                    vm.addScanResult(scan)
                }
                vm.recalculateNutrition()
                vm.regenerateTrainingPlan()
                vm.save()
                vm.requestNotificationPermission()
                await store.checkStatus()
                withAnimation(.snappy) {
                    isRestoringAccount = false
                    showOnboarding = false
                    showSplash = false
                }
            } else {
                withAnimation(.snappy) {
                    isRestoringAccount = false
                }
            }
        }
    }
}
