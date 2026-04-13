import SwiftUI
import PhotosUI
import UIKit

struct AddFoodView: View {
    @Bindable var viewModel: NutritionViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var entryMode: EntryMode = .aiSearch
    @FocusState private var focusedField: ManualField?

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
                modeSelector
                switch entryMode {
                case .scan: foodScanSection
                case .aiSearch: aiSearchSection
                case .quick: foodSearchList
                case .manual: manualEntryForm
                }
            }
            .background(AppTheme.background)
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
            .preferredColorScheme(.dark)
        }
    }

    private var modeSelector: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(EntryMode.allCases, id: \.rawValue) { mode in
                    let isSelected = entryMode == mode
                    Button {
                        withAnimation(.spring(duration: 0.25)) { entryMode = mode }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: modeIcon(mode)).font(.system(size: 11, weight: .semibold))
                            Text(mode.rawValue).font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(isSelected ? .white : AppTheme.secondaryText)
                        .padding(.horizontal, 14).padding(.vertical, 9)
                        .background {
                            if isSelected {
                                Capsule().fill(AppTheme.primaryAccent)
                            } else {
                                Capsule().fill(AppTheme.cardSurface)
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

    @State private var scanSelectedItem: PhotosPickerItem?
    @State private var scanCapturedImage: UIImage?
    @State private var showingScanCamera: Bool = false

    private var foodScanSection: some View {
        VStack(spacing: 0) {
            if viewModel.isAnalyzingImage {
                VStack(spacing: 20) {
                    if let img = scanCapturedImage {
                        Image(uiImage: img).resizable().aspectRatio(contentMode: .fill)
                            .frame(width: 160, height: 160).clipShape(.rect(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.12), radius: 10, y: 3)
                            .overlay { RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial).opacity(0.35) }
                    }
                    VStack(spacing: 10) {
                        ProgressView().controlSize(.large).tint(AppTheme.primaryAccent)
                        Text("Analyzing your food...").font(.system(size: 16, weight: .semibold)).foregroundStyle(AppTheme.primaryText)
                        Text("Identifying items and estimating nutrition").font(.system(size: 13)).foregroundStyle(AppTheme.secondaryText)
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
                    RoundedRectangle(cornerRadius: 24).fill(AppTheme.cardSurface).frame(height: 180)
                        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(AppTheme.border, lineWidth: 0.5))
                    VStack(spacing: 14) {
                        ZStack {
                            Circle().fill(AppTheme.primaryAccent.opacity(0.1)).frame(width: 64, height: 64)
                            Image(systemName: "camera.viewfinder").font(.system(size: 30, weight: .medium)).foregroundStyle(AppTheme.primaryAccent)
                        }
                        VStack(spacing: 4) {
                            Text("Scan Your Food").font(.system(size: 20, weight: .bold)).foregroundStyle(AppTheme.primaryText)
                            Text("Take a photo to get instant nutrition info").font(.system(size: 13)).foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                }
                .padding(.horizontal, 16)

                VStack(spacing: 10) {
                    Button { showingScanCamera = true } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill").font(.system(size: 15, weight: .semibold))
                            Text("Take Photo").font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 15)
                        .background(AppTheme.primaryAccent, in: .rect(cornerRadius: 14))
                    }
                    PhotosPicker(selection: $scanSelectedItem, matching: .images) {
                        HStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle.angled").font(.system(size: 15, weight: .semibold))
                            Text("Choose from Library").font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(AppTheme.primaryAccent).frame(maxWidth: .infinity).padding(.vertical, 15)
                        .background(AppTheme.primaryAccent.opacity(0.1)).clipShape(.rect(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 16)

                if let error = viewModel.aiErrorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(AppTheme.warning)
                        Text(error).font(.system(size: 13)).foregroundStyle(AppTheme.secondaryText)
                    }
                    .padding(12).frame(maxWidth: .infinity).background(AppTheme.warning.opacity(0.08)).clipShape(.rect(cornerRadius: 10))
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
                    Image(uiImage: img).resizable().aspectRatio(contentMode: .fill).frame(width: 50, height: 50).clipShape(.rect(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(AppTheme.success).font(.system(size: 14))
                            Text("\(viewModel.aiSearchResults.count) items found").font(.system(size: 14, weight: .semibold)).foregroundStyle(AppTheme.primaryText)
                        }
                        let totalCal = viewModel.aiSearchResults.reduce(0) { $0 + $1.calories }
                        Text("~\(totalCal) cal total").font(.system(size: 12)).foregroundStyle(AppTheme.secondaryText)
                    }
                    Spacer()
                    Button {
                        scanCapturedImage = nil; scanSelectedItem = nil
                        viewModel.aiSearchResults = []; viewModel.aiErrorMessage = nil
                    } label: { Text("Rescan").font(.system(size: 13, weight: .semibold)).foregroundStyle(AppTheme.primaryAccent) }
                }
                .padding(14).background(AppTheme.cardSurface).clipShape(.rect(cornerRadius: 14))
                .padding(.horizontal, 16).padding(.top, 6).padding(.bottom, 4)
            }
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(viewModel.aiSearchResults) { result in
                        Button { viewModel.addFoodFromAIResult(result, mealType: .lunch); dismiss() } label: { aiResultCard(result) }
                    }
                    if viewModel.aiSearchResults.count > 1 {
                        Button {
                            for result in viewModel.aiSearchResults { viewModel.addFoodFromAIResult(result, mealType: .lunch) }
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill").font(.system(size: 14))
                                Text("Add All Items").font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(AppTheme.primaryAccent, in: .rect(cornerRadius: 14))
                        }
                        .padding(.top, 6)
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 24).padding(.top, 6)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var aiSearchSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles").font(.system(size: 14)).foregroundStyle(AppTheme.primaryAccent)
                    TextField("Search any food...", text: $viewModel.aiSearchText)
                        .font(.system(size: 16)).focused($focusedField, equals: .aiSearch)
                        .submitLabel(.search)
                        .onSubmit { Task { await viewModel.searchFoodWithAI() } }
                }
                .padding(12).background(AppTheme.cardSurface).clipShape(.rect(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(AppTheme.border, lineWidth: 0.5))

                Button { Task { await viewModel.searchFoodWithAI() } } label: {
                    Image(systemName: "arrow.right.circle.fill").font(.system(size: 32)).foregroundStyle(AppTheme.primaryAccent)
                }
                .disabled(viewModel.aiSearchText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isAISearching)
            }
            .padding(.horizontal, 16).padding(.bottom, 12)

            if viewModel.isAISearching {
                VStack(spacing: 14) {
                    ProgressView().controlSize(.large).tint(AppTheme.primaryAccent)
                    Text("Searching nutrition data...").font(.system(size: 14, weight: .medium)).foregroundStyle(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.aiErrorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 32)).foregroundStyle(AppTheme.warning)
                    Text(error).font(.system(size: 14)).foregroundStyle(AppTheme.secondaryText).multilineTextAlignment(.center)
                }
                .padding(40).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.aiSearchResults.isEmpty {
                aiSearchEmptyState
            } else {
                aiResultsList
            }
        }
    }

    private var aiSearchEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle.fill").font(.system(size: 48)).foregroundStyle(AppTheme.primaryAccent.opacity(0.3))
            VStack(spacing: 6) {
                Text("Nutrition Database").font(.system(size: 18, weight: .semibold)).foregroundStyle(AppTheme.primaryText)
                Text("Search for any food and get\naccurate nutrition data instantly").font(.system(size: 14)).foregroundStyle(AppTheme.secondaryText).multilineTextAlignment(.center)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Try searching:").font(.system(size: 12, weight: .semibold)).foregroundStyle(AppTheme.muted).textCase(.uppercase)
                ForEach(["Chipotle chicken bowl", "Big Mac", "Açaí bowl with granola"], id: \.self) { suggestion in
                    Button {
                        viewModel.aiSearchText = suggestion
                        Task { await viewModel.searchFoodWithAI() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkle").font(.system(size: 10))
                            Text(suggestion).font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(AppTheme.primaryAccent).padding(.horizontal, 14).padding(.vertical, 8)
                        .background(AppTheme.primaryAccent.opacity(0.08)).clipShape(Capsule())
                    }
                }
            }
        }
        .padding(32).frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var aiResultsList: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(viewModel.aiSearchResults) { result in
                    Button { viewModel.addFoodFromAIResult(result, mealType: .lunch); dismiss() } label: { aiResultCard(result) }
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 20)
        }
    }

    private func aiResultCard(_ result: NutritionLookupResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(result.name).font(.system(size: 16, weight: .semibold)).foregroundStyle(AppTheme.primaryText).lineLimit(2).multilineTextAlignment(.leading)
                    Text(result.servingSize).font(.system(size: 12, weight: .medium)).foregroundStyle(AppTheme.muted)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(result.calories)").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.primaryAccent)
                    Text("cal").font(.system(size: 11, weight: .medium)).foregroundStyle(AppTheme.secondaryText)
                }
            }
            HStack(spacing: 12) {
                macroChip("P", value: result.protein, color: AppTheme.primaryAccent)
                macroChip("C", value: result.carbs, color: AppTheme.success)
                macroChip("F", value: result.fat, color: AppTheme.warning)
                Spacer()
                Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundStyle(AppTheme.primaryAccent)
            }
        }
        .padding(16).background(AppTheme.cardSurface).clipShape(.rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(AppTheme.border, lineWidth: 0.5))
    }

    private func macroChip(_ label: String, value: Double, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(label).font(.system(size: 10, weight: .bold)).foregroundStyle(color)
            Text("\(Int(value))g").font(.system(size: 12, weight: .semibold)).foregroundStyle(AppTheme.primaryText)
        }
        .padding(.horizontal, 8).padding(.vertical, 4).background(color.opacity(0.1)).clipShape(Capsule())
    }

    private var foodSearchList: some View {
        List {
            ForEach(viewModel.filteredFoods) { food in
                Button {
                    viewModel.addFoodEntry(food, mealType: .lunch)
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(food.name).font(.subheadline).foregroundStyle(AppTheme.primaryText)
                            Text("P: \(Int(food.protein))g  C: \(Int(food.carbs))g  F: \(Int(food.fat))g").font(.caption2).foregroundStyle(AppTheme.secondaryText)
                        }
                        Spacer()
                        Text("\(food.calories) cal").font(.caption.bold()).foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $viewModel.searchText, prompt: "Search foods...")
    }

    private var manualEntryForm: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Food Name").font(.caption2.bold()).foregroundStyle(AppTheme.secondaryText).textCase(.uppercase)
                    TextField("e.g. Chicken & Rice", text: $viewModel.manualName)
                        .font(.body).padding(11).background(AppTheme.cardSurface).clipShape(.rect(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(AppTheme.border, lineWidth: 0.5))
                        .focused($focusedField, equals: .name)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Calories").font(.caption2.bold()).foregroundStyle(AppTheme.secondaryText).textCase(.uppercase)
                    HStack(spacing: 8) {
                        TextField("0", text: $viewModel.manualCalories).font(.title3.bold()).keyboardType(.numberPad)
                            .padding(11).background(AppTheme.cardSurface).clipShape(.rect(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(AppTheme.border, lineWidth: 0.5))
                            .focused($focusedField, equals: .calories)
                        Text("cal").font(.caption).foregroundStyle(AppTheme.secondaryText)
                    }
                    if viewModel.manualCalories.isEmpty && hasAnyMacro {
                        Text("Will auto-calculate from macros").font(.caption2).foregroundStyle(AppTheme.muted)
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Macros (optional)").font(.caption2.bold()).foregroundStyle(AppTheme.secondaryText).textCase(.uppercase)
                    HStack(spacing: 8) {
                        macroField(label: "Protein", text: $viewModel.manualProtein, color: AppTheme.primaryAccent, field: .protein)
                        macroField(label: "Carbs", text: $viewModel.manualCarbs, color: AppTheme.success, field: .carbs)
                        macroField(label: "Fat", text: $viewModel.manualFat, color: AppTheme.warning, field: .fat)
                    }
                }
                Spacer().frame(height: 6)
                Button {
                    viewModel.addManualEntry(mealType: .lunch)
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Entry").fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 13)
                    .background(AppTheme.primaryAccent, in: .rect(cornerRadius: 14))
                }
                .disabled(!canAddManualEntry)
                .opacity(canAddManualEntry ? 1.0 : 0.5)
            }
            .padding(16)
        }
        .background(AppTheme.background)
        .onAppear { focusedField = .name }
    }

    private func macroField(label: String, text: Binding<String>, color: Color, field: ManualField) -> some View {
        VStack(spacing: 4) {
            Text(label).font(.caption2.bold()).foregroundStyle(color)
            TextField("0", text: text).font(.subheadline.bold()).keyboardType(.decimalPad).multilineTextAlignment(.center)
                .padding(9).background(color.opacity(0.07)).clipShape(.rect(cornerRadius: 10)).focused($focusedField, equals: field)
            Text("g").font(.system(size: 10)).foregroundStyle(AppTheme.muted)
        }
    }

    private var hasAnyMacro: Bool {
        (Double(viewModel.manualProtein) ?? 0) > 0 || (Double(viewModel.manualCarbs) ?? 0) > 0 || (Double(viewModel.manualFat) ?? 0) > 0
    }

    private var canAddManualEntry: Bool {
        let cal = Int(viewModel.manualCalories) ?? 0
        return cal > 0 || hasAnyMacro
    }
}

struct FoodCameraCapture: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        #if targetEnvironment(simulator)
        picker.sourceType = .photoLibrary
        #else
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        #endif
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: FoodCameraCapture
        init(_ parent: FoodCameraCapture) { self.parent = parent }

        nonisolated func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = info[.originalImage] as? UIImage
            Task { @MainActor in parent.capturedImage = image; parent.dismiss() }
        }

        nonisolated func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            Task { @MainActor in parent.dismiss() }
        }
    }
}
