import SwiftUI

struct CoachAbsChatView: View {
    @Bindable var vm: AppViewModel
    @State private var messages: [CoachMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @Environment(\.dismiss) private var dismiss

    private var scanContext: String {
        guard let scan = vm.latestScan else { return "No scan data available yet." }
        return """
        Overall Score: \(scan.overallScore), \
        Definition: \(scan.definition), Symmetry: \(scan.symmetry), \
        Thickness: \(scan.thickness), Obliques: \(scan.obliques), \
        Frame: \(scan.frame), Aesthetic: \(scan.aesthetic), \
        Abs Structure: \(scan.absStructure.rawValue), \
        Genetic Potential: \(scan.geneticPotential), \
        Est. Body Fat: \(String(format: "%.1f", scan.estimatedBodyFat))%
        """
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Divider().overlay(AppTheme.border)

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }

                            if isLoading {
                                HStack(spacing: 6) {
                                    TypingIndicator()
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .id("loading")
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    .scrollIndicators(.hidden)
                    .onChange(of: messages.count) { _, _ in
                        withAnimation {
                            if let lastID = messages.last?.id {
                                proxy.scrollTo(lastID, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: isLoading) { _, newValue in
                        if newValue {
                            withAnimation {
                                proxy.scrollTo("loading", anchor: .bottom)
                            }
                        }
                    }
                }

                Divider().overlay(AppTheme.border)
                inputBar
            }
        }
        .onAppear {
            if messages.isEmpty {
                let greeting = CoachMessage(
                    text: "Hey! I'm Coach Abs — your personal core training coach. Ask me anything about your abs, training, nutrition, or how to improve your score. 💪",
                    isUser: false
                )
                messages.append(greeting)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }

            ZStack {
                Circle()
                    .fill(AppTheme.primaryAccent)
                    .frame(width: 36, height: 36)
                Image(systemName: "bubble.left.and.text.bubble.right.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("Coach Abs")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Text("Your AI fitness coach")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(AppTheme.muted)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppTheme.cardSurface)
    }

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask Coach Abs...", text: $inputText, axis: .vertical)
                .font(.subheadline)
                .foregroundStyle(.white)
                .lineLimit(1...4)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AppTheme.cardSurfaceElevated)
                .clipShape(.rect(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(AppTheme.border, lineWidth: 1)
                )

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppTheme.muted : AppTheme.primaryAccent)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppTheme.cardSurface)
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let userMessage = CoachMessage(text: text, isUser: true)
        messages.append(userMessage)
        inputText = ""
        isLoading = true

        Task {
            do {
                let response = try await CoachAbsService.shared.sendMessage(
                    messages: messages.filter { $0.text != messages.first?.text || $0.isUser },
                    scanContext: scanContext
                )
                let botMessage = CoachMessage(text: response, isUser: false)
                messages.append(botMessage)
            } catch {
                let errorMessage = CoachMessage(
                    text: "Sorry, I couldn't connect right now. Try again in a moment.",
                    isUser: false
                )
                messages.append(errorMessage)
            }
            isLoading = false
        }
    }
}

struct ChatBubble: View {
    let message: CoachMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 60) }

            if !message.isUser {
                ZStack {
                    Circle()
                        .fill(AppTheme.primaryAccent)
                        .frame(width: 28, height: 28)
                    Image(systemName: "bubble.left.and.text.bubble.right.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }

            Text(message.text)
                .font(.subheadline)
                .foregroundStyle(message.isUser ? .white : AppTheme.secondaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    message.isUser
                        ? AppTheme.primaryAccent
                        : AppTheme.cardSurfaceElevated
                )
                .clipShape(.rect(cornerRadius: 16))
                .overlay(
                    Group {
                        if !message.isUser {
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(AppTheme.border.opacity(0.6), lineWidth: 1)
                        }
                    }
                )

            if !message.isUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 16)
    }
}

struct TypingIndicator: View {
    @State private var phase: Int = 0

    var body: some View {
        HStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(AppTheme.primaryAccent)
                    .frame(width: 28, height: 28)
                Image(systemName: "bubble.left.and.text.bubble.right.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
            }

            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(AppTheme.muted)
                        .frame(width: 6, height: 6)
                        .opacity(phase == i ? 1.0 : 0.3)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(AppTheme.cardSurfaceElevated)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppTheme.border.opacity(0.6), lineWidth: 1)
            )
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    phase = (phase + 1) % 3
                }
            }
        }
    }
}
