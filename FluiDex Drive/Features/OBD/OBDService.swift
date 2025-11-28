import Foundation
import CoreBluetooth
import Combine

class OBDService: NSObject, ObservableObject {
    @Published var speed: Int = 0
    @Published var rpm: Int = 0
    @Published var coolantTemp: Int = 0
    @Published var vin: String = ""
    @Published var isConnected = false

    private var centralManager: CBCentralManager!
    private var obdPeripheral: CBPeripheral?

    private let obdServiceUUID = CBUUID(string: "FFF0")
    private let writeUUID = CBUUID(string: "FFF2")
    private let notifyUUID = CBUUID(string: "FFF1")

    private var writeCharacteristic: CBCharacteristic?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    func startScan() {
        guard centralManager.state == .poweredOn else { return }
        centralManager.scanForPeripherals(withServices: nil)
    }

    private func sendCommand(_ command: String) {
        guard let peripheral = obdPeripheral,
              let writeChar = writeCharacteristic else { return }
        if let data = "\(command)\r".data(using: .utf8) {
            peripheral.writeValue(data, for: writeChar, type: .withResponse)
        }
    }

    func requestBasicData() {
        sendCommand("010D")
        sendCommand("010C")
        sendCommand("0105")
        sendCommand("0902")
    }

    private func parseResponse(_ string: String) {
        if string.contains("41 0D"),
           let value = string.split(separator: " ").last,
           let intVal = Int(value, radix: 16) {
            speed = intVal
        } else if string.contains("41 0C") {
            let bytes = string.split(separator: " ").suffix(2)
            if bytes.count == 2,
               let a = Int(bytes.first!, radix: 16),
               let b = Int(bytes.last!, radix: 16) {
                rpm = (256 * a + b) / 4
            }
        } else if string.contains("41 05"),
                  let value = string.split(separator: " ").last,
                  let intVal = Int(value, radix: 16) {
            coolantTemp = intVal - 40
        } else if string.contains("49 02") {
            vin = string.replacingOccurrences(of: " ", with: "")
        }
    }
}

extension OBDService: CBCentralManagerDelegate, CBPeripheralDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn { startScan() }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        if (peripheral.name ?? "").contains("OBD") || (peripheral.name ?? "").contains("ELM") {
            central.stopScan()
            obdPeripheral = peripheral
            obdPeripheral?.delegate = self
            central.connect(peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        peripheral.discoverServices(nil)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services where service.uuid == obdServiceUUID {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard let chars = service.characteristics else { return }
        for char in chars {
            if char.uuid == writeUUID { writeCharacteristic = char }
            if char.uuid == notifyUUID { peripheral.setNotifyValue(true, for: char) }
        }

        // ⚙️ Инициализация адаптера
        sendCommand("ATZ")
        sendCommand("ATE0")
        sendCommand("ATL0")
        sendCommand("ATS0")
        sendCommand("ATSP0")

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.requestBasicData()
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard let data = characteristic.value,
              let string = String(data: data, encoding: .utf8) else { return }
        parseResponse(string)
    }
}
