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

    private var audioRecorder: AVAudioRecorder?
    private var levelTimer: Timer?
    private var recordingURL: URL?

    func startRecording() {
        errorMessage = nil
        transcribedText = ""
        nutritionResults = []

        Task {
            let granted = await requestMicPermission()
            guard granted else {
                errorMessage = "Microphone access denied. Enable in Settings."
                return
            }
            beginRecordingSession()
        }
    }

    private func requestMicPermission() async -> Bool {
        let status = AVAudioApplication.shared.recordPermission
        switch status {
        case .granted:
            return true
        case .undetermined:
            return await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { allowed in
                    continuation.resume(returning: allowed)
                }
            }
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    private func beginRecordingSession() {
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
            let text = try await RorkAI.shared.transcribe(audioData: audioData, filename: "voice_log.m4a")
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
        Identify each food item and estimate nutrition. Return ONLY a JSON array:
        [{"name":"food name","calories":number,"protein":number,"carbs":number,"fat":number,"serving_size":"description"}]
        Be accurate with real nutritional data. If multiple items mentioned, list each separately.
        """

        do {
            let responseText = try await AnthropicService.shared.chat(
                systemPrompt: "",
                messages: [["role": "user", "content": prompt]],
                model: "claude-sonnet-4-20250514",
                maxTokens: 1024,
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
            let p = (item["protein"] as? Double) ?? (item["protein"] as? Int).map(Double.init) ?? 0
            let c = (item["carbs"] as? Double) ?? (item["carbs"] as? Int).map(Double.init) ?? 0
            let f = (item["fat"] as? Double) ?? (item["fat"] as? Int).map(Double.init) ?? 0
            let s = item["serving_size"] as? String ?? "1 serving"
            return NutritionLookupResult(name: name, calories: cal, protein: p, carbs: c, fat: f, servingSize: s)
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
