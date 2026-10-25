import Foundation
import Speech
import AVFoundation
import Observation

@Observable
@MainActor
final class SpeechRecognizer {

    
    var transcript: String = ""
    var isListening: Bool = false
    var errorMessage: String?

    
    private var recognizer: SFSpeechRecognizer?
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    init() {
        recognizer = SFSpeechRecognizer(locale: Locale.current)
            ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }

    //step 1 - permissions
    func startListening() {
        Task {
            guard await requestSpeechPermission(),
                  await requestMicrophonePermission() else { return }

            beginRecording()
        }
    }

    func stopListening() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        audioEngine = nil
        request = nil
        task = nil
        isListening = false
    }


    private func requestSpeechPermission() async -> Bool {
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        switch status {
        case .authorized:
            return true
        case .denied, .restricted:
            errorMessage = "Speech recognition is denied. Please enable it in Settings → Privacy → Speech Recognition."
            return false
        default:
            errorMessage = "Speech recognition is not available on this device."
            return false
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        let granted = await AVAudioApplication.requestRecordPermission()
        if !granted {
            errorMessage = "Microphone access is denied. Please enable it in Settings → Privacy → Microphone."
        }
        return granted
    }


    private func beginRecording() {
        stopListening() // reset any existing session

        guard let recognizer, recognizer.isAvailable else {
            errorMessage = "Speech recognizer is not available right now. Try again in a moment."
            return
        }

        // Step 1: Activate the audio session FIRST.
        // The input node format is only valid after the session is active.
        // Calling engine.start() with a mismatched/zero sample-rate format causes SIGABRT.
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Could not configure audio session: \(error.localizedDescription)"
            return
        }

        // Step 2: Build the engine and recognition request.
        let engine = AVAudioEngine()
        audioEngine = engine

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        request = req

        // Step 3: Now the session is active — outputFormat returns a valid sample rate.
        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            req.append(buffer)
        }

        // Step 4: Start recognition task.
        task = recognizer.recognitionTask(with: req) { [weak self] result, error in
            guard let self else { return }
            Task { @MainActor in
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }
                if error != nil || (result?.isFinal == true) {
                    self.stopListening()
                }
            }
        }

        // Step 5: Start the engine (session already active, format already valid).
        do {
            engine.prepare()
            try engine.start()
            isListening = true
            errorMessage = nil
        } catch {
            errorMessage = "Could not start recording: \(error.localizedDescription)"
            stopListening()
        }
    }
}
