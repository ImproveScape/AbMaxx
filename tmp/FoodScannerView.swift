import SwiftUI
import PhotosUI
import AVFoundation
import UIKit

struct FoodScannerView: View {
    @Bindable var viewModel: NutritionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var showingCamera: Bool = false
    @State private var selectedMeal: MealType = .breakfast
    @State private var appeared: Bool = false

    private let brandRed = Color(red: 0.95, green: 0.23, blue: 0.15)
    private let brandOrange = Color(red: 1.0, green: 0.45, blue: 0.18)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                mealSelector

                if viewModel.isAnalyzingImage {
                    analyzingState
                } else if !viewModel.aiSearchResults.isEmpty && capturedImage != nil {
                    resultsState
                } else {
                    captureState
                }
            }
            .background(Color.black)
            .navigationTitle("Scan Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        viewModel.aiSearchResults = []
                        viewModel.aiErrorMessage = nil
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedItem) { _, newValue in
                guard let newValue else { return }
                Task {
                    if let data = try? await newValue.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        capturedImage = uiImage
                        await analyzeImage(uiImage)
                    }
                }
            }
            .fullScreenCover(isPresented: $showingCamera, onDismiss: {
                guard let img = capturedImage else { return }
                Task { await analyzeImage(img) }
            }) {
                FuelCameraView(capturedImage: $capturedImage)
            }
            .task {
                withAnimation(.spring(response: 0.5)) {
                    appeared = true
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

    private var captureState: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer().frame(height: 20)

                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color(.tertiarySystemGroupedBackground))
                        .frame(height: 220)

                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(brandRed.opacity(0.1))
                                .frame(width: 80, height: 80)

                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 36, weight: .medium))
                                .foregroundStyle(brandRed)
                        }

                        VStack(spacing: 6) {
                            Text("Scan Your Food")
                                .font(.system(size: 22, weight: .bold))
                            Text("Take a photo or choose from your library\nto instantly get nutrition info")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                VStack(spacing: 12) {
                    Button {
                        showingCamera = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Take Photo")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .brandDeepGradientBackground(cornerRadius: 16)
                    }

                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        HStack(spacing: 10) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Choose from Library")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundStyle(brandRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(brandRed.opacity(0.1))
                        .clipShape(.rect(cornerRadius: 16))
                    }
                }
                .padding(.horizontal, 20)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 14)
                .animation(.spring(response: 0.5).delay(0.1), value: appeared)

                if let error = viewModel.aiErrorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(Color.orange.opacity(0.08))
                    .clipShape(.rect(cornerRadius: 12))
                    .padding(.horizontal, 20)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Tips for best results")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)
                        .padding(.horizontal, 20)

                    VStack(spacing: 8) {
                        tipRow(icon: "light.max", text: "Good lighting helps accuracy")
                        tipRow(icon: "arrow.up.left.and.arrow.down.right", text: "Get all food items in frame")
                        tipRow(icon: "eye", text: "Show the food clearly, no obstructions")
                    }
                    .padding(.horizontal, 20)
                }
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5).delay(0.2), value: appeared)

                Spacer()
            }
        }
        .scrollIndicators(.hidden)
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(brandRed.opacity(0.7))
                .frame(width: 28, height: 28)
                .background(brandRed.opacity(0.08))
                .clipShape(.rect(cornerRadius: 8))

            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
    }

    private var analyzingState: some View {
        VStack(spacing: 24) {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 200)
                    .clipShape(.rect(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .opacity(0.4)
                    }
            }

            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                    .tint(brandRed)

                Text("Analyzing your food...")
                    .font(.system(size: 17, weight: .semibold))

                Text("Identifying items and estimating nutrition")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var resultsState: some View {
        VStack(spacing: 0) {
            if let image = capturedImage {
                HStack(spacing: 14) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(.rect(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.system(size: 15))
                            Text("\(viewModel.aiSearchResults.count) items found")
                                .font(.system(size: 15, weight: .semibold))
                        }

                        let totalCal = viewModel.aiSearchResults.reduce(0) { $0 + $1.calories }
                        Text("~\(totalCal) calories total")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        resetScan()
                    } label: {
                        Text("Rescan")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(brandRed)
                    }
                }
                .padding(16)
                .background(Color(white: 0.1))
                .clipShape(.rect(cornerRadius: 16))
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)
            }

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.aiSearchResults.enumerated()), id: \.offset) { _, result in
                        Button {
                            viewModel.addFoodFromAIResult(result, mealType: selectedMeal)
                            dismiss()
                        } label: {
                            foodResultCard(result)
                        }
                    }

                    Button {
                        for result in viewModel.aiSearchResults {
                            viewModel.addFoodFromAIResult(result, mealType: selectedMeal)
                        }
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 15))
                            Text("Add All Items")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .brandDeepGradientBackground(cornerRadius: 14)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func foodResultCard(_ result: NutritionLookupResult) -> some View {
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

    private func analyzeImage(_ image: UIImage) async {
        guard let compressed = image.jpegData(compressionQuality: 0.6) else { return }
        await viewModel.analyzeFoodImage(compressed)
    }

    private func resetScan() {
        capturedImage = nil
        selectedItem = nil
        viewModel.aiSearchResults = []
        viewModel.aiErrorMessage = nil
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

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: FoodCameraCapture

        init(_ parent: FoodCameraCapture) {
            self.parent = parent
        }

        nonisolated func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = info[.originalImage] as? UIImage
            Task { @MainActor in
                parent.capturedImage = image
                parent.dismiss()
            }
        }

        nonisolated func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            Task { @MainActor in
                parent.dismiss()
            }
        }
    }
}
