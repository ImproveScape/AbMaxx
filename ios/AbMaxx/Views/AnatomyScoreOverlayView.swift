import SwiftUI

struct AnatomyScoreOverlayView: View {
    let upperAbsScore: Int
    let lowerAbsScore: Int
    let obliquesScore: Int
    let vTaperScore: Int

    @State private var opacity: Double = 0

    private static let imageURL = "https://r2-pub.rork.com/projects/ef37pg3laezo1t2hj7mt0/assets/9538eb95-b1ae-4581-b7cb-569bb4160e1c.png"

    var body: some View {
        ZStack {
            Color.clear

            AsyncImage(url: URL(string: Self.imageURL)) { phase in
                if let image = phase.image {
                    GeometryReader { geo in
                        let side = min(geo.size.width, geo.size.height)
                        ZStack {
                            Canvas { context, canvasSize in
                                drawAllZones(context: context, size: canvasSize)
                            }
                            .frame(width: side, height: side)
                            .opacity(opacity)

                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: side, height: side)
                                .blendMode(.screen)
                                .allowsHitTesting(false)
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                    }
                } else if phase.error != nil {
                    placeholderView
                } else {
                    placeholderView
                        .overlay {
                            ProgressView()
                                .tint(AppTheme.primaryAccent)
                        }
                }
            }
        }
        .clipShape(.rect(cornerRadius: 14))
        .onAppear {
            if opacity == 0 {
                withAnimation(.easeOut(duration: 0.8)) {
                    opacity = 1
                }
            } else {
                opacity = 1
            }
        }
    }

    private var placeholderView: some View {
        Color.clear
            .aspectRatio(1.0, contentMode: .fit)
    }

    private func drawAllZones(context: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        drawObliques(context: context, w: w, h: h)
        drawVTaper(context: context, w: w, h: h)
        drawUpperAbs(context: context, w: w, h: h)
        drawLowerAbs(context: context, w: w, h: h)
    }

    // MARK: - Upper Abs (rows 1-2)

    private func drawUpperAbs(context: GraphicsContext, w: CGFloat, h: CGFloat) {
        let color = zoneColor(for: upperAbsScore)

        var r1l = Path()
        r1l.move(to: pt(0.383, 0.297, w, h))
        r1l.addLine(to: pt(0.494, 0.292, w, h))
        r1l.addLine(to: pt(0.494, 0.366, w, h))
        r1l.addLine(to: pt(0.379, 0.370, w, h))
        r1l.closeSubpath()

        var r1r = Path()
        r1r.move(to: pt(0.506, 0.292, w, h))
        r1r.addLine(to: pt(0.617, 0.297, w, h))
        r1r.addLine(to: pt(0.621, 0.370, w, h))
        r1r.addLine(to: pt(0.506, 0.366, w, h))
        r1r.closeSubpath()

        var r2l = Path()
        r2l.move(to: pt(0.376, 0.379, w, h))
        r2l.addLine(to: pt(0.494, 0.376, w, h))
        r2l.addLine(to: pt(0.494, 0.447, w, h))
        r2l.addLine(to: pt(0.371, 0.450, w, h))
        r2l.closeSubpath()

        var r2r = Path()
        r2r.move(to: pt(0.506, 0.376, w, h))
        r2r.addLine(to: pt(0.624, 0.379, w, h))
        r2r.addLine(to: pt(0.629, 0.450, w, h))
        r2r.addLine(to: pt(0.506, 0.447, w, h))
        r2r.closeSubpath()

        for path in [r1l, r1r, r2l, r2r] {
            context.fill(path, with: .color(color))
        }
    }

    // MARK: - Lower Abs (rows 3-4)

    private func drawLowerAbs(context: GraphicsContext, w: CGFloat, h: CGFloat) {
        let color = zoneColor(for: lowerAbsScore)

        var r3l = Path()
        r3l.move(to: pt(0.368, 0.459, w, h))
        r3l.addLine(to: pt(0.494, 0.456, w, h))
        r3l.addLine(to: pt(0.494, 0.529, w, h))
        r3l.addLine(to: pt(0.364, 0.532, w, h))
        r3l.closeSubpath()

        var r3r = Path()
        r3r.move(to: pt(0.506, 0.456, w, h))
        r3r.addLine(to: pt(0.632, 0.459, w, h))
        r3r.addLine(to: pt(0.636, 0.532, w, h))
        r3r.addLine(to: pt(0.506, 0.529, w, h))
        r3r.closeSubpath()

        var r4l = Path()
        r4l.move(to: pt(0.366, 0.542, w, h))
        r4l.addLine(to: pt(0.494, 0.539, w, h))
        r4l.addLine(to: pt(0.494, 0.612, w, h))
        r4l.addLine(to: pt(0.453, 0.627, w, h))
        r4l.addLine(to: pt(0.413, 0.619, w, h))
        r4l.addLine(to: pt(0.383, 0.597, w, h))
        r4l.closeSubpath()

        var r4r = Path()
        r4r.move(to: pt(0.506, 0.539, w, h))
        r4r.addLine(to: pt(0.634, 0.542, w, h))
        r4r.addLine(to: pt(0.617, 0.597, w, h))
        r4r.addLine(to: pt(0.587, 0.619, w, h))
        r4r.addLine(to: pt(0.547, 0.627, w, h))
        r4r.addLine(to: pt(0.506, 0.612, w, h))
        r4r.closeSubpath()

        for path in [r3l, r3r, r4l, r4r] {
            context.fill(path, with: .color(color))
        }
    }

    // MARK: - Obliques

    private func drawObliques(context: GraphicsContext, w: CGFloat, h: CGFloat) {
        let color = zoneColor(for: obliquesScore)

        var left = Path()
        left.move(to: pt(0.381, 0.295, w, h))
        left.addLine(to: pt(0.312, 0.272, w, h))
        left.addLine(to: pt(0.278, 0.303, w, h))
        left.addLine(to: pt(0.328, 0.332, w, h))
        left.addLine(to: pt(0.280, 0.360, w, h))
        left.addLine(to: pt(0.322, 0.390, w, h))
        left.addLine(to: pt(0.272, 0.418, w, h))
        left.addLine(to: pt(0.270, 0.462, w, h))
        left.addLine(to: pt(0.278, 0.512, w, h))
        left.addLine(to: pt(0.298, 0.558, w, h))
        left.addLine(to: pt(0.320, 0.592, w, h))
        left.addLine(to: pt(0.342, 0.618, w, h))
        left.addLine(to: pt(0.376, 0.600, w, h))
        left.addLine(to: pt(0.366, 0.542, w, h))
        left.addLine(to: pt(0.364, 0.532, w, h))
        left.addLine(to: pt(0.368, 0.459, w, h))
        left.addLine(to: pt(0.371, 0.450, w, h))
        left.addLine(to: pt(0.376, 0.379, w, h))
        left.addLine(to: pt(0.379, 0.370, w, h))
        left.closeSubpath()
        context.fill(left, with: .color(color))

        var right = Path()
        right.move(to: pt(0.619, 0.295, w, h))
        right.addLine(to: pt(0.688, 0.272, w, h))
        right.addLine(to: pt(0.722, 0.303, w, h))
        right.addLine(to: pt(0.672, 0.332, w, h))
        right.addLine(to: pt(0.720, 0.360, w, h))
        right.addLine(to: pt(0.678, 0.390, w, h))
        right.addLine(to: pt(0.728, 0.418, w, h))
        right.addLine(to: pt(0.730, 0.462, w, h))
        right.addLine(to: pt(0.722, 0.512, w, h))
        right.addLine(to: pt(0.702, 0.558, w, h))
        right.addLine(to: pt(0.680, 0.592, w, h))
        right.addLine(to: pt(0.658, 0.618, w, h))
        right.addLine(to: pt(0.624, 0.600, w, h))
        right.addLine(to: pt(0.634, 0.542, w, h))
        right.addLine(to: pt(0.636, 0.532, w, h))
        right.addLine(to: pt(0.632, 0.459, w, h))
        right.addLine(to: pt(0.629, 0.450, w, h))
        right.addLine(to: pt(0.624, 0.379, w, h))
        right.addLine(to: pt(0.621, 0.370, w, h))
        right.closeSubpath()
        context.fill(right, with: .color(color))
    }

    // MARK: - V-Taper

    private func drawVTaper(context: GraphicsContext, w: CGFloat, h: CGFloat) {
        let color = zoneColor(for: vTaperScore)

        var leftV = Path()
        leftV.move(to: pt(0.377, 0.620, w, h))
        leftV.addLine(to: pt(0.410, 0.634, w, h))
        leftV.addLine(to: pt(0.452, 0.773, w, h))
        leftV.addLine(to: pt(0.440, 0.778, w, h))
        leftV.addLine(to: pt(0.395, 0.642, w, h))
        leftV.addLine(to: pt(0.368, 0.624, w, h))
        leftV.closeSubpath()
        context.fill(leftV, with: .color(color))

        var rightV = Path()
        rightV.move(to: pt(0.623, 0.620, w, h))
        rightV.addLine(to: pt(0.590, 0.634, w, h))
        rightV.addLine(to: pt(0.548, 0.773, w, h))
        rightV.addLine(to: pt(0.560, 0.778, w, h))
        rightV.addLine(to: pt(0.605, 0.642, w, h))
        rightV.addLine(to: pt(0.632, 0.624, w, h))
        rightV.closeSubpath()
        context.fill(rightV, with: .color(color))
    }

    // MARK: - Helpers

    private func pt(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGPoint {
        CGPoint(x: x * w, y: y * h)
    }

    private func zoneColor(for score: Int) -> Color {
        if score >= 85 { return Color(red: 0.20, green: 0.90, blue: 0.40) }
        if score >= 75 { return Color(red: 0.95, green: 0.80, blue: 0.10) }
        if score >= 65 { return Color(red: 1.00, green: 0.55, blue: 0.10) }
        return Color(red: 1.00, green: 0.22, blue: 0.20)
    }
}
