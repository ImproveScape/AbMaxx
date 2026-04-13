import SwiftUI

struct MuscleMapView: View {
    let focusMuscles: [MuscleHighlight]
    let region: AbRegion

    private let highlightColor = Color(red: 0.25, green: 0.50, blue: 1.0)
    private let secondaryColor = Color(red: 0.40, green: 0.60, blue: 1.0)

    var body: some View {
        HStack(spacing: 0) {
            anatomicalImageView(imageName: "body_front", isFront: true)
            anatomicalImageView(imageName: "body_back", isFront: false)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 340)
        .background(BackgroundView().ignoresSafeArea())
        .clipShape(.rect(cornerRadius: 16))
    }

    private func anatomicalImageView(imageName: String, isFront: Bool) -> some View {
        GeometryReader { geo in
            let _ = geo.size.width
            let _ = geo.size.height

            ZStack {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Canvas { context, size in
                    let imgAspect: CGFloat = 1024.0 / 1536.0
                    let containerAspect = size.width / size.height

                    let imgW: CGFloat
                    let imgH: CGFloat
                    let imgX: CGFloat
                    let imgY: CGFloat

                    if imgAspect > containerAspect {
                        imgW = size.width
                        imgH = imgW / imgAspect
                        imgX = 0
                        imgY = (size.height - imgH) / 2
                    } else {
                        imgH = size.height
                        imgW = imgH * imgAspect
                        imgX = (size.width - imgW) / 2
                        imgY = 0
                    }

                    func pt(_ xPct: CGFloat, _ yPct: CGFloat) -> CGPoint {
                        CGPoint(x: imgX + xPct * imgW, y: imgY + yPct * imgH)
                    }

                    func sz(_ wPct: CGFloat, _ hPct: CGFloat) -> CGSize {
                        CGSize(width: wPct * imgW, height: hPct * imgH)
                    }

                    if isFront {
                        drawFrontHighlights(context: &context, pt: pt, sz: sz)
                    } else {
                        drawBackHighlights(context: &context, pt: pt, sz: sz)
                    }
                }
                .allowsHitTesting(false)
                .blendMode(.screen)
            }
        }
    }

    // MARK: - Front Highlights

    private func drawFrontHighlights(
        context: inout GraphicsContext,
        pt: (_ xPct: CGFloat, _ yPct: CGFloat) -> CGPoint,
        sz: (_ wPct: CGFloat, _ hPct: CGFloat) -> CGSize
    ) {
        if shouldHighlightFrontUpper {
            var rectusUpper = Path()
            rectusUpper.move(to: pt(0.42, 0.30))
            rectusUpper.addQuadCurve(to: pt(0.58, 0.30), control: pt(0.50, 0.285))
            rectusUpper.addLine(to: pt(0.58, 0.42))
            rectusUpper.addQuadCurve(to: pt(0.42, 0.42), control: pt(0.50, 0.425))
            rectusUpper.closeSubpath()
            context.fill(rectusUpper, with: .color(highlightColor.opacity(0.55)))

            var leftBlock1 = Path()
            leftBlock1.addRoundedRect(in: CGRect(origin: pt(0.425, 0.305), size: sz(0.07, 0.05)), cornerSize: CGSize(width: 2, height: 2))
            context.fill(leftBlock1, with: .color(highlightColor.opacity(0.7)))

            var rightBlock1 = Path()
            rightBlock1.addRoundedRect(in: CGRect(origin: pt(0.505, 0.305), size: sz(0.07, 0.05)), cornerSize: CGSize(width: 2, height: 2))
            context.fill(rightBlock1, with: .color(highlightColor.opacity(0.7)))

            var leftBlock2 = Path()
            leftBlock2.addRoundedRect(in: CGRect(origin: pt(0.425, 0.36), size: sz(0.07, 0.05)), cornerSize: CGSize(width: 2, height: 2))
            context.fill(leftBlock2, with: .color(highlightColor.opacity(0.65)))

            var rightBlock2 = Path()
            rightBlock2.addRoundedRect(in: CGRect(origin: pt(0.505, 0.36), size: sz(0.07, 0.05)), cornerSize: CGSize(width: 2, height: 2))
            context.fill(rightBlock2, with: .color(highlightColor.opacity(0.65)))
        }

        if shouldHighlightFrontLower {
            var lowerAbs = Path()
            lowerAbs.move(to: pt(0.43, 0.42))
            lowerAbs.addLine(to: pt(0.57, 0.42))
            lowerAbs.addQuadCurve(to: pt(0.55, 0.50), control: pt(0.58, 0.46))
            lowerAbs.addQuadCurve(to: pt(0.45, 0.50), control: pt(0.50, 0.51))
            lowerAbs.addQuadCurve(to: pt(0.43, 0.42), control: pt(0.42, 0.46))
            lowerAbs.closeSubpath()
            context.fill(lowerAbs, with: .color(highlightColor.opacity(0.50)))

            var leftLower1 = Path()
            leftLower1.addRoundedRect(in: CGRect(origin: pt(0.435, 0.425), size: sz(0.06, 0.035)), cornerSize: CGSize(width: 2, height: 2))
            context.fill(leftLower1, with: .color(highlightColor.opacity(0.65)))

            var rightLower1 = Path()
            rightLower1.addRoundedRect(in: CGRect(origin: pt(0.505, 0.425), size: sz(0.06, 0.035)), cornerSize: CGSize(width: 2, height: 2))
            context.fill(rightLower1, with: .color(highlightColor.opacity(0.65)))

            var leftLower2 = Path()
            leftLower2.addRoundedRect(in: CGRect(origin: pt(0.44, 0.465), size: sz(0.055, 0.03)), cornerSize: CGSize(width: 2, height: 2))
            context.fill(leftLower2, with: .color(highlightColor.opacity(0.6)))

            var rightLower2 = Path()
            rightLower2.addRoundedRect(in: CGRect(origin: pt(0.505, 0.465), size: sz(0.055, 0.03)), cornerSize: CGSize(width: 2, height: 2))
            context.fill(rightLower2, with: .color(highlightColor.opacity(0.6)))
        }

        if shouldHighlightObliques {
            var leftOblique = Path()
            leftOblique.move(to: pt(0.34, 0.30))
            leftOblique.addQuadCurve(to: pt(0.42, 0.30), control: pt(0.38, 0.29))
            leftOblique.addLine(to: pt(0.43, 0.48))
            leftOblique.addQuadCurve(to: pt(0.36, 0.48), control: pt(0.40, 0.49))
            leftOblique.addQuadCurve(to: pt(0.34, 0.30), control: pt(0.32, 0.39))
            leftOblique.closeSubpath()
            context.fill(leftOblique, with: .color(secondaryColor.opacity(0.40)))

            var rightOblique = Path()
            rightOblique.move(to: pt(0.58, 0.30))
            rightOblique.addQuadCurve(to: pt(0.66, 0.30), control: pt(0.62, 0.29))
            rightOblique.addQuadCurve(to: pt(0.64, 0.48), control: pt(0.68, 0.39))
            rightOblique.addQuadCurve(to: pt(0.57, 0.48), control: pt(0.60, 0.49))
            rightOblique.closeSubpath()
            context.fill(rightOblique, with: .color(secondaryColor.opacity(0.40)))
        }

        if shouldHighlightDeepCore {
            var deepCore = Path()
            deepCore.move(to: pt(0.38, 0.29))
            deepCore.addLine(to: pt(0.62, 0.29))
            deepCore.addQuadCurve(to: pt(0.60, 0.50), control: pt(0.65, 0.40))
            deepCore.addQuadCurve(to: pt(0.40, 0.50), control: pt(0.50, 0.52))
            deepCore.addQuadCurve(to: pt(0.38, 0.29), control: pt(0.35, 0.40))
            deepCore.closeSubpath()
            context.fill(deepCore, with: .color(highlightColor.opacity(0.30)))
        }

        if shouldHighlightHipFlexors {
            var leftHip = Path()
            leftHip.addEllipse(in: CGRect(origin: pt(0.36, 0.48), size: sz(0.10, 0.05)))
            context.fill(leftHip, with: .color(secondaryColor.opacity(0.35)))

            var rightHip = Path()
            rightHip.addEllipse(in: CGRect(origin: pt(0.54, 0.48), size: sz(0.10, 0.05)))
            context.fill(rightHip, with: .color(secondaryColor.opacity(0.35)))
        }

        if shouldHighlightShoulders {
            var leftDelt = Path()
            leftDelt.addEllipse(in: CGRect(origin: pt(0.24, 0.22), size: sz(0.10, 0.06)))
            context.fill(leftDelt, with: .color(secondaryColor.opacity(0.35)))

            var rightDelt = Path()
            rightDelt.addEllipse(in: CGRect(origin: pt(0.66, 0.22), size: sz(0.10, 0.06)))
            context.fill(rightDelt, with: .color(secondaryColor.opacity(0.35)))
        }

        if shouldHighlightQuads {
            var leftQuad = Path()
            leftQuad.move(to: pt(0.36, 0.54))
            leftQuad.addLine(to: pt(0.48, 0.54))
            leftQuad.addQuadCurve(to: pt(0.47, 0.72), control: pt(0.50, 0.63))
            leftQuad.addLine(to: pt(0.37, 0.72))
            leftQuad.addQuadCurve(to: pt(0.36, 0.54), control: pt(0.33, 0.63))
            leftQuad.closeSubpath()
            context.fill(leftQuad, with: .color(secondaryColor.opacity(0.30)))

            var rightQuad = Path()
            rightQuad.move(to: pt(0.52, 0.54))
            rightQuad.addLine(to: pt(0.64, 0.54))
            rightQuad.addQuadCurve(to: pt(0.63, 0.72), control: pt(0.67, 0.63))
            rightQuad.addLine(to: pt(0.53, 0.72))
            rightQuad.addQuadCurve(to: pt(0.52, 0.54), control: pt(0.50, 0.63))
            rightQuad.closeSubpath()
            context.fill(rightQuad, with: .color(secondaryColor.opacity(0.30)))
        }
    }

    // MARK: - Back Highlights

    private func drawBackHighlights(
        context: inout GraphicsContext,
        pt: (_ xPct: CGFloat, _ yPct: CGFloat) -> CGPoint,
        sz: (_ wPct: CGFloat, _ hPct: CGFloat) -> CGSize
    ) {
        if shouldHighlightObliques {
            var leftOblique = Path()
            leftOblique.move(to: pt(0.34, 0.34))
            leftOblique.addLine(to: pt(0.44, 0.34))
            leftOblique.addLine(to: pt(0.44, 0.47))
            leftOblique.addQuadCurve(to: pt(0.36, 0.47), control: pt(0.40, 0.48))
            leftOblique.addQuadCurve(to: pt(0.34, 0.34), control: pt(0.32, 0.41))
            leftOblique.closeSubpath()
            context.fill(leftOblique, with: .color(secondaryColor.opacity(0.40)))

            var rightOblique = Path()
            rightOblique.move(to: pt(0.56, 0.34))
            rightOblique.addLine(to: pt(0.66, 0.34))
            rightOblique.addQuadCurve(to: pt(0.64, 0.47), control: pt(0.68, 0.41))
            rightOblique.addQuadCurve(to: pt(0.56, 0.47), control: pt(0.60, 0.48))
            rightOblique.closeSubpath()
            context.fill(rightOblique, with: .color(secondaryColor.opacity(0.40)))
        }

        if shouldHighlightErectorSpinae {
            var leftErector = Path()
            leftErector.move(to: pt(0.45, 0.24))
            leftErector.addLine(to: pt(0.49, 0.24))
            leftErector.addLine(to: pt(0.49, 0.48))
            leftErector.addLine(to: pt(0.45, 0.48))
            leftErector.closeSubpath()
            context.fill(leftErector, with: .color(secondaryColor.opacity(0.40)))

            var rightErector = Path()
            rightErector.move(to: pt(0.51, 0.24))
            rightErector.addLine(to: pt(0.55, 0.24))
            rightErector.addLine(to: pt(0.55, 0.48))
            rightErector.addLine(to: pt(0.51, 0.48))
            rightErector.closeSubpath()
            context.fill(rightErector, with: .color(secondaryColor.opacity(0.40)))
        }

        if shouldHighlightGlutes {
            var leftGlute = Path()
            leftGlute.addEllipse(in: CGRect(origin: pt(0.36, 0.47), size: sz(0.13, 0.07)))
            context.fill(leftGlute, with: .color(secondaryColor.opacity(0.35)))

            var rightGlute = Path()
            rightGlute.addEllipse(in: CGRect(origin: pt(0.51, 0.47), size: sz(0.13, 0.07)))
            context.fill(rightGlute, with: .color(secondaryColor.opacity(0.35)))
        }

        if shouldHighlightLats {
            var leftLat = Path()
            leftLat.move(to: pt(0.30, 0.24))
            leftLat.addLine(to: pt(0.44, 0.24))
            leftLat.addLine(to: pt(0.44, 0.38))
            leftLat.addQuadCurve(to: pt(0.30, 0.34), control: pt(0.36, 0.37))
            leftLat.closeSubpath()
            context.fill(leftLat, with: .color(secondaryColor.opacity(0.35)))

            var rightLat = Path()
            rightLat.move(to: pt(0.56, 0.24))
            rightLat.addLine(to: pt(0.70, 0.24))
            rightLat.addQuadCurve(to: pt(0.56, 0.38), control: pt(0.64, 0.37))
            rightLat.closeSubpath()
            context.fill(rightLat, with: .color(secondaryColor.opacity(0.35)))
        }

        if shouldHighlightDeepCore || shouldHighlightFrontUpper || shouldHighlightFrontLower {
            var lowerBack = Path()
            lowerBack.move(to: pt(0.40, 0.38))
            lowerBack.addLine(to: pt(0.60, 0.38))
            lowerBack.addQuadCurve(to: pt(0.58, 0.48), control: pt(0.62, 0.43))
            lowerBack.addQuadCurve(to: pt(0.42, 0.48), control: pt(0.50, 0.49))
            lowerBack.addQuadCurve(to: pt(0.40, 0.38), control: pt(0.38, 0.43))
            lowerBack.closeSubpath()
            context.fill(lowerBack, with: .color(highlightColor.opacity(0.25)))
        }
    }

    // MARK: - Highlight Logic

    private var muscleNames: Set<String> {
        Set(focusMuscles.map { $0.name.lowercased() })
    }

    private var shouldHighlightFrontUpper: Bool {
        muscleNames.contains(where: { $0.contains("rectus abdominis") || $0.contains("upper rectus") }) ||
        region == .upperAbs || region == .deepCore
    }

    private var shouldHighlightFrontLower: Bool {
        muscleNames.contains(where: { $0.contains("rectus abdominis") || $0.contains("lower rectus") }) ||
        region == .lowerAbs || region == .deepCore
    }

    private var shouldHighlightObliques: Bool {
        muscleNames.contains(where: { $0.contains("oblique") }) || region == .obliques
    }

    private var shouldHighlightDeepCore: Bool {
        muscleNames.contains(where: { $0.contains("transverse") })
    }

    private var shouldHighlightShoulders: Bool {
        muscleNames.contains(where: { $0.contains("shoulder") })
    }

    private var shouldHighlightHipFlexors: Bool {
        muscleNames.contains(where: { $0.contains("hip flexor") })
    }

    private var shouldHighlightQuads: Bool {
        muscleNames.contains(where: { $0.contains("quad") })
    }

    private var shouldHighlightErectorSpinae: Bool {
        muscleNames.contains(where: { $0.contains("erector") })
    }

    private var shouldHighlightGlutes: Bool {
        muscleNames.contains(where: { $0.contains("glute") })
    }

    private var shouldHighlightLats: Bool {
        muscleNames.contains(where: { $0.contains("lat") && !$0.contains("oblique") })
    }
}
