import SwiftUI

struct SurveyEquipmentView: View {
    @Binding var equipment: EquipmentSetting?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Where do you train?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("Your workouts will only include exercises you can actually do.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            VStack(spacing: 10) {
                ForEach(EquipmentSetting.allCases, id: \.self) { setting in
                    OnboardingPillButton(
                        title: setting.rawValue,
                        subtitle: setting.detail,
                        icon: setting.icon,
                        isSelected: equipment == setting
                    ) {
                        equipment = setting
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)

            Spacer()
        }
    }
}
