import Foundation
import AVFoundation

nonisolated enum VoiceLogPhase: Sendable {
    case idle
    case recording
    case transcribing
    case analyzing
    case results
}

@Observable
@MainActor
class VoiceLogService: NSObject {
    var currentPhase: VoiceLogPhase = .idle
    var isRecording: Bool = false
    var transcribedText: String = ""
    var nutritionResults: [NutritionLookupResult] = []
    var errorMessage: String?
    var audioLevels: [Float] = Array(repeating: 0, count: 32)
    var permissionDenied: Bool = false

    private var audioRecorder: AVAudioRecorder?
    private var levelTimer: Timer?
    private var recordingURL: URL?

    func startRecording() {
        errorMessage = nil
        transcribedText = ""
        nutritionResults = []
        permissionDenied = false

        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            beginRecording()
        case .denied:
            permissionDenied = true
            errorMessage = "Microphone access denied. Enable it in Settings."
        case .undetermined:
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                Task { @MainActor [weak self] in
                    if granted {
                        self?.beginRecording()
                    } else {
                        self?.permissionDenied = true
                        self?.errorMessage = "Microphone access is required for voice logging."
                    }
                }
            }
        @unknown default:
            errorMessage = "Could not access microphone."
        }
    }

    private func beginRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            errorMessage = "Could not access microphone."
            return
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("voice_log_\(UUID().uuidString).m4a")
        recordingURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.isMeteringEnabled = true
            recorder.delegate = self
            recorder.record()
            audioRecorder = recorder
            isRecording = true
            currentPhase = .recording

            levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.updateLevels()
                }
            }
        } catch {
            errorMessage = "Could not start recording."
        }
    }

    func stopRecordingAndProcess() async {
        audioRecorder?.stop()
        levelTimer?.invalidate()
        levelTimer = nil
        isRecording = false
        audioLevels = Array(repeating: 0, count: 32)

        guard let url = recordingURL else {
            errorMessage = "No recording found."
            currentPhase = .results
            return
        }

        currentPhase = .transcribing

        do {
            let audioData = try Data(contentsOf: url)
            let text = try await OpenAIService.shared.transcribe(audioData: audioData, filename: "voice_log.m4a")
            transcribedText = text

            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errorMessage = "Could not understand audio. Try again."
                currentPhase = .results
                return
            }

            currentPhase = .analyzing
            await analyzeFood(text)
        } catch {
            errorMessage = "Transcription failed. Try again."
            currentPhase = .results
        }

        try? FileManager.default.removeItem(at: url)
    }

    func reset() {
        audioRecorder?.stop()
        levelTimer?.invalidate()
        levelTimer = nil
        isRecording = false
        currentPhase = .idle
        transcribedText = ""
        nutritionResults = []
        errorMessage = nil
        permissionDenied = false
        audioLevels = Array(repeating: 0, count: 32)
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
    }

    func stopAndCleanup() {
        audioRecorder?.stop()
        levelTimer?.invalidate()
        levelTimer = nil
        isRecording = false
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func analyzeFood(_ text: String) async {
        let prompt = """
        The user said they ate: "\(text)"
        Identify each food item and estimate nutrition including micronutrients. Return ONLY a JSON array:
        [{"name":"food name","calories":number,"protein":number,"carbs":number,"fat":number,"serving_size":"description","fiber":number,"sugar":number,"sodium":number,"potassium":number,"cholesterol":number,"vitamin_a":number,"vitamin_c":number,"calcium":number,"iron":number,"vitamin_d":number,"magnesium":number,"zinc":number}]
        All micronutrient values per serving. fiber/sugar in grams, sodium/potassium/calcium/iron/magnesium/zinc in mg, vitamin_a in mcg RAE, vitamin_c in mg, vitamin_d in mcg.
        Be accurate with real USDA nutritional data. If multiple items mentioned, list each separately.
        """

        do {
            let responseText = try await OpenAIService.shared.chat(
                model: "gpt-4o",
                messages: [["role": "user", "content": prompt]],
                temperature: 0.3
            )
            nutritionResults = parseResults(responseText)
            if nutritionResults.isEmpty {
                errorMessage = "Could not identify food items."
            }
        } catch {
            errorMessage = "Analysis failed. Try again."
        }

        currentPhase = .results
    }

    private func parseResults(_ text: String) -> [NutritionLookupResult] {
        var jsonString = text.trimmingCharacters(in: .whitespacesAndNewlines)
        jsonString = jsonString.replacingOccurrences(of: "```json", with: "")
        jsonString = jsonString.replacingOccurrences(of: "```", with: "")
        jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        if let start = jsonString.firstIndex(of: "["), let end = jsonString.lastIndex(of: "]") {
            jsonString = String(jsonString[start...end])
        }
        guard let data = jsonString.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return [] }

        return array.compactMap { item in
            guard let name = item["name"] as? String else { return nil }
            let cal: Int
            if let c = item["calories"] as? Int { cal = c }
            else if let c = item["calories"] as? Double { cal = Int(c) }
            else { cal = 0 }
            func d(_ key: String) -> Double { (item[key] as? Double) ?? (item[key] as? Int).map(Double.init) ?? 0 }
            let p = d("protein")
            let c = d("carbs")
            let f = d("fat")
            let s = item["serving_size"] as? String ?? "1 serving"
            return NutritionLookupResult(
                name: name, calories: cal, protein: p, carbs: c, fat: f, servingSize: s,
                fiber: d("fiber"), sugar: d("sugar"), sodium: d("sodium"),
                potassium: d("potassium"), cholesterol: d("cholesterol"),
                vitaminA: d("vitamin_a"), vitaminC: d("vitamin_c"),
                calcium: d("calcium"), iron: d("iron"),
                vitaminD: d("vitamin_d"), vitaminE: d("vitamin_e"), vitaminK: d("vitamin_k"),
                vitaminB6: d("vitamin_b6"), vitaminB12: d("vitamin_b12"), folate: d("folate"),
                magnesium: d("magnesium"), zinc: d("zinc"), phosphorus: d("phosphorus"),
                thiamin: d("thiamin"), riboflavin: d("riboflavin"), niacin: d("niacin"),
                manganese: d("manganese"), selenium: d("selenium"), copper: d("copper")
            )
        }
    }

    private func updateLevels() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        recorder.updateMeters()
        let power = recorder.averagePower(forChannel: 0)
        let normalizedLevel = max(0, (power + 50) / 50)

        audioLevels.removeFirst()
        audioLevels.append(normalizedLevel)
    }
}

extension VoiceLogService: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            isRecording = false
        }
    }
}
