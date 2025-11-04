import Foundation
import CoreBluetooth
import Combine
import SwiftUI

@MainActor
class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var peripherals: [CBPeripheral] = []
    @Published var connectedPeripheral: CBPeripheral?
    @Published var status: String = "🔍 Scanning..."
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    
    private var centralManager: CBCentralManager!
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Bluetooth State
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            status = "🟢 Bluetooth ON — Scanning..."
            centralManager.scanForPeripherals(withServices: nil)
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
    
    // MARK: - Discover Devices
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        if !peripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            peripherals.append(peripheral)
        }
    }
    
    // MARK: - Connect Device
    func connect(to peripheral: CBPeripheral) {
        centralManager.stopScan()
        connectedPeripheral = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
        status = "Connecting to \(peripheral.name ?? "device")..."
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        status = "✅ Connected to \(peripheral.name ?? "device")"
    }
    
    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        status = "❌ Failed to connect"
        alertMessage = "Connection failed: \(error?.localizedDescription ?? "unknown error")"
        showAlert = true
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        status = "🔌 Disconnected"
        connectedPeripheral = nil
        centralManager.scanForPeripherals(withServices: nil)
    }
    
    // MARK: - Disconnect
    func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
}
