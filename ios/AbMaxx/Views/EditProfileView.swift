import SwiftUI

struct EditProfileView: View {
    @Bindable var vm: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var gender: Gender
    @State private var dateOfBirth: Date
    @State private var heightFeet: Int
    @State private var heightInches: Int
    @State private var weightLbs: Double
    @State private var useMetric: Bool
    @State private var username: String
    @State private var equipmentSetting: EquipmentSetting
    @State private var weightText: String = ""
    @State private var heightCmText: String = ""
    @State private var showSavedConfirmation: Bool = false

    init(vm: AppViewModel) {
        self.vm = vm
        let p = vm.profile
        _gender = State(initialValue: p.gender)
        _dateOfBirth = State(initialValue: p.dateOfBirth)
        _heightFeet = State(initialValue: p.heightFeet)
        _heightInches = State(initialValue: p.heightInches)
        _weightLbs = State(initialValue: p.weightLbs)
        _useMetric = State(initialValue: p.useMetric)
        _username = State(initialValue: p.username)
        _equipmentSetting = State(initialValue: p.equipmentSetting)
    }

    private var hasChanges: Bool {
        let p = vm.profile
        return gender != p.gender ||
            dateOfBirth != p.dateOfBirth ||
            heightFeet != p.heightFeet ||
            heightInches != p.heightInches ||
            weightLbs != p.weightLbs ||
            useMetric != p.useMetric ||
            username != p.username ||
            equipmentSetting != p.equipmentSetting
    }

    private var age: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 25
    }

    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let minDate = calendar.date(byAdding: .year, value: -80, to: Date()) ?? Date()
        let maxDate = calendar.date(byAdding: .year, value: -13, to: Date()) ?? Date()
        return minDate...maxDate
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundView().ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        nameSection
                        genderSection
                        ageSection
                        measurementsSection
                        equipmentSection
                        saveButton
                        Color.clear.frame(height: 40)
                    }
                    .padding(.top, 8)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.muted)
                    }
                }
            }
            .onAppear {
                weightText = "\(Int(weightLbs))"
                if useMetric {
                    heightCmText = "\(heightFeet)"
                }
            }
            .overlay {
                if showSavedConfirmation {
                    savedToast
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: - Name

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "person.fill", title: "NAME")

            HStack(spacing: 12) {
                Image(systemName: "at")
                    .foregroundStyle(AppTheme.muted)
                TextField("Your name", text: $username)
                    .foregroundStyle(.white)
                    .font(.body.weight(.medium))
            }
            .padding(14)
            .background(AppTheme.cardSurface)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(AppTheme.border.opacity(0.5), lineWidth: 1)
            )
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Gender

    private var genderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "figure.stand", title: "GENDER")

            HStack(spacing: 10) {
                ForEach(Gender.allCases, id: \.self) { g in
                    Button {
                        withAnimation(.spring(duration: 0.2)) { gender = g }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: g == .male ? "figure.stand" : "figure.stand.dress")
                                .font(.body.weight(.semibold))
                            Text(g.rawValue)
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(gender == g ? .white : AppTheme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(gender == g ? AppTheme.primaryAccent : AppTheme.cardSurface)
                        .clipShape(.rect(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(gender == g ? AppTheme.primaryAccent.opacity(0.6) : AppTheme.border.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .sensoryFeedback(.selection, trigger: gender)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Age

    private var ageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "calendar", title: "AGE")

            VStack(spacing: 8) {
                Text("\(age) years old")
                    .font(.system(size: 22, weight: .bold, design: .default))
                    .foregroundStyle(.white)

                DatePicker(
                    "Date of Birth",
                    selection: $dateOfBirth,
                    in: dateRange,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(AppTheme.primaryAccent)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(AppTheme.cardSurface)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppTheme.border.opacity(0.4), lineWidth: 1)
            )
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Measurements

    private var measurementsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "ruler", title: "MEASUREMENTS")

            Picker("", selection: $useMetric) {
                Text("Imperial").tag(false)
                Text("Metric").tag(true)
            }
            .pickerStyle(.segmented)
            .onChange(of: useMetric) { _, newValue in
                if newValue {
                    let cm = Double(heightFeet) * 30.48 + Double(heightInches) * 2.54
                    heightFeet = Int(cm)
                    heightInches = 0
                    let kg = weightLbs * 0.453592
                    weightLbs = kg.rounded()
                    weightText = "\(Int(weightLbs))"
                    heightCmText = "\(heightFeet)"
                } else {
                    let totalInches = Double(heightFeet) / 2.54
                    heightFeet = Int(totalInches / 12)
                    heightInches = Int(totalInches.truncatingRemainder(dividingBy: 12))
                    weightLbs = (weightLbs / 0.453592).rounded()
                    weightText = "\(Int(weightLbs))"
                }
            }

            if useMetric {
                HStack(spacing: 10) {
                    measurementCard(label: "HEIGHT") {
                        HStack(spacing: 4) {
                            TextField("175", text: $heightCmText)
                                .font(.system(size: 28, weight: .bold, design: .default))
                                .foregroundStyle(.white)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 80)
                                .onChange(of: heightCmText) { _, newValue in
                                    if let val = Int(newValue) { heightFeet = val }
                                }
                            Text("cm")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.muted)
                        }
                    }
                    measurementCard(label: "WEIGHT") {
                        HStack(spacing: 4) {
                            TextField("77", text: $weightText)
                                .font(.system(size: 28, weight: .bold, design: .default))
                                .foregroundStyle(.white)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 80)
                                .onChange(of: weightText) { _, newValue in
                                    if let val = Double(newValue) { weightLbs = val }
                                }
                            Text("kg")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.muted)
                        }
                    }
                }
            } else {
                HStack(spacing: 10) {
                    measurementCard(label: "HEIGHT") {
                        HStack(spacing: 8) {
                            Picker("Feet", selection: $heightFeet) {
                                ForEach(4...7, id: \.self) { ft in
                                    Text("\(ft) ft").tag(ft)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.white)

                            Picker("Inches", selection: $heightInches) {
                                ForEach(0...11, id: \.self) { inch in
                                    Text("\(inch) in").tag(inch)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.white)
                        }
                    }
                    measurementCard(label: "WEIGHT") {
                        HStack(spacing: 4) {
                            TextField("170", text: $weightText)
                                .font(.system(size: 28, weight: .bold, design: .default))
                                .foregroundStyle(.white)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 80)
                                .onChange(of: weightText) { _, newValue in
                                    if let val = Double(newValue) { weightLbs = val }
                                }
                            Text("lbs")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.muted)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func measurementCard<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.muted)
                .tracking(2)
            content()
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppTheme.border.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - Equipment

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "dumbbell.fill", title: "EQUIPMENT")

            HStack(spacing: 10) {
                ForEach(EquipmentSetting.allCases, id: \.self) { setting in
                    Button {
                        withAnimation(.spring(duration: 0.2)) { equipmentSetting = setting }
                    } label: {
                        VStack(spacing: 10) {
                            Image(systemName: setting.icon)
                                .font(.title3.weight(.semibold))
                            Text(setting.rawValue)
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(equipmentSetting == setting ? .white : AppTheme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(equipmentSetting == setting ? AppTheme.primaryAccent : AppTheme.cardSurface)
                        .clipShape(.rect(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(equipmentSetting == setting ? AppTheme.primaryAccent.opacity(0.6) : AppTheme.border.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .sensoryFeedback(.selection, trigger: equipmentSetting)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Save

    private var saveButton: some View {
        Button {
            saveChanges()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.body.weight(.bold))
                Text("Save Changes")
                    .font(.body.weight(.bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(hasChanges ? AppTheme.primaryAccent : AppTheme.muted.opacity(0.5))
            .clipShape(.rect(cornerRadius: 16))
            .shadow(color: hasChanges ? AppTheme.primaryAccent.opacity(0.3) : .clear, radius: 12, y: 4)
        }
        .disabled(!hasChanges)
        .padding(.horizontal, 16)
        .sensoryFeedback(.success, trigger: showSavedConfirmation)
    }

    private var savedToast: some View {
        VStack {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.body.weight(.bold))
                    .foregroundStyle(AppTheme.success)
                Text("Profile updated! Nutrition recalculated.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(AppTheme.cardSurface)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(AppTheme.success.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 20, y: 8)
            .padding(.top, 8)

            Spacer()
        }
    }

    // MARK: - Helpers

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppTheme.primaryAccent)
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppTheme.secondaryText)
                .tracking(1.5)
        }
    }

    private func saveChanges() {
        vm.profile.username = username
        vm.profile.gender = gender
        vm.profile.dateOfBirth = dateOfBirth
        vm.profile.heightFeet = heightFeet
        vm.profile.heightInches = heightInches
        vm.profile.weightLbs = weightLbs
        vm.profile.useMetric = useMetric
        vm.profile.equipmentSetting = equipmentSetting
        vm.recalculateNutrition()
        vm.refreshExercisesForEquipment()
        vm.save()

        withAnimation(.spring(duration: 0.4)) {
            showSavedConfirmation = true
        }

        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { showSavedConfirmation = false }
            try? await Task.sleep(for: .milliseconds(300))
            dismiss()
        }
    }
}
