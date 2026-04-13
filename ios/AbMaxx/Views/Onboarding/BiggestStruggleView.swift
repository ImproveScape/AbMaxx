import SwiftUI

struct BiggestStruggleView: View {
    @Binding var selectedStruggles: Set<String>
    @State private var appeared: Bool = false

    private let struggles: [(id: String, icon: String, text: String, color: Color)] = [
        ("consistency", "arrow.trianglehead.2.counterclockwise", "Lack of Consistency", Color(red: 0.40, green: 0.60, blue: 1.0)),
        ("eating", "fork.knife", "Unhealthy Eating Habits", Color(red: 0.30, green: 0.95, blue: 0.60)),
        ("schedule", "clock.badge.exclamationmark", "Busy Schedule", Color(red: 1.0, green: 0.7, blue: 0.2)),
        ("motivation", "battery.25percent", "Lack of Motivation", Color(red: 0.95, green: 0.35, blue: 0.35)),
        ("direction", "questionmark.circle", "Don't Know Where to Start", Color(red: 0.78, green: 0.50, blue: 1.0)),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What's your biggest\nstruggle?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .lineSpacing(2)

                Text("Select all that apply — be honest with yourself.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
            }
            .padding(.top, 20)
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .animation(.easeIn(duration: 0.4), value: appeared)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(struggles.enumerated()), id: \.element.id) { index, struggle in
                        let isSelected = selectedStruggles.contains(struggle.id)
                        Button {
                            if isSelected {
                                selectedStruggles.remove(struggle.id)
                            } else {
                                selectedStruggles.insert(struggle.id)
                            }
                        } label: {
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isSelected ? struggle.color.opacity(0.2) : AppTheme.cardSurface)
                                        .frame(width: 44, height: 44)
                                    if isSelected {
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(struggle.color.opacity(0.4), lineWidth: 1)
                                            .frame(width: 44, height: 44)
                                    }
                                    Image(systemName: struggle.icon)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(isSelected ? struggle.color : AppTheme.secondaryText)
                                }

                                Text(struggle.text)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(isSelected ? .white : AppTheme.secondaryText)

                                Spacer()

                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(isSelected ? struggle.color : AppTheme.border.opacity(0.8), lineWidth: isSelected ? 2 : 1.5)
                                        .frame(width: 24, height: 24)
                                    if isSelected {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(struggle.color)
                                            .frame(width: 14, height: 14)
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .black))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(isSelected ? struggle.color.opacity(0.06) : AppTheme.cardSurface)
                            )
                            .clipShape(.rect(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(isSelected ? struggle.color.opacity(0.35) : AppTheme.border.opacity(0.4), lineWidth: isSelected ? 1.5 : 1)
                            )
                        }
                        .sensoryFeedback(.selection, trigger: isSelected)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeIn(duration: 0.3).delay(0.05 + Double(index) * 0.05), value: appeared)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)

            if !selectedStruggles.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.primaryAccent)
                    Text("\(selectedStruggles.count) selected — we'll build your plan around these")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(duration: 0.4), value: selectedStruggles.count)
            }
        }
        .onAppear { appeared = true }
    }
}
