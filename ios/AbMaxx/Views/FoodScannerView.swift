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

    @State private var appeared: Bool = false

    private let brandAccent = AppTheme.primaryAccent

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isAnalyzingImage {
                    analyzingState
                } else if !viewModel.aiSearchResults.isEmpty && capturedImage != nil {
                    resultsState
                } else {
                    captureState
                }
            }
            .background(BackgroundView().ignoresSafeArea())
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
                withAnimation(.spring(response: 0.5)) { appeared = true }
            }
        }
    }

    private var captureState: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer().frame(height: 20)
                ZStack {
                    RoundedRectangle(cornerRadius: 28).fill(Color(.tertiarySystemGroupedBackground)).frame(height: 220)
                    VStack(spacing: 16) {
                        ZStack {
                            Circle().fill(brandAccent.opacity(0.1)).frame(width: 80, height: 80)
                            Image(systemName: "camera.viewfinder").font(.system(size: 36, weight: .medium)).foregroundStyle(brandAccent)
                        }
                        VStack(spacing: 6) {
                            Text("Scan Your Food").font(.system(size: 22, weight: .bold))
                            Text("Take a photo or choose from your library\nto instantly get nutrition info")
                                .font(.system(size: 14)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 20)

                VStack(spacing: 12) {
                    Button { showingCamera = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "camera.fill").font(.system(size: 16, weight: .semibold))
                            Text("Take Photo").font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                        .brandDeepGradientBackground(cornerRadius: 16)
                    }
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        HStack(spacing: 10) {
                            Image(systemName: "photo.on.rectangle.angled").font(.system(size: 16, weight: .semibold))
                            Text("Choose from Library").font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundStyle(brandAccent).frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(brandAccent.opacity(0.1)).clipShape(.rect(cornerRadius: 16))
                    }
                }
                .padding(.horizontal, 20)
                .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 14)
                .animation(.spring(response: 0.5).delay(0.1), value: appeared)

                if let error = viewModel.aiErrorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(AppTheme.warning)
                        Text(error).font(.system(size: 13)).foregroundStyle(.secondary)
                    }
                    .padding(14).frame(maxWidth: .infinity).background(AppTheme.warning.opacity(0.08)).clipShape(.rect(cornerRadius: 12))
                    .padding(.horizontal, 20)
                }

                Spacer()
            }
        }
        .scrollIndicators(.hidden)
    }

    private var analyzingState: some View {
        VStack(spacing: 24) {
            if let image = capturedImage {
                Image(uiImage: image).resizable().aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 200).clipShape(.rect(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
                    .overlay { RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial).opacity(0.4) }
            }
            VStack(spacing: 12) {
                ProgressView().controlSize(.large).tint(brandAccent)
                Text("Analyzing your food...").font(.system(size: 17, weight: .semibold))
                Text("Identifying items and estimating nutrition").font(.system(size: 14)).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var resultsState: some View {
        VStack(spacing: 0) {
            if let image = capturedImage {
                HStack(spacing: 14) {
                    Image(uiImage: image).resizable().aspectRatio(contentMode: .fill).frame(width: 60, height: 60).clipShape(.rect(cornerRadius: 12))
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.system(size: 15))
                            Text("\(viewModel.aiSearchResults.count) items found").font(.system(size: 15, weight: .semibold))
                        }
                        let totalCal = viewModel.aiSearchResults.reduce(0) { $0 + $1.calories }
                        Text("~\(totalCal) calories total").font(.system(size: 13)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { resetScan() } label: { Text("Rescan").font(.system(size: 13, weight: .semibold)).foregroundStyle(brandAccent) }
                }
                .padding(16).background(Color(white: 0.1)).clipShape(.rect(cornerRadius: 16))
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 4)
            }
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(viewModel.aiSearchResults) { result in
                        Button { viewModel.addFoodFromAIResult(result, mealType: .lunch); dismiss() } label: { foodResultCard(result) }
                    }
                    Button {
                        for result in viewModel.aiSearchResults { viewModel.addFoodFromAIResult(result, mealType: .lunch) }
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill").font(.system(size: 15))
                            Text("Add All Items").font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 15)
                        .brandDeepGradientBackground(cornerRadius: 14)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 16).padding(.bottom, 30).padding(.top, 8)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func foodResultCard(_ result: NutritionLookupResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(result.name).font(.system(size: 16, weight: .semibold)).foregroundStyle(.primary).lineLimit(2).multilineTextAlignment(.leading)
                    Text(result.servingSize).font(.system(size: 12, weight: .medium)).foregroundStyle(.tertiary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(result.calories)").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(brandAccent)
                    Text("cal").font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 12) {
                scanMacroChip("P", value: result.protein, color: .blue)
                scanMacroChip("C", value: result.carbs, color: AppTheme.success)
                scanMacroChip("F", value: result.fat, color: .purple)
                Spacer()
                Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundStyle(brandAccent)
            }
        }
        .padding(16).background(Color(white: 0.1)).clipShape(.rect(cornerRadius: 14))
    }

    private func scanMacroChip(_ label: String, value: Double, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(label).font(.system(size: 10, weight: .bold)).foregroundStyle(color)
            Text("\(Int(value))g").font(.system(size: 12, weight: .semibold)).foregroundStyle(.primary)
        }
        .padding(.horizontal, 8).padding(.vertical, 4).background(color.opacity(0.1)).clipShape(Capsule())
    }

    private func analyzeImage(_ image: UIImage) async {
        guard let compressed = image.jpegData(compressionQuality: 0.6) else { return }
        await viewModel.analyzeFoodImage(compressed)
    }

    private func resetScan() {
        capturedImage = nil; selectedItem = nil
        viewModel.aiSearchResults = []; viewModel.aiErrorMessage = nil
    }
}
