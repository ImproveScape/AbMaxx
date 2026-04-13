import Foundation
import AVFoundation

@Observable
class VoiceCoachService {
    var isEnabled: Bool = true
    var isSpeaking: Bool = false

    private var audioPlayer: AVAudioPlayer?
    private var speechQueue: [String] = []
    private var isProcessingQueue: Bool = false
    private var audioCache: [String: Data] = [:]
    private let voiceId = "ErXwobaYiN019PkySvjV"
    private let modelId = "eleven_flash_v2_5"

    private var baseURL: String { Config.EXPO_PUBLIC_TOOLKIT_URL }
    private var secretKey: String { Config.EXPO_PUBLIC_RORK_TOOLKIT_SECRET_KEY }

    private var isConfigured: Bool {
        !baseURL.isEmpty && !secretKey.isEmpty
    }

    func speak(_ text: String, priority: Bool = false) {
        guard isEnabled && isConfigured else { return }
        if priority {
            speechQueue.insert(text, at: 0)
        } else {
            speechQueue.append(text)
        }
        processQueue()
    }

    func announceExerciseStart(name: String, sets: Int, reps: String, isTimeBased: Bool) {
        let message: String
        if isTimeBased {
            message = "Let's go. \(name). \(sets) sets. Brace your core."
        } else {
            message = "Next up. \(name). \(sets) sets. Lock in."
        }
        speak(message, priority: true)
    }

    func announceSetComplete(setNumber: Int, totalSets: Int) {
        let phrases = [
            "Set done. Nice work.",
            "Good set. Rest up.",
            "Solid. Recover and go again.",
            "That's the way. Breathe.",
            "Clean set. Stay locked in.",
        ]
        let phrase = phrases[setNumber % phrases.count]
        if setNumber >= totalSets {
            speak("Exercise complete. \(phrase)", priority: true)
        } else {
            speak(phrase, priority: true)
        }
    }

    func announceRestOver() {
        let phrases = [
            "Rest over. Let's go.",
            "Time's up. Back to work.",
            "Ready? Let's hit it.",
            "Break's done. Focus up.",
        ]
        speak(phrases.randomElement()!, priority: true)
    }

    func announceWorkoutComplete(exerciseCount: Int, totalTime: Int) {
        let minutes = totalTime / 60
        speak("Workout complete. \(exerciseCount) exercises in \(minutes) minutes. That's how you build abs.", priority: true)
    }

    func announceCoachingCue(_ cue: String) {
        speak(cue)
    }

    func stop() {
        speechQueue.removeAll()
        audioPlayer?.stop()
        audioPlayer = nil
        isSpeaking = false
        isProcessingQueue = false
    }

    private func processQueue() {
        guard !isProcessingQueue, !speechQueue.isEmpty else { return }
        isProcessingQueue = true

        Task {
            while !speechQueue.isEmpty {
                let text = speechQueue.removeFirst()
                await synthesizeAndPlay(text)
                try? await Task.sleep(for: .milliseconds(300))
            }
            isProcessingQueue = false
        }
    }

    private func synthesizeAndPlay(_ text: String) async {
        let cacheKey = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if let cached = audioCache[cacheKey] {
            await playAudio(cached)
            return
        }

        guard let url = URL(string: "\(baseURL)/v2/elevenlabs/v1/text-to-speech/\(voiceId)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(secretKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        let body: [String: Any] = [
            "text": text,
            "model_id": modelId,
            "output_format": "mp3_44100_128",
            "voice_settings": [
                "stability": 0.6,
                "similarity_boost": 0.75,
                "style": 0.3,
                "use_speaker_boost": true
            ]
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else { return }
        request.httpBody = httpBody

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200, data.count > 1000 else { return }

            if audioCache.count > 50 {
                audioCache.removeAll()
            }
            audioCache[cacheKey] = data
            await playAudio(data)
        } catch {
            // silently fail
        }
    }

    private func playAudio(_ data: Data) async {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { }

        do {
            let player = try AVAudioPlayer(data: data)
            audioPlayer = player
            isSpeaking = true
            player.play()

            while player.isPlaying {
                try? await Task.sleep(for: .milliseconds(100))
            }
            isSpeaking = false
        } catch {
            isSpeaking = false
        }
    }
}
