import SwiftUI

struct ContentView: View {
    @State private var vm = AppViewModel()
    @State private var onboardingVM = OnboardingViewModel()
    @State private var store = StoreViewModel()
    @State private var showOnboarding: Bool = true
    @State private var showSplash: Bool = true
    @State private var waterToastWorkItem: DispatchWorkItem?
    @State private var foodToastWorkItem: DispatchWorkItem?
    @State private var macroOverToastWorkItem: DispatchWorkItem?

    var body: some View {
        ZStack {
            BackgroundView()
                .ignoresSafeArea()
            if showSplash && !vm.profile.hasCompletedOnboarding {
                SplashAnimationView {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showSplash = false
                    }
                }
                .transition(.opacity)
            } else if showOnboarding && !vm.profile.hasCompletedOnboarding {
                OnboardingFlowView(
                    viewModel: onboardingVM,
                    store: store,
                    onComplete: { profile, scanResult in
                        OnboardingViewModel.clearSavedProgress()
                        vm.profile = profile
                        if let result = scanResult {
                            vm.addScanResult(result)
                        }
                        vm.recalculateNutrition()
                        vm.regenerateTrainingPlan()
                        vm.save()
                        vm.requestNotificationPermission()
                        withAnimation(.snappy) {
                            showOnboarding = false
                        }
                    }
                )
                .transition(.opacity)
            } else {
                MainTabView(vm: vm, store: store)
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

            if vm.showMilestoneUnlock, let milestone = vm.unlockedMilestone {
                MilestoneUnlockCelebrationView(milestone: milestone) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        vm.showMilestoneUnlock = false
                        vm.unlockedMilestone = nil
                    }
                }
                .transition(.opacity)
                .zIndex(99)
            }

            if vm.showWaterToast {
                VStack {
                    WaterLoggedToast(
                        glassCount: vm.waterToastCount,
                        waterGoal: vm.dailyNutrition.waterGoal
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    Spacer()
                }
                .padding(.top, 60)
                .zIndex(98)
                .allowsHitTesting(false)
            }

            if vm.showFoodToast {
                VStack {
                    FoodLoggedToast(foodName: vm.foodToastName)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                    Spacer()
                }
                .padding(.top, 60)
                .zIndex(97)
                .allowsHitTesting(false)
            }

            if vm.showMacroOverToast {
                MacroOverLimitToast(
                    macroName: vm.macroOverName,
                    overByAmount: vm.macroOverAmount,
                    message: vm.macroOverMessage
                )
                .transition(.opacity)
                .zIndex(200)
                .allowsHitTesting(false)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            vm.load()
            if vm.profile.hasCompletedOnboarding {
                showSplash = false
                showOnboarding = false
                vm.requestNotificationPermission()
            } else {
                let restored = onboardingVM.restoreProgressIfNeeded()
                if restored {
                    showSplash = false
                }
                OnboardingPreloader.shared.preloadAll()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            if vm.profile.hasCompletedOnboarding {
                vm.refreshSmartNotifications()
            }
        }
        .onChange(of: vm.showWaterToast) { _, newValue in
            if newValue {
                waterToastWorkItem?.cancel()
                let work = DispatchWorkItem {
                    withAnimation(.spring(duration: 0.3)) {
                        vm.showWaterToast = false
                    }
                }
                waterToastWorkItem = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: work)
            }
        }
        .onChange(of: vm.showFoodToast) { _, newValue in
            if newValue {
                foodToastWorkItem?.cancel()
                let work = DispatchWorkItem {
                    withAnimation(.spring(duration: 0.3)) {
                        vm.showFoodToast = false
                    }
                }
                foodToastWorkItem = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: work)
            }
        }
        .onChange(of: vm.showMacroOverToast) { _, newValue in
            if newValue {
                macroOverToastWorkItem?.cancel()
                let work = DispatchWorkItem {
                    withAnimation(.spring(duration: 0.4)) {
                        vm.showMacroOverToast = false
                    }
                }
                macroOverToastWorkItem = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0, execute: work)
            }
        }
        .task {
            await store.checkStatus()
        }
    }

}
