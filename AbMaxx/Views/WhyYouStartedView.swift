import SwiftUI

struct WhyYouStartedView: View {
    @Bindable var vm: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var newReason: String = ""
    @State private var isAddingReason: Bool = false
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.bottom, 8)

                ScrollView {
                    VStack(spacing: 20) {
                        Text("Remind yourself why you started. Listing specific reasons helps you anchor when things get tough.")
                            .font(.body)
                            .foregroundStyle(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                            .padding(.bottom, 8)

                        VStack(spacing: 14) {
                            ForEach(Array(vm.whyReasons.enumerated()), id: \.offset) { index, reason in
                                reasonRow(reason, index: index)
                            }
                        }
                        .padding(.horizontal, 16)

                        if isAddingReason {
                            addReasonField
                                .padding(.horizontal, 16)
                        }

                        Button {
                            if isAddingReason && !newReason.trimmingCharacters(in: .whitespaces).isEmpty {
                                vm.whyReasons.append(newReason.trimmingCharacters(in: .whitespaces))
                                vm.saveReasons()
                                newReason = ""
                                isFieldFocused = true
                            } else {
                                isAddingReason = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isFieldFocused = true
                                }
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(AppTheme.primaryAccent)
                                Text("Add Another Reason")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(AppTheme.cardSurface)
                            .clipShape(.rect(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(AppTheme.border, lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 16)

                        Color.clear.frame(height: 40)
                    }
                    .padding(.top, 8)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            if vm.whyReasons.isEmpty {
                vm.whyReasons.append(vm.profile.goal.rawValue)
                vm.saveReasons()
            }
        }
    }

    private var header: some View {
        ZStack {
            Text("Why You Started")
                .font(.title3.bold())
                .foregroundStyle(.white)

            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(AppTheme.cardSurface)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(AppTheme.border, lineWidth: 1))
                }
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func reasonRow(_ reason: String, index: Int) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.primaryAccent)
                    .frame(width: 30, height: 30)
                Image(systemName: "checkmark")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }

            Text(reason)
                .font(.body.weight(.medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                withAnimation(.spring(duration: 0.3)) {
                    vm.whyReasons.remove(at: index)
                    vm.saveReasons()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.bold())
                    .foregroundStyle(AppTheme.muted)
                    .frame(width: 28, height: 28)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppTheme.primaryAccent.opacity(0.3), lineWidth: 1)
        )
    }

    private var addReasonField: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .strokeBorder(AppTheme.border, lineWidth: 1.5)
                    .frame(width: 30, height: 30)
            }

            TextField("", text: $newReason, prompt: Text("Enter your reason...").foregroundStyle(AppTheme.muted))
                .font(.body.weight(.medium))
                .foregroundStyle(.white)
                .focused($isFieldFocused)
                .onSubmit {
                    guard !newReason.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    vm.whyReasons.append(newReason.trimmingCharacters(in: .whitespaces))
                    vm.saveReasons()
                    newReason = ""
                    isAddingReason = false
                }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppTheme.border, lineWidth: 1)
        )
    }
}
