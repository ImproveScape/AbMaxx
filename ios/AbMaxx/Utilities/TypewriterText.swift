import SwiftUI

struct TypewriterText: View {
    let fullText: String
    let font: Font
    let color: Color
    let speed: Double
    let startDelay: Double

    @State private var visibleCount: Int = 0
    @State private var started: Bool = false

    init(
        _ text: String,
        font: Font = .body,
        color: Color = .white,
        speed: Double = 0.04,
        startDelay: Double = 0
    ) {
        self.fullText = text
        self.font = font
        self.color = color
        self.speed = speed
        self.startDelay = startDelay
    }

    var body: some View {
        Text(displayText)
            .font(font)
            .foregroundStyle(color)
            .onAppear {
                guard !started else { return }
                started = true
                animate()
            }
    }

    private var displayText: AttributedString {
        var visible = AttributedString(String(fullText.prefix(visibleCount)))
        let remaining = String(fullText.dropFirst(visibleCount))
        var hidden = AttributedString(remaining)
        hidden.foregroundColor = .clear
        visible.append(hidden)
        return visible
    }

    private func animate() {
        let chars = Array(fullText)
        Task {
            if startDelay > 0 {
                try? await Task.sleep(for: .milliseconds(Int(startDelay * 1000)))
            }
            for i in 1...chars.count {
                visibleCount = i
                let char = chars[i - 1]
                let pause: Int
                if char == "\n" {
                    pause = Int(speed * 1000 * 4)
                } else if char == "." || char == "!" || char == "?" {
                    pause = Int(speed * 1000 * 6)
                } else if char == "," || char == "—" || char == ":" {
                    pause = Int(speed * 1000 * 3)
                } else {
                    pause = Int(speed * 1000)
                }
                try? await Task.sleep(for: .milliseconds(pause))
            }
        }
    }
}
