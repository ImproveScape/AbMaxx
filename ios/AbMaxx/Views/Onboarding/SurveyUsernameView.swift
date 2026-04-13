import SwiftUI

struct SurveyUsernameView: View {
    @Binding var username: String
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Let's make this yours")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("What should we call you?")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 24)
            .padding(.horizontal, 24)

            Spacer().frame(height: 48)

            TextField("", text: $username, prompt: Text("Your name")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(AppTheme.muted))
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .focused($isFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
                .padding(.horizontal, 40)

            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isFocused = true
            }
        }
    }
}
