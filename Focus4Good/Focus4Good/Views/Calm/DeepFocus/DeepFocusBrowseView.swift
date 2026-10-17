import SwiftUI

// MARK: - DeepFocusBrowseView

struct DeepFocusBrowseView: View {

    @Environment(CalmCentreStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var isPlaying = false
    @State private var hasStarted = false
    @State private var elapsed: TimeInterval = 0
    @State private var totalDuration: TimeInterval = 644
    @State private var timer: Timer?
    @State private var volume: Double = 0.8
    @State private var isMuted = false
    @State private var isFavourite = false
    @State private var showCompletion = false
    @State private var isSeeking = false
    @State private var seekTime: TimeInterval = 0

    private static let favouriteKey = "deep_focus_favourite"
    private let userId = UUID()
    private var audio: DeepFocusAudioService { DeepFocusAudioService.shared }

    private var remaining: TimeInterval {
        max(0, totalDuration - (isSeeking ? seekTime : elapsed))
    }

    var body: some View {
        GeometryReader { geo in
            let artworkSize = max(0, geo.size.width - 56)

            ZStack {

                VStack(spacing: 0) {
                    Spacer()

                    // Artwork
                    Image("guided_meditation")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: artworkSize, height: artworkSize)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)

                    Spacer().frame(height: 32)

                    // Title + Favourite
                    titleRow.padding(.horizontal, 28)

                    Spacer().frame(height: 20)

                    // Progress
                    progressSection.padding(.horizontal, 28)

                    Spacer().frame(height: 36)

                    // Controls
                    playbackControls

                    Spacer().frame(height: 36)

                    // Volume
                    volumeSlider.padding(.horizontal, 28)

                    Spacer()
                }
                .frame(maxWidth: .infinity)

                if showCompletion {
                    completionOverlay
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showCompletion)
        }
        .background(AppTheme.appGradient.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBar()
        .onAppear {
            loadFavourite()
            startSession()
        }
        .onDisappear {
            stopTimer()
            audio.stop()
        }
    }

    // MARK: - Subviews

    private var titleRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Creating Mental Space")
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(1)

                Text("Deep Focus Guided Meditation")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button { toggleFavourite() } label: {
                Image(systemName: isFavourite ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundStyle(isFavourite ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var progressSection: some View {
        VStack(spacing: 6) {
            Slider(
                value: Binding(
                    get: { isSeeking ? seekTime : elapsed },
                    set: { newValue in
                        seekTime = newValue
                        isSeeking = true
                    }
                ),
                in: 0...max(totalDuration, 1),
                onEditingChanged: { editing in
                    if !editing {
                        seek(to: seekTime)
                        isSeeking = false
                    }
                }
            )
            .tint(Color(.systemGray))

            HStack {
                Text(formatTime(isSeeking ? seekTime : elapsed))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()

                Spacer()

                Text("-\(formatTime(remaining))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }

    private var playbackControls: some View {
        HStack(spacing: 44) {
            Button {
                toggleMute()
            } label: {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.title2)
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)

            Button {
                if isPlaying {
                    pauseSession()
                } else if hasStarted {
                    resumeSession()
                } else {
                    startSession()
                }
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(Color.accentColor))
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)

            Button { resetSession() } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
        }
    }

    private var volumeSlider: some View {
        HStack(spacing: 10) {
            Image(systemName: "speaker.fill")
                .font(.caption)
                .foregroundStyle(.secondary)

            Slider(value: $volume, in: 0...1)
                .tint(Color(.systemGray))
                .onChange(of: volume) { _, newVol in
                    isMuted = (newVol == 0)
                    audio.setVolume(Float(newVol))
                }

            Image(systemName: "speaker.wave.3.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    showCompletion = false
                    dismiss()
                }

            VStack(spacing: 20) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.accentColor)

                Text("Namaste 🙏")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("You completed a \(Int(round(totalDuration / 60)))-minute\nGuided Meditation session")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text("+ 50 Focus Points")
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)

                Button {
                    showCompletion = false
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            Capsule()
                                .fill(Color.accentColor)
                                .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                }
                .padding(.top, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 40)
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    // MARK: - Favourite

    private func loadFavourite() {
        isFavourite = UserDefaults.standard.bool(forKey: Self.favouriteKey)
    }

    private func toggleFavourite() {
        isFavourite.toggle()
        UserDefaults.standard.set(isFavourite, forKey: Self.favouriteKey)
    }

    // MARK: - Session Logic

    private func startSession() {
        audio.onFinished = { [self] in
            completeSession()
        }
        audio.play()
        if audio.duration > 0 {
            totalDuration = audio.duration
        }
        audio.setVolume(isMuted ? 0 : Float(volume))
        isPlaying = true
        hasStarted = true
        startTimer()
    }

    private func pauseSession() {
        audio.pause()
        isPlaying = false
        stopTimer()
    }

    private func resumeSession() {
        audio.resume()
        isPlaying = true
        startTimer()
    }

    private func resetSession() {
        audio.seek(to: 0)
        elapsed = 0
        seekTime = 0
        if !isPlaying {
            audio.play()
            isPlaying = true
            startTimer()
        }
    }

    private func seek(to time: TimeInterval) {
        audio.seek(to: time)
        elapsed = time
    }

    private func toggleMute() {
        isMuted.toggle()
        if isMuted {
            audio.setVolume(0)
        } else {
            audio.setVolume(Float(volume > 0 ? volume : 0.5))
        }
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            guard !isSeeking else { return }
            elapsed = audio.currentTime
            if audio.duration > 0 {
                totalDuration = audio.duration
            }
            if elapsed >= totalDuration && totalDuration > 0 {
                completeSession()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func completeSession() {
        stopTimer()
        audio.stop()
        isPlaying = false
        hasStarted = false

        Task {
            await store.logGuidedMeditationSession(
                userId: userId,
                meditationName: "Creating Mental Space",
                durationSeconds: Int(totalDuration)
            )
        }

        showCompletion = true
    }
}

#Preview {
    NavigationStack {
        DeepFocusBrowseView()
            .environment(CalmCentreStore.shared)
    }
}
