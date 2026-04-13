import SwiftUI

struct MainTabView: View {
    @Bindable var vm: AppViewModel
    var store: StoreViewModel?

    @State private var selectedTab: Int = 2

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if #available(iOS 26.0, *) {
                    liquidGlassTabView
                } else {
                    fallbackTabView
                }
            }
            .ignoresSafeArea(.keyboard)

        }
        .onChange(of: vm.shouldNavigateToAnalysis) { _, newValue in
            if newValue {
                withAnimation(.spring(duration: 0.3)) {
                    selectedTab = 3
                }
                vm.shouldNavigateToAnalysis = false
            }
        }
    }

    @available(iOS 26.0, *)
    private var liquidGlassTabView: some View {
        TabView(selection: $selectedTab) {
            Tab("Routine", systemImage: "dumbbell.fill", value: 0) {
                RoutineView(vm: vm, selectedTab: selectedTab)
            }

            Tab("Nutrition", systemImage: "fork.knife", value: 1) {
                NutritionView(vm: vm)
            }

            Tab("Home", systemImage: "house.fill", value: 2) {
                DashboardView(vm: vm, selectedTab: $selectedTab)
            }

            Tab("Analysis", systemImage: "chart.bar.fill", value: 3) {
                AnalysisView(vm: vm)
            }

            Tab("Profile", systemImage: "person.fill", value: 4) {
                ProfileView(vm: vm, store: store)
            }
        }
        .tint(AppTheme.primaryAccent)
    }

    private var fallbackTabView: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                RoutineView(vm: vm, selectedTab: selectedTab)
                    .tag(0)

                NutritionView(vm: vm)
                    .tag(1)

                DashboardView(vm: vm, selectedTab: $selectedTab)
                    .tag(2)

                AnalysisView(vm: vm)
                    .tag(3)

                ProfileView(vm: vm, store: store)
                    .tag(4)
            }
            .toolbarBackground(.hidden, for: .tabBar)

            FallbackTabBar(selectedTab: $selectedTab)
        }
    }
}

struct FallbackTabBar: View {
    @Binding var selectedTab: Int

    private let tabs: [(icon: String, label: String)] = [
        ("dumbbell.fill", "Routine"),
        ("fork.knife", "Nutrition"),
        ("house.fill", "Home"),
        ("chart.bar.fill", "Analysis"),
        ("person.fill", "Profile")
    ]

    private let centerIndex = 2

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(AppTheme.navBarBorder)
                .frame(height: 1)

            HStack(spacing: 0) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                    Button {
                        withAnimation(.spring(duration: 0.25)) {
                            selectedTab = index
                        }
                    } label: {
                            tabButton(tab: tab, isSelected: selectedTab == index)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 2)
            .sensoryFeedback(.selection, trigger: selectedTab)
        }
        .background {
            AppTheme.navBarBg
                .ignoresSafeArea(.container, edges: .bottom)
        }
    }

    private func tabButton(tab: (icon: String, label: String), isSelected: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: tab.icon)
                .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? AppTheme.primaryAccent : AppTheme.muted)
                .frame(height: 28)

            Text(tab.label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isSelected ? AppTheme.primaryAccent : AppTheme.muted)
        }
    }
}
