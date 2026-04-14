import Foundation
import UIKit

class HeatMapService {
    static let shared = HeatMapService()

    private let systemPrompt = """
You are a sports medicine imaging specialist analyzing a physique photo to create a heat map overlay. You must return VERY precise normalized coordinates (0.0-1.0) for each muscle zone. The coordinates will be used to render colored fills directly on top of the muscle regions in the photo.

COORDINATE SYSTEM:
- (0,0) = top-left of the image
- (1,1) = bottom-right of the image
- cx/cy = exact center of the visible muscle area
- w/h = tight bounding width/height around that muscle (normalized)

CRITICAL ACCURACY RULES:
- Each zone must be positioned EXACTLY over the corresponding muscle in the image
- The w/h values should tightly fit the muscle — NOT oversized boxes
- Ab blocks should be small and precise, fitting inside the tendinous intersections
- Left/right abs should be close together, separated only by the linea alba (midline)
- Obliques should be positioned lateral to the rectus abdominis
- V-taper should be at the lower corners of the abs, angled inward
- The ab blocks should NOT overlap each other
- Keep zones SMALL and TIGHT — it is better to be slightly too small than too big

ZONES TO MAP:
1. upper_abs_left — left upper rectus abdominis block
2. upper_abs_right — right upper rectus abdominis block
3. mid_abs_left — left middle rectus abdominis block
4. mid_abs_right — right middle rectus abdominis block
5. lower_abs_left — left lower rectus abdominis block
6. lower_abs_right — right lower rectus abdominis block
7. left_oblique — left external oblique (lateral to abs)
8. right_oblique — right external oblique (lateral to abs)
9. v_taper_left — left inguinal/V-line
10. v_taper_right — right inguinal/V-line

SCORING (0-100):
- 90-100: Razor sharp, deeply etched separation visible
- 75-89: Clear definition with visible grooves
- 60-74: Moderate definition, outlines visible
- 45-59: Faint definition, covered by some fat
- 30-44: Minimal visibility, needs significant work
- 0-29: No visible definition

For each zone provide a brief technical note about what you see.

Return ONLY this JSON, no other text:
{
  "upper_abs_left": {"score": 0-100, "cx": 0.0-1.0, "cy": 0.0-1.0, "w": 0.0-1.0, "h": 0.0-1.0, "note": "brief technical observation"},
  "upper_abs_right": {"score": 0-100, "cx": 0.0-1.0, "cy": 0.0-1.0, "w": 0.0-1.0, "h": 0.0-1.0, "note": "..."},
  "mid_abs_left": {"score": 0-100, "cx": 0.0-1.0, "cy": 0.0-1.0, "w": 0.0-1.0, "h": 0.0-1.0, "note": "..."},
  "mid_abs_right": {"score": 0-100, "cx": 0.0-1.0, "cy": 0.0-1.0, "w": 0.0-1.0, "h": 0.0-1.0, "note": "..."},
  "lower_abs_left": {"score": 0-100, "cx": 0.0-1.0, "cy": 0.0-1.0, "w": 0.0-1.0, "h": 0.0-1.0, "note": "..."},
  "lower_abs_right": {"score": 0-100, "cx": 0.0-1.0, "cy": 0.0-1.0, "w": 0.0-1.0, "h": 0.0-1.0, "note": "..."},
  "left_oblique": {"score": 0-100, "cx": 0.0-1.0, "cy": 0.0-1.0, "w": 0.0-1.0, "h": 0.0-1.0, "note": "..."},
  "right_oblique": {"score": 0-100, "cx": 0.0-1.0, "cy": 0.0-1.0, "w": 0.0-1.0, "h": 0.0-1.0, "note": "..."},
  "v_taper_left": {"score": 0-100, "cx": 0.0-1.0, "cy": 0.0-1.0, "w": 0.0-1.0, "h": 0.0-1.0, "note": "..."},
  "v_taper_right": {"score": 0-100, "cx": 0.0-1.0, "cy": 0.0-1.0, "w": 0.0-1.0, "h": 0.0-1.0, "note": "..."},
  "overall_assessment": "2-3 sentence technical summary of the entire midsection",
  "strongest_area": "name of strongest zone",
  "weakest_area": "name of weakest zone",
  "technical_notes": ["note1", "note2", "note3", "note4"]
}
"""

    func analyzeForHeatMap(_ image: UIImage) async -> HeatMapAnalysis? {
        guard let base64 = imageToBase64(image) else { return nil }

        do {
            let content = try await AnthropicService.shared.chatWithVision(
                systemPrompt: systemPrompt,
                userText: "Analyze this physique photo. Map each abdominal zone with precise coordinates relative to the image. Score definition intensity for each zone. Be precise with coordinates — they will be used to render a heat map overlay directly on this image. Return only JSON.",
                imageBase64: base64,
                model: "claude-sonnet-4-20250514",
                maxTokens: 2000,
                temperature: 0.3
            )

            return parseResponse(content)
        } catch {
            print("[HeatMap] Error: \(error)")
            return nil
        }
    }

    private func parseResponse(_ text: String) -> HeatMapAnalysis? {
        var jsonString = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if jsonString.hasPrefix("```json") {
            jsonString = String(jsonString.dropFirst(7))
        }
        if jsonString.hasPrefix("```") {
            jsonString = String(jsonString.dropFirst(3))
        }
        if jsonString.hasSuffix("```") {
            jsonString = String(jsonString.dropLast(3))
        }
        jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)

        if let start = jsonString.range(of: "{"),
           let end = jsonString.range(of: "}", options: .backwards) {
            jsonString = String(jsonString[start.lowerBound...end.upperBound])
        }

        guard let data = jsonString.data(using: .utf8) else { return nil }

        do {
            let aiResponse = try JSONDecoder().decode(HeatMapAIResponse.self, from: data)
            return convertToHeatMap(aiResponse)
        } catch {
            print("[HeatMap] Parse error: \(error)")
            return nil
        }
    }

    private func convertToHeatMap(_ ai: HeatMapAIResponse) -> HeatMapAnalysis {
        let zoneMapping: [(String, HeatMapAIResponse.ZoneData)] = [
            ("Upper Abs L", ai.upper_abs_left),
            ("Upper Abs R", ai.upper_abs_right),
            ("Mid Abs L", ai.mid_abs_left),
            ("Mid Abs R", ai.mid_abs_right),
            ("Lower Abs L", ai.lower_abs_left),
            ("Lower Abs R", ai.lower_abs_right),
            ("Left Oblique", ai.left_oblique),
            ("Right Oblique", ai.right_oblique),
            ("V-Line L", ai.v_taper_left),
            ("V-Line R", ai.v_taper_right),
        ]

        let zones = zoneMapping.map { name, data in
            HeatMapZone(
                name: name,
                centerX: data.cx,
                centerY: data.cy,
                width: data.w,
                height: data.h,
                definitionScore: max(0, min(100, data.score)),
                needsWork: data.score < 60,
                note: data.note
            )
        }

        return HeatMapAnalysis(
            zones: zones,
            overallAssessment: ai.overall_assessment,
            strongestArea: ai.strongest_area,
            weakestArea: ai.weakest_area,
            technicalNotes: ai.technical_notes
        )
    }

    func generateHeatMapImage(_ image: UIImage, analysis: HeatMapAnalysis) async -> UIImage? {
        guard let pngData = resizeForEdit(image) else {
            print("[HeatMap] Failed to get PNG data for edit")
            return nil
        }

        let zoneDescriptions = analysis.zones.map { zone in
            "\(zone.name): score \(zone.definitionScore)/100 — \(zone.needsWork ? "NEEDS WORK" : "DEFINED")"
        }.joined(separator: "\n")

        let prompt = """
Edit this physique photo to add a professional sports-medicine style heat map overlay directly on the abdominal muscles. Keep the original photo fully visible underneath.

Overlay semi-transparent color zones on each muscle group using these exact score colors:
- Score 85+ = vivid iOS green (#30D158)
- Score 75-84 = bright system yellow (#FFD60A)
- Score 65-74 = system orange (#FF9F0A)
- Score below 65 = system red (#FF3B30)

Zone analysis:
\(zoneDescriptions)

Strongest: \(analysis.strongestArea)
Weakest: \(analysis.weakestArea)

Make it look like a high-tech body composition scan / thermal imaging analysis. Add thin white contour lines tracing each muscle group boundary. Add small score labels (like "87" or "42") near each zone. Use the score color assigned to each specific zone exactly — do not substitute cyan, lime, amber gradients, or generic heatmap colors. The overall look should be clinical, technical, and futuristic — like an elite sports lab diagnostic image. Keep the person's body clearly visible through the overlay.
"""

        do {
            let base64Result = try await RorkAI.shared.editImage(
                imageData: pngData,
                prompt: prompt,
                size: "1024x1536"
            )
            guard !base64Result.isEmpty,
                  let imageData = Data(base64Encoded: base64Result),
                  let resultImage = UIImage(data: imageData) else {
                print("[HeatMap] Failed to decode edited image")
                return nil
            }
            return resultImage
        } catch {
            print("[HeatMap] Image edit error: \(error)")
            return nil
        }
    }

    private func resizeForEdit(_ image: UIImage) -> Data? {
        let maxDimension: CGFloat = 1024
        let size = image.size
        let scale: CGFloat
        if size.width > size.height {
            scale = min(maxDimension / size.width, 1.0)
        } else {
            scale = min(maxDimension / size.height, 1.0)
        }
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resized?.pngData()
    }

    private func imageToBase64(_ image: UIImage) -> String? {
        let maxDimension: CGFloat = 1024
        let size = image.size
        let scale: CGFloat
        if size.width > size.height {
            scale = min(maxDimension / size.width, 1.0)
        } else {
            scale = min(maxDimension / size.height, 1.0)
        }
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resized?.jpegData(compressionQuality: 0.8)?.base64EncodedString()
    }
}
