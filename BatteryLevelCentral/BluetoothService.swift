//
//  BluetoothService.swift
//  BatteryLevelCentral
//
//  Created by Vladislav Kleschenko on 12/15/19.
//  Copyright © 2019 Vladislav Kleschenko. All rights reserved.
//

import Foundation
import CoreBluetooth

struct PeripheralData: Hashable {
    let uuid: UUID
    let name: String
    var batteryLevel: Int
    let peripheral: CBPeripheral
}

final class BluetoothService: NSObject {

    static let shared = BluetoothService()

    private let myServiceUUID = CBUUID(string: "5FC769E5-2532-4EB2-9FBD-DF419466C2B2")
    private let myCharasteristicUUID = CBUUID(string: "5E6BC5A4-AC32-41D7-8804-A43BAD288457")

    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?

    private(set) var peripherals = [PeripheralData]()

    var didUpdateValue: () -> () = {}

    override init() {
        super.init()

        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    private func decode(data: Data) -> Int {
        var byte: UInt8 = 0
        data.copyBytes(to: &byte, count: 1)
        return Int(byte)
    }
}

extension BluetoothService: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("start scanning for peripherals")
            centralManager.scanForPeripherals(withServices: [myServiceUUID], options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("didDiscover peripheral RSSI: \(RSSI)")

        central.connect(peripheral, options: nil)

        let peripheralData = PeripheralData(uuid: peripheral.identifier, name: peripheral.name ?? "Unknown", batteryLevel: 0, peripheral: peripheral)
        if peripherals.first(where: { $0.uuid == peripheral.identifier }) == nil {
            peripherals.append(peripheralData)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("didConnect to Peripheral: \(peripheral.identifier)")

        peripheral.delegate = self
        peripheral.discoverServices([myServiceUUID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("didDisconnectPeripheral: \(peripheral.identifier)")

        peripherals.removeAll(where: { $0.uuid == peripheral.identifier })
        didUpdateValue()
    }
}

extension BluetoothService: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("Error: \(String(describing: error)) on didDiscoverServices")
            return
        }

        print("didDiscoverServices")

        peripheral.services?.filter { $0.uuid == myServiceUUID }.forEach { service in
            peripheral.discoverCharacteristics([myCharasteristicUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("Error: \(String(describing: error)) on didDiscoverCharacteristicsFor service: \(service.uuid)")
            return
        }
        print("didDiscoverCharacteristicsFor service: \(service.uuid)")

        let characteristic = service.characteristics!.first!
        peripheral.setNotifyValue(true, for: characteristic)
        peripheral.readValue(for: characteristic)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Error: \(String(describing: error)) on didUpdateValueFor: \(characteristic)")
            return
        }
        guard let index = peripherals.firstIndex(where: {$0.uuid == peripheral.identifier }) else { fatalError() }
        if let data = characteristic.value {
            peripherals[index].batteryLevel = decode(data: data)
            didUpdateValue()
        }
    }
}
