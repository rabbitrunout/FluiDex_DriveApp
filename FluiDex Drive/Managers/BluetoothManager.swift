import Foundation
import CoreBluetooth
import Combine
import SwiftUI

// 👾 Модель фейкового устройства для демо-режима
struct DemoBluetoothDevice: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let subtitle: String
}

@MainActor
class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    // 🔌 Реальные устройства
    @Published var peripherals: [CBPeripheral] = []
    @Published var connectedPeripheral: CBPeripheral?

    // 👾 Демо-устройства
    @Published var demoDevices: [DemoBluetoothDevice] = []
    @Published var connectedDemoDevice: DemoBluetoothDevice?

    // ⚙️ Статусы
    @Published var status: String = "🔍 Scanning..."
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""

    // 🚦 Флаг демо-режима
    @Published var isDemoMode: Bool = false

    private var centralManager: CBCentralManager?
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()

        #if targetEnvironment(simulator)
        // 🧪 Симулятор → сразу включаем демо-режим
        isDemoMode = true
        status = "🟣 Demo Mode — simulated devices"
        demoDevices = [
            DemoBluetoothDevice(name: "FluiDex Demo Car", subtitle: "OBD-II • Battery • RPM"),
            DemoBluetoothDevice(name: "Family SUV • Demo", subtitle: "Tire pressure • Oil life"),
            DemoBluetoothDevice(name: "Test OBD-II Adapter", subtitle: "Debug mode")
        ]
        #else
        // 📡 Реальное устройство → обычный Bluetooth
        centralManager = CBCentralManager(delegate: self, queue: nil)
        #endif
    }

    // MARK: - Bluetooth State (реальный режим)

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard !isDemoMode else { return } // в демо-режиме сюда не заходим

        switch central.state {
        case .poweredOn:
            status = "🟢 Bluetooth ON — Scanning..."
            centralManager?.scanForPeripherals(withServices: nil)
        case .poweredOff:
            status = "🔴 Bluetooth OFF"
            alertMessage = "Please enable Bluetooth in Settings."
            showAlert = true
        case .unauthorized:
            status = "🚫 Access Denied"
            alertMessage = "Bluetooth access not authorized. Go to Settings → Privacy → Bluetooth."
            showAlert = true
        case .unsupported:
            status = "⚠️ Bluetooth not supported on this device."
            alertMessage = "Your device does not support Bluetooth."
            showAlert = true
        default:
            status = "Bluetooth unavailable"
        }
    }

    // MARK: - Discover Devices (реальный режим)

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        guard !isDemoMode else { return }

        if !peripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            peripherals.append(peripheral)
        }
    }

    // MARK: - Connect Device (реальный режим)

    func connect(to peripheral: CBPeripheral) {
        guard !isDemoMode else { return }

        centralManager?.stopScan()
        connectedPeripheral = peripheral
        peripheral.delegate = self
        centralManager?.connect(peripheral, options: nil)
        status = "Connecting to \(peripheral.name ?? "device")..."
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard !isDemoMode else { return }
        status = "✅ Connected to \(peripheral.name ?? "device")"
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        guard !isDemoMode else { return }
        status = "❌ Failed to connect"
        alertMessage = "Connection failed: \(error?.localizedDescription ?? "unknown error")"
        showAlert = true
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        guard !isDemoMode else { return }
        status = "🔌 Disconnected"
        connectedPeripheral = nil
        centralManager?.scanForPeripherals(withServices: nil)
    }

    // MARK: - Disconnect (общий)

    func disconnect() {
        if isDemoMode {
            // 👾 Демо-отключение
            connectedDemoDevice = nil
            status = "🟣 Demo Mode — not connected"
        } else if let peripheral = connectedPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
    }

    // MARK: - DEMO: Connect Device

    func connectDemo(to device: DemoBluetoothDevice) {
        guard isDemoMode else { return }
        connectedDemoDevice = device
        status = "✅ Connected to \(device.name) (demo)"
    }
}
