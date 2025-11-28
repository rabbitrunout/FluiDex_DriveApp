import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    private var player: AVAudioPlayer?

    func playPing() {
        // Ищем звук ping.wav в проекте
        guard let url = Bundle.main.url(forResource: "ping", withExtension: "wav") else {
            print("⚠️ Ping sound file not found")
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = 0.5
            player?.play()
        } catch {
            print("Error playing sound: \(error.localizedDescription)")
        }
    }
}
