import SwiftUI

struct SurveyAgeView: View {
    @Binding var dateOfBirth: Date

    private var age: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 25
    }

    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let min = calendar.date(byAdding: .year, value: -80, to: Date()) ?? Date()
        let max = calendar.date(byAdding: .year, value: -13, to: Date()) ?? Date()
        return min...max
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("How old are you?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("We'll optimize your plan for your body's recovery speed.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 24)
            .padding(.horizontal, 24)

            VStack(spacing: 6) {
                Text("\(age)")
                    .font(.system(size: 72, weight: .black))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: age)

                Text("years old")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.muted)
            }
            .padding(.top, 24)

            DatePicker(
                "Date of Birth",
                selection: $dateOfBirth,
                in: dateRange,
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxHeight: 160)
            .padding(.horizontal, 24)
            .padding(.top, 8)

            Spacer()
        }
    }
}
