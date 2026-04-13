import SwiftUI

enum WordmarkSize {
    case large
    case medium
    case small
    case mini

    var fontSize: CGFloat {
        switch self {
        case .large: return 28
        case .medium: return 20
        case .small: return 14
        case .mini: return 11
        }
    }

    var tracking: CGFloat {
        switch self {
        case .large: return 4
        case .medium: return 3
        case .small: return 2.5
        case .mini: return 2
        }
    }
}

struct ABMAXXWordmark: View {
    var size: WordmarkSize = .large
    var color: Color = .white

    var body: some View {
        Text("ABMAXX")
            .font(.system(size: size.fontSize, weight: .black, design: .default))
            .tracking(size.tracking)
            .foregroundStyle(color)
    }
}
