import SwiftUI

struct ShirtOffView: View {
    @State private var phase: Int = 0

    private let killedHabits = [
        "Hiding at the pool",
        "Shirt on at the beach",
        "Making excuses",
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 40) {
                VStack(spacing: 4) {
                    Text("You won't be")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)

                    Text("anxious")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(.white)

                    Text("taking your shirt off.")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                }
                .multilineTextAlignment(.center)
                .opacity(phase >= 1 ? 1 : 0)
                .animation(.easeIn(duration: 0.6), value: phase)

                if phase >= 3 {
                    VStack(spacing: 12) {
                        ForEach(killedHabits, id: \.self) { item in
                            Text(item)
                                .font(.callout.weight(.medium))
                                .foregroundStyle(AppTheme.destructive.opacity(0.4))
                                .strikethrough(true, color: AppTheme.destructive.opacity(0.6))
                        }
                    }
                    .transition(.opacity)
                }

                if phase >= 4 {
                    Text("Never again.")
                        .font(.title3.weight(.black))
                        .foregroundStyle(.white)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 28)

            Spacer()
        }
        .onAppear {
            Task {
                try? await Task.sleep(for: .milliseconds(400))
                withAnimation { phase = 1 }
                try? await Task.sleep(for: .seconds(1.0))
                withAnimation(.easeIn(duration: 0.5)) { phase = 3 }
                try? await Task.sleep(for: .milliseconds(900))
                withAnimation(.easeIn(duration: 0.4)) { phase = 4 }
            }
        }
    }
}
