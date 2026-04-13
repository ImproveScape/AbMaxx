import SwiftUI
import PhotosUI
import UIKit

struct AddFoodView: View {
    @Bindable var viewModel: NutritionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMeal: MealType = .breakfast
    @State private var entryMode: EntryMode = .aiSearch
    @FocusState private var focusedField: ManualField?

    private let brandRed = Color(red: 0.95, green: 0.23, blue: 0.15)
    private let brandOrange = Color(red: 1.0, green: 0.45, blue: 0.18)

    private enum EntryMode: String, CaseIterable {
        case scan = "Scan Food"
        case aiSearch = "Nutrition Database"
        case quick = "Quick Add"
        case manual = "Manual"
    }

    private enum ManualField: Hashable {
        case name, calories, protein, carbs, fat, aiSearch
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                mealSelector
                modeSelector
                
                switch entryMode {
                case .scan:
                    foodScanSection
                case .aiSearch:
                    aiSearchSection
                case .quick:
                    foodSearchList
                case .manual:
                    manualEntryForm
                }
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        viewModel.resetManualEntry()
                        viewModel.aiSearchResults = []
                        viewModel.aiSearchText = ""
                        viewModel.aiErrorMessage = nil
                        dismiss()
                    }
                }
            }
        }
    }

    private var mealSelector: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                ForEach(MealType.allCases, id: \.self) { meal in
                    Button {
                        selectedMeal = meal
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: meal.icon)
                                .font(.caption2)
                            Text(meal.rawValue)
                                .font(.caption.bold())
                        }
                        .foregroundStyle(selectedMeal == meal ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background {
                            if selectedMeal == meal {
                                BrandRedGradientDeep().clipShape(Capsule())
                            } else {
                                Color(.tertiarySystemGroupedBackground).clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 10)
        }
        .contentMargins(.horizontal, 16)
        .scrollIndicators(.hidden)
    }

    private var modeSelector: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(EntryMode.allCases, id: \.rawValue) { mode in
                    let isSelected = entryMode == mode
                    Button {
                        withAnimation(.spring(duration: 0.25)) {
                            entryMode = mode
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: modeIcon(mode))
                                .font(.system(size: 11, weight: .semibold))
                            Text(mode.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(isSelected ? .white : .secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background {
                            if isSelected {
                                Capsule().fill(
                                    LinearGradient(
                                        colors: [brandRed, brandOrange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            } else {
                                Capsule().fill(Color(.tertiarySystemGroupedBackground))
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 12)
        }
        .contentMargins(.horizontal, 16)
        .scrollIndicators(.hidden)
    }

    private func modeIcon(_ mode: EntryMode) -> String {
        switch mode {
        case .scan: "camera.viewfinder"
        case .aiSearch: "text.book.closed.fill"
        case .quick: "magnifyingglass"
        case .manual: "square.and.pencil"
        }
    }

    // MARK: - Food Scan

    @State private var scanSelectedItem: PhotosPickerItem?
    @State private var scanCapturedImage: UIImage?
    @State private var showingScanCamera: Bool = false

    private var foodScanSection: some View {
        VStack(spacing: 0) {
            if viewModel.isAnalyzingImage {
                VStack(spacing: 20) {
                    if let img = scanCapturedImage {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 160, height: 160)
                            .clipShape(.rect(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.12), radius: 10, y: 3)
                            .overlay {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.35)
                            }
                    }
                    VStack(spacing: 10) {
                        ProgressView()
                            .controlSize(.large)
                            .tint(brandRed)
                        Text("Analyzing your food...")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Identifying items and estimating nutrition")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !viewModel.aiSearchResults.isEmpty && scanCapturedImage != nil {
                scanResultsView
            } else {
                scanCaptureView
            }
        }
        .onChange(of: scanSelectedItem) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    scanCapturedImage = uiImage
                    if let compressed = uiImage.jpegData(compressionQuality: 0.6) {
                        await viewModel.analyzeFoodImage(compressed)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingScanCamera, onDismiss: {
            guard let img = scanCapturedImage else { return }
            Task {
                if let compressed = img.jpegData(compressionQuality: 0.6) {
                    await viewModel.analyzeFoodImage(compressed)
                }
            }
        }) {
            FoodCameraCapture(capturedImage: $scanCapturedImage)
        }
    }

    private var scanCaptureView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 12)

                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(.tertiarySystemGroupedBackground))
                        .frame(height: 180)

                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(brandRed.opacity(0.1))
                                .frame(width: 64, height: 64)
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 30, weight: .medium))
                                .foregroundStyle(brandRed)
                        }
                        VStack(spacing: 4) {
                            Text("Scan Your Food")
                                .font(.system(size: 20, weight: .bold))
                            Text("Take a photo to get instant nutrition info")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)

                VStack(spacing: 10) {
                    Button {
                        showingScanCamera = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Take Photo")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .brandDeepGradientBackground(cornerRadius: 14)
                    }

                    PhotosPicker(selection: $scanSelectedItem, matching: .images) {
                        HStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Choose from Library")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(brandRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(brandRed.opacity(0.1))
                        .clipShape(.rect(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 16)

                if let error = viewModel.aiErrorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(Color.orange.opacity(0.08))
                    .clipShape(.rect(cornerRadius: 10))
                    .padding(.horizontal, 16)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private var scanResultsView: some View {
        VStack(spacing: 0) {
            if let img = scanCapturedImage {
                HStack(spacing: 12) {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(.rect(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.system(size: 14))
                            Text("\(viewModel.aiSearchResults.count) items found")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        let totalCal = viewModel.aiSearchResults.reduce(0) { $0 + $1.calories }
                        Text("~\(totalCal) cal total")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        scanCapturedImage = nil
                        scanSelectedItem = nil
                        viewModel.aiSearchResults = []
                        viewModel.aiErrorMessage = nil
                    } label: {
                        Text("Rescan")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(brandRed)
                    }
                }
                .padding(14)
                .background(Color(white: 0.1))
                .clipShape(.rect(cornerRadius: 14))
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 4)
            }

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.aiSearchResults.enumerated()), id: \.offset) { _, result in
                        Button {
                            viewModel.addFoodFromAIResult(result, mealType: selectedMeal)
                            dismiss()
                        } label: {
                            aiResultCard(result)
                        }
                    }

                    if viewModel.aiSearchResults.count > 1 {
                        Button {
                            for result in viewModel.aiSearchResults {
                                viewModel.addFoodFromAIResult(result, mealType: selectedMeal)
                            }
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 14))
                                Text("Add All Items")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .brandDeepGradientBackground(cornerRadius: 14)
                        }
                        .padding(.top, 6)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                .padding(.top, 6)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - AI Search

    private var aiSearchSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundStyle(brandRed)

                    TextField("Search any food...", text: $viewModel.aiSearchText)
                        .font(.system(size: 16))
                        .focused($focusedField, equals: .aiSearch)
                        .submitLabel(.search)
                        .onSubmit {
                            Task { await viewModel.searchFoodWithAI() }
                        }
                }
                .padding(12)
                .background(Color(white: 0.1))
                .clipShape(.rect(cornerRadius: 12))

                Button {
                    Task { await viewModel.searchFoodWithAI() }
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(brandRed)
                }
                .disabled(viewModel.aiSearchText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isAISearching)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            if viewModel.isAISearching {
                VStack(spacing: 14) {
                    ProgressView()
                        .controlSize(.large)
                        .tint(brandRed)
                    Text("Searching nutrition data...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.aiErrorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(40)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.aiSearchResults.isEmpty {
                aiSearchEmptyState
            } else {
                aiResultsList
            }
        }
    }

    private var aiSearchEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(brandRed.opacity(0.3))

            VStack(spacing: 6) {
                Text("Nutrition Database")
                    .font(.system(size: 18, weight: .semibold))
                Text("Search for any food and get\naccurate nutrition data instantly")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Try searching:")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)

                ForEach(["Chipotle chicken bowl", "Big Mac", "Açaí bowl with granola"], id: \.self) { suggestion in
                    Button {
                        viewModel.aiSearchText = suggestion
                        Task { await viewModel.searchFoodWithAI() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkle")
                                .font(.system(size: 10))
                            Text(suggestion)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(brandRed)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(brandRed.opacity(0.08))
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var aiResultsList: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(Array(viewModel.aiSearchResults.enumerated()), id: \.offset) { index, result in
                    Button {
                        viewModel.addFoodFromAIResult(result, mealType: selectedMeal)
                        dismiss()
                    } label: {
                        aiResultCard(result)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }

    private func aiResultCard(_ result: NutritionLookupResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(result.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(result.servingSize)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(result.calories)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(brandRed)
                    Text("cal")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                macroChip("P", value: result.protein, color: .blue)
                macroChip("C", value: result.carbs, color: brandOrange)
                macroChip("F", value: result.fat, color: .purple)
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(brandRed)
            }
        }
        .padding(16)
        .background(Color(white: 0.1))
        .clipShape(.rect(cornerRadius: 14))
    }

    private func macroChip(_ label: String, value: Double, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(color)
            Text("\(Int(value))g")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }

    // MARK: - Quick Search

    private var foodSearchList: some View {
        List {
            ForEach(viewModel.filteredFoods) { food in
                Button {
                    viewModel.addFoodEntry(food, mealType: selectedMeal)
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(food.name)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Text("P: \(Int(food.protein))g  C: \(Int(food.carbs))g  F: \(Int(food.fat))g")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(food.calories) cal")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $viewModel.searchText, prompt: "Search foods...")
    }

    // MARK: - Manual Entry

    private var manualEntryForm: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Food Name")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    TextField("e.g. Chicken & Rice", text: $viewModel.manualName)
                        .font(.body)
                        .padding(11)
                        .background(Color(white: 0.1))
                        .clipShape(.rect(cornerRadius: 10))
                        .focused($focusedField, equals: .name)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Calories")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    HStack(spacing: 8) {
                        TextField("0", text: $viewModel.manualCalories)
                            .font(.title3.bold())
                            .keyboardType(.numberPad)
                            .padding(11)
                            .background(Color(white: 0.1))
                            .clipShape(.rect(cornerRadius: 10))
                            .focused($focusedField, equals: .calories)
                        Text("cal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if viewModel.manualCalories.isEmpty && hasAnyMacro {
                        Text("Will auto-calculate from macros")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Macros (optional)")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    HStack(spacing: 8) {
                        macroField(label: "Protein", text: $viewModel.manualProtein, color: .blue, field: .protein)
                        macroField(label: "Carbs", text: $viewModel.manualCarbs, color: .orange, field: .carbs)
                        macroField(label: "Fat", text: $viewModel.manualFat, color: .purple, field: .fat)
                    }
                }

                Spacer().frame(height: 6)

                Button {
                    viewModel.addManualEntry(mealType: selectedMeal)
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Entry")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(!canAddManualEntry)
            }
            .padding(16)
        }
        .background(Color.black)
        .onAppear {
            focusedField = .name
        }
    }

    private func macroField(label: String, text: Binding<String>, color: Color, field: ManualField) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2.bold())
                .foregroundStyle(color)
            TextField("0", text: text)
                .font(.subheadline.bold())
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .padding(9)
                .background(color.opacity(0.07))
                .clipShape(.rect(cornerRadius: 10))
                .focused($focusedField, equals: field)
            Text("g")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
    }

    private var hasAnyMacro: Bool {
        (Double(viewModel.manualProtein) ?? 0) > 0 ||
        (Double(viewModel.manualCarbs) ?? 0) > 0 ||
        (Double(viewModel.manualFat) ?? 0) > 0
    }

    private var canAddManualEntry: Bool {
        let cal = Int(viewModel.manualCalories) ?? 0
        return cal > 0 || hasAnyMacro
    }
}
