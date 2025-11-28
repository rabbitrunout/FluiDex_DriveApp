import SwiftUI

struct OBDLiveDataView: View {
    @StateObject private var obd = OBDService()

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()

            VStack(spacing: 20) {
                Text(obd.isConnected ? "Connected to OBD-II" : "Scanning for OBD device…")
                    .font(.headline)
                    .foregroundColor(.white)

                if obd.isConnected {
                    Group {
                        HStack { Label("Speed", systemImage: "speedometer"); Spacer(); Text("\(obd.speed) km/h") }
                        HStack { Label("RPM", systemImage: "gauge.with.dots"); Spacer(); Text("\(obd.rpm)") }
                        HStack { Label("Coolant Temp", systemImage: "thermometer"); Spacer(); Text("\(obd.coolantTemp) °C") }
                        HStack { Label("VIN", systemImage: "car.fill"); Spacer(); Text(obd.vin.isEmpty ? "—" : obd.vin) }
                    }
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                }

                Spacer()
            }
            .padding(.top, 50)
        }
    }
}

#Preview { OBDLiveDataView() }
