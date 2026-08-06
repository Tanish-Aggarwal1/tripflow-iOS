import AVFoundation

/// Author: Pratham
/// Reusable singleton for playing the app's short completion chime (FR9's Sound requirement).
final class SoundManager {

    /// Shared singleton instance; the player is created once and reused.
    static let shared = SoundManager()

    /// Player holding the loaded chime, kept alive between calls so playback isn't cut short.
    private var player: AVAudioPlayer?

    private init() {}

    /// Plays the chime once from the start, loading it lazily on first use.
    /// No-ops if chime.m4a can't be found or loaded.
    func playChime() {
        if player == nil {
            guard let url = Bundle.main.url(forResource: "chime", withExtension: "m4a") else {
                print("SoundManager: chime.m4a not found in bundle")
                return
            }
            do {
                player = try AVAudioPlayer(contentsOf: url)
            } catch {
                print("SoundManager: failed to load chime.m4a - \(error)")
                return
            }
        }

        player?.currentTime = 0
        player?.play()
    }
}
