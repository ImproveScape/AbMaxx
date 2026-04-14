import SwiftUI

struct AnatomyScoreOverlayView: View {
    let upperAbsScore: Int
    let lowerAbsScore: Int
    let obliquesScore: Int
    let vTaperScore: Int

    @State private var appeared: Bool = false

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
                                guard appeared else { return }
                                drawAllZones(context: context, size: canvasSize)
                            }
                            .frame(width: side, height: side)

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
            withAnimation(.easeOut(duration: 0.8)) {
                appeared = true
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

    private let dy: CGFloat = 0.04
    private let dx: CGFloat = 0.04

    // MARK: - Upper Abs (rows 1-2)

    private func drawUpperAbs(context: GraphicsContext, w: CGFloat, h: CGFloat) {
        let color = zoneColor(for: upperAbsScore)
        let pad: CGFloat = 0.008

        var r1l = Path()
        r1l.move(to: pt(0.383 - dx, 0.297 + dy - pad, w, h))
        r1l.addLine(to: pt(0.501, 0.292 + dy - pad, w, h))
        r1l.addLine(to: pt(0.501, 0.370 + dy + pad, w, h))
        r1l.addLine(to: pt(0.379 - dx, 0.370 + dy + pad, w, h))
        r1l.closeSubpath()

        var r1r = Path()
        r1r.move(to: pt(0.499, 0.292 + dy - pad, w, h))
        r1r.addLine(to: pt(0.617 + dx, 0.297 + dy - pad, w, h))
        r1r.addLine(to: pt(0.621 + dx, 0.370 + dy + pad, w, h))
        r1r.addLine(to: pt(0.499, 0.370 + dy + pad, w, h))
        r1r.closeSubpath()

        var r2l = Path()
        r2l.move(to: pt(0.376 - dx, 0.379 + dy - pad, w, h))
        r2l.addLine(to: pt(0.501, 0.376 + dy - pad, w, h))
        r2l.addLine(to: pt(0.501, 0.450 + dy + pad, w, h))
        r2l.addLine(to: pt(0.371 - dx, 0.450 + dy + pad, w, h))
        r2l.closeSubpath()

        var r2r = Path()
        r2r.move(to: pt(0.499, 0.376 + dy - pad, w, h))
        r2r.addLine(to: pt(0.624 + dx, 0.379 + dy - pad, w, h))
        r2r.addLine(to: pt(0.629 + dx, 0.450 + dy + pad, w, h))
        r2r.addLine(to: pt(0.499, 0.450 + dy + pad, w, h))
        r2r.closeSubpath()

        for path in [r1l, r1r, r2l, r2r] {
            context.fill(path, with: .color(color))
        }
    }

    // MARK: - Lower Abs (rows 3-4)

    private func drawLowerAbs(context: GraphicsContext, w: CGFloat, h: CGFloat) {
        let color = zoneColor(for: lowerAbsScore)
        let pad: CGFloat = 0.008

        var r3l = Path()
        r3l.move(to: pt(0.368 - dx, 0.459 + dy - pad, w, h))
        r3l.addLine(to: pt(0.501, 0.456 + dy - pad, w, h))
        r3l.addLine(to: pt(0.501, 0.532 + dy + pad, w, h))
        r3l.addLine(to: pt(0.364 - dx, 0.532 + dy + pad, w, h))
        r3l.closeSubpath()

        var r3r = Path()
        r3r.move(to: pt(0.499, 0.456 + dy - pad, w, h))
        r3r.addLine(to: pt(0.632 + dx, 0.459 + dy - pad, w, h))
        r3r.addLine(to: pt(0.636 + dx, 0.532 + dy + pad, w, h))
        r3r.addLine(to: pt(0.499, 0.532 + dy + pad, w, h))
        r3r.closeSubpath()

        var r4l = Path()
        r4l.move(to: pt(0.366 - dx, 0.542 + dy - pad, w, h))
        r4l.addLine(to: pt(0.501, 0.539 + dy - pad, w, h))
        r4l.addLine(to: pt(0.501, 0.612 + dy + pad, w, h))
        r4l.addLine(to: pt(0.453, 0.627 + dy + pad, w, h))
        r4l.addLine(to: pt(0.413 - dx, 0.619 + dy + pad, w, h))
        r4l.addLine(to: pt(0.383 - dx, 0.597 + dy + pad, w, h))
        r4l.closeSubpath()

        var r4r = Path()
        r4r.move(to: pt(0.499, 0.539 + dy - pad, w, h))
        r4r.addLine(to: pt(0.634 + dx, 0.542 + dy - pad, w, h))
        r4r.addLine(to: pt(0.617 + dx, 0.597 + dy + pad, w, h))
        r4r.addLine(to: pt(0.587 + dx, 0.619 + dy + pad, w, h))
        r4r.addLine(to: pt(0.547, 0.627 + dy + pad, w, h))
        r4r.addLine(to: pt(0.499, 0.612 + dy + pad, w, h))
        r4r.closeSubpath()

        for path in [r3l, r3r, r4l, r4r] {
            context.fill(path, with: .color(color))
        }
    }

    // MARK: - Obliques

    private func drawObliques(context: GraphicsContext, w: CGFloat, h: CGFloat) {
        let color = zoneColor(for: obliquesScore)
        let ex: CGFloat = 0.012

        var left = Path()
        left.move(to: pt(0.381 - dx, 0.295 + dy - ex, w, h))
        left.addLine(to: pt(0.312 - dx - ex, 0.272 + dy - ex, w, h))
        left.addLine(to: pt(0.278 - dx - ex, 0.303 + dy, w, h))
        left.addLine(to: pt(0.328 - dx - ex, 0.332 + dy, w, h))
        left.addLine(to: pt(0.280 - dx - ex, 0.360 + dy, w, h))
        left.addLine(to: pt(0.322 - dx - ex, 0.390 + dy, w, h))
        left.addLine(to: pt(0.272 - dx - ex, 0.418 + dy, w, h))
        left.addLine(to: pt(0.270 - dx - ex, 0.462 + dy, w, h))
        left.addLine(to: pt(0.278 - dx - ex, 0.512 + dy, w, h))
        left.addLine(to: pt(0.298 - dx - ex, 0.558 + dy, w, h))
        left.addLine(to: pt(0.320 - dx - ex, 0.592 + dy, w, h))
        left.addLine(to: pt(0.342 - dx - ex, 0.618 + dy + ex, w, h))
        left.addLine(to: pt(0.376 - dx, 0.600 + dy + ex, w, h))
        left.addLine(to: pt(0.366 - dx, 0.542 + dy, w, h))
        left.addLine(to: pt(0.364 - dx, 0.532 + dy, w, h))
        left.addLine(to: pt(0.368 - dx, 0.459 + dy, w, h))
        left.addLine(to: pt(0.371 - dx, 0.450 + dy, w, h))
        left.addLine(to: pt(0.376 - dx, 0.379 + dy, w, h))
        left.addLine(to: pt(0.379 - dx, 0.370 + dy, w, h))
        left.closeSubpath()
        context.fill(left, with: .color(color))

        var right = Path()
        right.move(to: pt(0.619 + dx, 0.295 + dy - ex, w, h))
        right.addLine(to: pt(0.688 + dx + ex, 0.272 + dy - ex, w, h))
        right.addLine(to: pt(0.722 + dx + ex, 0.303 + dy, w, h))
        right.addLine(to: pt(0.672 + dx + ex, 0.332 + dy, w, h))
        right.addLine(to: pt(0.720 + dx + ex, 0.360 + dy, w, h))
        right.addLine(to: pt(0.678 + dx + ex, 0.390 + dy, w, h))
        right.addLine(to: pt(0.728 + dx + ex, 0.418 + dy, w, h))
        right.addLine(to: pt(0.730 + dx + ex, 0.462 + dy, w, h))
        right.addLine(to: pt(0.722 + dx + ex, 0.512 + dy, w, h))
        right.addLine(to: pt(0.702 + dx + ex, 0.558 + dy, w, h))
        right.addLine(to: pt(0.680 + dx + ex, 0.592 + dy, w, h))
        right.addLine(to: pt(0.658 + dx + ex, 0.618 + dy + ex, w, h))
        right.addLine(to: pt(0.624 + dx, 0.600 + dy + ex, w, h))
        right.addLine(to: pt(0.634 + dx, 0.542 + dy, w, h))
        right.addLine(to: pt(0.636 + dx, 0.532 + dy, w, h))
        right.addLine(to: pt(0.632 + dx, 0.459 + dy, w, h))
        right.addLine(to: pt(0.629 + dx, 0.450 + dy, w, h))
        right.addLine(to: pt(0.624 + dx, 0.379 + dy, w, h))
        right.addLine(to: pt(0.621 + dx, 0.370 + dy, w, h))
        right.closeSubpath()
        context.fill(right, with: .color(color))
    }

    // MARK: - V-Taper

    private func drawVTaper(context: GraphicsContext, w: CGFloat, h: CGFloat) {
        let color = zoneColor(for: vTaperScore)
        let ex: CGFloat = 0.008

        var leftV = Path()
        leftV.move(to: pt(0.377 - dx - ex, 0.620 + dy, w, h))
        leftV.addLine(to: pt(0.410, 0.634 + dy, w, h))
        leftV.addLine(to: pt(0.452 + ex, 0.773 + dy + ex, w, h))
        leftV.addLine(to: pt(0.440, 0.778 + dy + ex, w, h))
        leftV.addLine(to: pt(0.395 - dx - ex, 0.642 + dy, w, h))
        leftV.addLine(to: pt(0.368 - dx - ex, 0.624 + dy, w, h))
        leftV.closeSubpath()
        context.fill(leftV, with: .color(color))

        var rightV = Path()
        rightV.move(to: pt(0.623 + dx + ex, 0.620 + dy, w, h))
        rightV.addLine(to: pt(0.590, 0.634 + dy, w, h))
        rightV.addLine(to: pt(0.548 - ex, 0.773 + dy + ex, w, h))
        rightV.addLine(to: pt(0.560, 0.778 + dy + ex, w, h))
        rightV.addLine(to: pt(0.605 + dx + ex, 0.642 + dy, w, h))
        rightV.addLine(to: pt(0.632 + dx + ex, 0.624 + dy, w, h))
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
