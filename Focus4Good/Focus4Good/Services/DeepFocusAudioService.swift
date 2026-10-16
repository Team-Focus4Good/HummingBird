import AVFoundation
import Observation

// MARK: - DeepFocusAudioService

@Observable
@MainActor
final class DeepFocusAudioService: NSObject, AVAudioPlayerDelegate {

    static let shared = DeepFocusAudioService()

    private var audioPlayer: AVAudioPlayer?
    private(set) var isPlaying = false
    private(set) var duration: TimeInterval = 0
    var onFinished: (@MainActor () -> Void)?

    private override init() {
        super.init()
    }

    var currentTime: TimeInterval {
        get { audioPlayer?.currentTime ?? 0 }
        set { audioPlayer?.currentTime = newValue }
    }

    var volume: Float {
        get { audioPlayer?.volume ?? 1.0 }
        set { audioPlayer?.volume = newValue }
    }

    @discardableResult
    func loadAudio() -> Bool {
        // Stop any conflicting audio
        ASMRAudioService.shared.stop()
        BreatheAudioService.shared.stopAll()
        JPMRAudioService.shared.stopAll()

        // Configure audio session
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        let candidateNames = [
            "creating-mental-space",
            "creating-mental space",
            "creating_mental_space"
        ]

        var soundUrl: URL?
        for name in candidateNames {
            if let url = Bundle.main.url(forResource: name, withExtension: "mp3") {
                soundUrl = url
                break
            }
        }

        guard let url = soundUrl else {
            print("DeepFocusAudioService: could not find mental space mp3 in bundle")
            return false
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()
            audioPlayer = player
            duration = player.duration
            return true
        } catch {
            print("DeepFocusAudioService: failed to load audio — \(error)")
            return false
        }
    }

    func play() {
        if audioPlayer == nil {
            guard loadAudio() else { return }
        }
        audioPlayer?.play()
        isPlaying = true
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }

    func resume() {
        audioPlayer?.play()
        isPlaying = true
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func seek(to time: TimeInterval) {
        guard let player = audioPlayer else { return }
        let clamped = max(0, min(time, player.duration))
        player.currentTime = clamped
    }

    func setVolume(_ vol: Float) {
        audioPlayer?.volume = vol
    }

    // MARK: - AVAudioPlayerDelegate

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.onFinished?()
        }
    }
}
