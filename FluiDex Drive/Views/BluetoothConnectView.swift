import SwiftUI
import CoreBluetooth
import AVFoundation
import Combine   // ✅ Добавь эту строчку


struct BluetoothConnectView: View {
    @StateObject private var manager = BluetoothManager()
    @State private var pulse = false
    @State private var rotation: Double = 0
    @State private var radarGlow = false
    @State private var rotationSpeed: Double = 2.0
    @State private var lastDeviceCount = 0
    
    var body: some View {
        ZStack {
            // 🌌 FluiDex Drive фон
            LinearGradient(
                colors: [.black, Color(hex: "#1A1A40")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // 💫 Заголовок
                Text("Vehicle Bluetooth")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .glow(color: .cyan, radius: 14)
                    .padding(.top, 10)
                
                // 🌀 Неоновый HUD-радар
                if manager.connectedPeripheral == nil {
                    ZStack {
                        // Пульсирующие кольца
                        ForEach(0..<3) { i in
                            Circle()
                                .stroke(
                                    LinearGradient(colors: [.cyan.opacity(0.8), .blue.opacity(0.4)],
                                                   startPoint: .topLeading,
                                                   endPoint: .bottomTrailing),
                                    lineWidth: 1.2
                                )
                                .frame(width: CGFloat(160 + i * 60), height: CGFloat(160 + i * 60))
                                .opacity(pulse ? 0.1 : 0.4)
                                .scaleEffect(pulse ? 1.3 : 0.9)
                                .animation(
                                    .easeInOut(duration: 2)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.5),
                                    value: pulse
                                )
                        }
                        
                        // Вращающийся сектор радара
                        Circle()
                            .trim(from: 0, to: 0.15)
                            .stroke(
                                AngularGradient(gradient: Gradient(colors: [.cyan, .blue, .clear]),
                                                center: .center),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .frame(width: 220, height: 220)
                            .rotationEffect(.degrees(rotation))
                            .shadow(color: radarGlow ? .cyan.opacity(0.9) : .cyan.opacity(0.5),
                                    radius: radarGlow ? 15 : 6)
                            .animation(.easeInOut(duration: 0.8), value: radarGlow)
                            .onAppear {
                                withAnimation(.linear(duration: rotationSpeed)
                                    .repeatForever(autoreverses: false)) {
                                        rotation = 360
                                    }
                            }
                        
                        // Центральная иконка машины
                        Image(systemName: "car.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.cyan)
                            .shadow(color: .cyan.opacity(0.9), radius: 10)
                            .scaleEffect(pulse ? 1.1 : 0.9)
                            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
                    }
                    .frame(height: 250)
                    .onAppear { pulse = true }
                    
                    // ✨ Надпись “Scanning...”
                    Text("Scanning for devices…")
                        .font(.headline)
                        .foregroundColor(.cyan)
                        .opacity(pulse ? 1 : 0.3)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulse)
                        .padding(.top, -10)
                }
                
                // 🟢 Bluetooth статус
                Text(manager.status)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(manager.status.contains("Connected") ? .green : .cyan)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                    .background(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: manager.status.contains("Connected")
                                        ? [.green, .mint]
                                        : [.cyan.opacity(0.8), .blue.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .cornerRadius(20)
                    .shadow(color: .cyan.opacity(0.4), radius: 10)
                    .animation(.easeInOut, value: manager.status)
                
                // 📡 Список устройств
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(manager.peripherals, id: \.identifier) { device in
                            Button {
                                manager.connect(to: device)
                            } label: {
                                HStack(spacing: 15) {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                        .foregroundColor(.cyan)
                                        .shadow(color: .cyan.opacity(0.8), radius: 6)
                                        .font(.title3)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(device.name ?? "Unknown Device")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text(manager.connectedPeripheral?.identifier == device.identifier
                                             ? "Connected"
                                             : "Tap to connect")
                                            .font(.caption)
                                            .foregroundColor(manager.connectedPeripheral?.identifier == device.identifier ? .green : .gray)
                                    }
                                    
                                    Spacer()
                                    
                                    if manager.connectedPeripheral?.identifier == device.identifier {
                                        Circle()
                                            .fill(.green)
                                            .frame(width: 10, height: 10)
                                            .shadow(color: .green.opacity(0.7), radius: 6)
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            LinearGradient(
                                                colors: [.cyan.opacity(0.6), .blue.opacity(0.5)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.4
                                        )
                                )
                                .cornerRadius(16)
                                .shadow(color: .cyan.opacity(0.3), radius: 8)
                                .glow(color: manager.connectedPeripheral?.identifier == device.identifier ? .green : .cyan, radius: 5)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 340)
                .scrollIndicators(.hidden)
                
                // 🔘 Disconnect
                if manager.connectedPeripheral != nil {
                    NeonButton(title: "Disconnect") {
                        manager.disconnect()
                    }
                    .padding(.horizontal, 40)
                }
            }
            .padding()
            .alert("Bluetooth Alert", isPresented: $manager.showAlert) {
                Button("OK", role: .cancel) { }
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text(manager.alertMessage)
            }
        }
        // 🎯 Реакция радара на новые устройства
        .onReceive(manager.$peripherals.map(\.count)) { newValue in
            if newValue > lastDeviceCount {
                SoundManager.shared.playPing()
                withAnimation(.easeInOut(duration: 0.4)) {
                    radarGlow = true
                    rotationSpeed = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeOut(duration: 1.5)) {
                        radarGlow = false
                        rotationSpeed = 2.0
                    }
                }
            }
            lastDeviceCount = newValue
        }



    }
}

#Preview {
    BluetoothConnectView()
}
