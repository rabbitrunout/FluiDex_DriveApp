import SwiftUI

struct TripHUDView: View {
    @StateObject private var tripManager = TripManager()

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Trip Tracker")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Circle()
                    .fill(tripManager.isTracking ? Color.green : Color.gray)
                    .frame(width: 10, height: 10)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Distance")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Text(String(format: "%.2f km", tripManager.distanceKm))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.cyan)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Duration")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Text(formatTime(tripManager.duration))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.cyan)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Speed")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Text(String(format: "%.0f km/h", tripManager.currentSpeedKmh))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.cyan)
                }
            }

            HStack(spacing: 16) {
                Button(action: {
                    tripManager.start()
                }) {
                    Label("Start", systemImage: "play.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(colors: [.cyan, .blue],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing)
                        )
                        .foregroundColor(.black)
                        .cornerRadius(20)
                }

                Button(action: {
                    tripManager.stop()
                }) {
                    Label("Stop", systemImage: "stop.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
            }

            Text(tripManager.statusText)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .cornerRadius(20)
        .shadow(color: .cyan.opacity(0.4), radius: 10, y: 5)
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let sec = Int(interval)
        let h = sec / 3600
        let m = (sec % 3600) / 60
        let s = sec % 60
        if h > 0 {
            return String(format: "%02d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [.black, Color(hex: "#1A1A40")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        TripHUDView()
            .padding()
    }
}
