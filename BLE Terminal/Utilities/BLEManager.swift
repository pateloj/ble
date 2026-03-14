//
//  BLEManager.swift
//  BLE Terminal
//
//  Created by Ashwin Gattani on 08/09/25.
//

import SwiftUI
import CoreBluetooth

// MARK: - Models
struct PeripheralInfo: Identifiable, Hashable {
    let id: UUID
    let name: String
    let peripheral: CBPeripheral
    var rssi: Int
}

// MARK: - BLE Manager
final class BLEManager: NSObject, ObservableObject {
    private var central: CBCentralManager!
    @Published var isPoweredOn: Bool = false
    @Published var isScanning: Bool = false
    @Published var devices: [PeripheralInfo] = []
    @Published var connectedPeripheral: CBPeripheral? = nil
    private var writeCharacteristic: CBCharacteristic? = nil
    private var notifyCharacteristic: CBCharacteristic? = nil
    private var isRequestInProgress: Bool = false
    private var requestQueue: [String] = []
    private var timer: Timer?

    @Published var receivedText: String = ""
    @Published var logLines: [String] = []

    var preferredServiceUUID: CBUUID? = nil
    var preferredWriteCharacteristicUUID: CBUUID? = nil
    var preferredNotifyCharacteristicUUID: CBUUID? = nil

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    func startScan() {
        guard isPoweredOn else { appendLog("Bluetooth is not powered on"); return }
        devices.removeAll()
        central.scanForPeripherals(withServices: preferredServiceUUID != nil ? [preferredServiceUUID!] : nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        isScanning = true
        appendLog("Started scanning…")
    }

    func stopScan() {
        central.stopScan()
        isScanning = false
        appendLog("Stopped scanning.")
    }

    func connect(_ info: PeripheralInfo) {
        stopScan()
        connectedPeripheral = info.peripheral
        writeCharacteristic = nil
        notifyCharacteristic = nil
        info.peripheral.delegate = self
        central.connect(info.peripheral, options: nil)
        appendLog("Connecting to \(info.name) …")
    }

    func connectByUUIDString(_ uuidString: String) {
        guard let uuid = UUID(uuidString: uuidString) else { appendLog("Invalid UUID format"); return }
        let peripherals = central.retrievePeripherals(withIdentifiers: [uuid])
        guard let p = peripherals.first else { appendLog("No known peripheral with that UUID. It must be discovered at least once first."); return }
        stopScan()
        connectedPeripheral = p
        writeCharacteristic = nil
        notifyCharacteristic = nil
        p.delegate = self
        central.connect(p, options: nil)
        appendLog("Connecting to known peripheral: \(p.name ?? "(unknown)") …")
    }

    func disconnect() {
        if let p = connectedPeripheral {
            central.cancelPeripheralConnection(p)
        }
    }

    func sendData(_ text: String) {
        if(!isRequestInProgress) {
            sendASCII(text)
        } else {
            requestQueue.append(text)
        }
    }
    
    private func sendASCII(_ text: String) {
        guard let p = connectedPeripheral, let ch = writeCharacteristic else {
            appendLog("No writable characteristic available.")
            return
        }
        guard let data = text.data(using: .utf8) else {
            appendLog("Failed to encode text as UTF-8.")
            return
        }
        
        let writeType: CBCharacteristicWriteType = ch.properties.contains(.writeWithoutResponse) ? .withoutResponse : .withResponse
        p.writeValue(data, for: ch, type: writeType)
        appendLog("➡️ Sent: \(text)")
    }

    private func appendLog(_ line: String) {
        print(line)
        logLines.append("[\(timestamp())] \(line)")
    }

    private func timestamp() -> String {
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss"
        return df.string(from: Date())
    }
}

//MARK: - Timer
extension BLEManager {
    private func runQueueTimer() {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                let text = self.requestQueue.isEmpty ? nil : self.requestQueue.removeFirst()
                if(text != nil) {
                    self.isRequestInProgress = true
                    self.sendASCII(text!)
                }
            }
        }

        private func stopQueueTimer() {
            timer?.invalidate()
            timer = nil
        }
}

// MARK: - CBCentralManagerDelegate
extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isPoweredOn = (central.state == .poweredOn)
        appendLog("Central state: \(central.state.rawValue)")
        if central.state != .poweredOn {
            isScanning = false
            devices.removeAll()
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let name = peripheral.name ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? "(unknown)"
        let info = PeripheralInfo(id: peripheral.identifier, name: name, peripheral: peripheral, rssi: RSSI.intValue)
        if let idx = devices.firstIndex(where: { $0.id == info.id }) {
            devices[idx].rssi = info.rssi
        } else {
            if info.name.contains("AWS") {
                devices.append(info)
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        appendLog("✅ Connected: \(peripheral.name ?? peripheral.identifier.uuidString)")
        peripheral.discoverServices(preferredServiceUUID != nil ? [preferredServiceUUID!] : nil)
        isRequestInProgress = false
        runQueueTimer()
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        appendLog("❌ Failed to connect: \(error?.localizedDescription ?? "unknown error")")
        connectedPeripheral = nil
        isRequestInProgress = false
        stopQueueTimer()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        appendLog("🔌 Disconnected: \(error?.localizedDescription ?? "user initiated")")
        connectedPeripheral = nil
        isRequestInProgress = false
        stopQueueTimer()
    }
}

// MARK: - CBPeripheralDelegate
extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error { appendLog("Service discovery error: \(error.localizedDescription)"); return }
        guard let services = peripheral.services, !services.isEmpty else { appendLog("No services found."); return }
        appendLog("Discovered \(services.count) services")
        for svc in services {
            if preferredServiceUUID == nil || svc.uuid == preferredServiceUUID { peripheral.discoverCharacteristics(nil, for: svc) }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error { appendLog("Characteristic discovery error: \(error.localizedDescription)"); return }
        guard let chars = service.characteristics else { return }
        for ch in chars {
            if notifyCharacteristic == nil {
                if let preferred = preferredNotifyCharacteristicUUID, ch.uuid == preferred, ch.properties.contains(.notify) {
                    notifyCharacteristic = ch
                } else if preferredNotifyCharacteristicUUID == nil && ch.properties.contains(.notify) {
                    notifyCharacteristic = ch
                }
                if let n = notifyCharacteristic { peripheral.setNotifyValue(true, for: n); appendLog("Subscribed to notifications on \(n.uuid.uuidString)") }
            }
            if writeCharacteristic == nil {
                let isWritable = ch.properties.contains(.write) || ch.properties.contains(.writeWithoutResponse)
                if let preferred = preferredWriteCharacteristicUUID, ch.uuid == preferred, isWritable {
                    writeCharacteristic = ch
                } else if preferredWriteCharacteristicUUID == nil && isWritable {
                    writeCharacteristic = ch
                }
                if let w = writeCharacteristic { appendLog("Writable characteristic: \(w.uuid.uuidString)") }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error { appendLog("Notify update error: \(error.localizedDescription)"); return }
        guard let data = characteristic.value else { return }
        let text = String(data: data, encoding: .utf8) ?? data.map { String(format: "%02X", $0) }.joined()
        receivedText.append(text)
        if !text.hasSuffix("\n") { receivedText.append("\n") }
        appendLog("⬅️ Received: \(text.trimmingCharacters(in: .newlines))")
        
        isRequestInProgress = false
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error { appendLog("Write error: \(error.localizedDescription)") }
    }
}
