import SwiftUI

struct SurveyHeightWeightView: View {
    @Binding var heightFeet: Int
    @Binding var heightInches: Int
    @Binding var weightLbs: Double
    @Binding var useMetric: Bool

    @State private var heightCm: Int = 170
    @State private var weightKg: Int = 70
    @State private var weightLbsInt: Int = 150
    @State private var appeared: Bool = false
    @State private var didInitialize: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Height & Weight")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("This unlocks your exact calorie & macro targets.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 20)
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)

            unitToggle
                .padding(.top, 28)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

            HStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text("HEIGHT")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(AppTheme.secondaryText)
                        .tracking(2)

                    if useMetric {
                        Picker("", selection: $heightCm) {
                            ForEach(140...220, id: \.self) { cm in
                                Text("\(cm) cm")
                                    .foregroundStyle(.white)
                                    .tag(cm)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 180)
                    } else {
                        HStack(spacing: 0) {
                            Picker("", selection: $heightFeet) {
                                ForEach(4...7, id: \.self) { ft in
                                    Text("\(ft) ft")
                                        .foregroundStyle(.white)
                                        .tag(ft)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80, height: 180)
                            .clipped()

                            Picker("", selection: $heightInches) {
                                ForEach(0...11, id: \.self) { inch in
                                    Text("\(inch) in")
                                        .foregroundStyle(.white)
                                        .tag(inch)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80, height: 180)
                            .clipped()
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 8) {
                    Text("WEIGHT")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(AppTheme.secondaryText)
                        .tracking(2)

                    if useMetric {
                        Picker("", selection: $weightKg) {
                            ForEach(30...180, id: \.self) { kg in
                                Text("\(kg) kg")
                                    .foregroundStyle(.white)
                                    .tag(kg)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 180)
                    } else {
                        Picker("", selection: $weightLbsInt) {
                            ForEach(60...400, id: \.self) { lb in
                                Text("\(lb) lbs")
                                    .foregroundStyle(.white)
                                    .tag(lb)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 180)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 16)
            .padding(.horizontal, 8)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)

            Spacer()
        }
        .onAppear {
            if !didInitialize {
                weightLbsInt = max(60, min(400, Int(weightLbs)))
                let totalCm = Double(heightFeet) * 30.48 + Double(heightInches) * 2.54
                heightCm = max(140, min(220, Int(totalCm)))
                weightKg = max(30, min(180, Int(weightLbs * 0.453592)))
                didInitialize = true
            }
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
        .onChange(of: heightFeet) { _, _ in
            guard didInitialize else { return }
            syncMetricFromImperial()
        }
        .onChange(of: heightInches) { _, _ in
            guard didInitialize else { return }
            syncMetricFromImperial()
        }
        .onChange(of: heightCm) { _, newValue in
            guard didInitialize else { return }
            if useMetric {
                let totalInches = Double(newValue) / 2.54
                heightFeet = Int(totalInches / 12)
                heightInches = Int(totalInches.truncatingRemainder(dividingBy: 12))
            }
        }
        .onChange(of: weightLbsInt) { _, newValue in
            guard didInitialize else { return }
            weightLbs = Double(newValue)
            weightKg = max(30, min(180, Int(Double(newValue) * 0.453592)))
        }
        .onChange(of: weightKg) { _, newValue in
            guard didInitialize else { return }
            if useMetric {
                let lbs = Double(newValue) / 0.453592
                weightLbs = lbs.rounded()
                weightLbsInt = max(60, min(400, Int(lbs.rounded())))
            }
        }
        .onChange(of: useMetric) { _, newValue in
            if newValue {
                let cm = Double(heightFeet) * 30.48 + Double(heightInches) * 2.54
                heightCm = max(140, min(220, Int(cm.rounded())))
                weightKg = max(30, min(180, Int(weightLbs * 0.453592)))
            } else {
                let totalInches = Double(heightCm) / 2.54
                heightFeet = Int(totalInches / 12)
                heightInches = Int(totalInches.truncatingRemainder(dividingBy: 12))
                weightLbsInt = max(60, min(400, Int((Double(weightKg) / 0.453592).rounded())))
                weightLbs = Double(weightLbsInt)
            }
        }
    }

    private var unitToggle: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(.spring(duration: 0.3)) { useMetric = false }
            } label: {
                Text("Imperial")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(!useMetric ? .white : AppTheme.secondaryText)
                    .frame(width: 90, height: 34)
                    .background(
                        Capsule()
                            .fill(!useMetric ? Color.white.opacity(0.15) : .clear)
                    )
            }

            Button {
                withAnimation(.spring(duration: 0.3)) { useMetric = true }
            } label: {
                Text("Metric")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(useMetric ? .white : AppTheme.secondaryText)
                    .frame(width: 90, height: 34)
                    .background(
                        Capsule()
                            .fill(useMetric ? Color.white.opacity(0.15) : .clear)
                    )
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.06))
        )
    }

    private func syncMetricFromImperial() {
        if !useMetric {
            let totalCm = Double(heightFeet) * 30.48 + Double(heightInches) * 2.54
            heightCm = max(140, min(220, Int(totalCm.rounded())))
        }
    }
}
