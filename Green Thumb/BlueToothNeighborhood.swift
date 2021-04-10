//
//  BlueToothNeighborhood.swift
//  Green Thumb
//
//  Created by Jacob Mayl on 4/5/21.
// copied originally from cypress github, changed a lot to update to our project and new xcode standards
import CoreBluetooth
import Foundation
import Compression


private struct BLEParameters {
    static let nurseryService = CBUUID(string: "00000000-0000-1000-8000-00805F9B34F0")
    static let ledCharactersticUUID = CBUUID(string:"00000000-0000-1000-8000-00805F9B34F1")
    static let capsenseCharactersticUUID = CBUUID(string:"00000000-0000-1000-8000-00805F9B34F2")
}

class BlueToothNeighborhood: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate  {
    
    private var centralManager : CBCentralManager!
    private var nurseryBoard : CBPeripheral?
    private var nurseryService : CBService!
    private var ledCharacteristic : CBCharacteristic!
    private var capsenseCharacteristic : CBCharacteristic!
    
    
    // MARK: - Functions to start of the central manager
    
    func startUpCentralManager() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    @objc func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch (central.state) {
        case .poweredOff: break
        case .poweredOn:
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: RCNotifications.BluetoothReady), object: nil)
            print("Bluetooth is on")
        case .resetting: break
        case .unauthorized: break
        case .unknown:break
        case .unsupported:break
        }
    }
    
    // MARK: - Functions to discover ble devices
    
    func discoverDevice() {
        print("Starting scan")
        centralManager.scanForPeripherals(withServices: [BLEParameters.nurseryService], options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
    }
    /*
    func centralManager( didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], rssi: NSNumber)
    {
        if nurseryBoard == nil {
            print("Found a new Periphal advertising capsense led service")
            nurseryBoard = peripheral
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: RCNotifications.FoundDevice), object: nil)
            centralManager.stopScan()
    } */
         func centralManager(_: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : AnyObject], rssi: NSNumber)
         {
             if nurseryBoard == nil {
                 print("Found a new Periphal advertising capsense led service")
                 nurseryBoard = peripheral
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: RCNotifications.FoundDevice), object: nil)
                 centralManager.stopScan()
             }
         }
    
    // MARK: - Functions to connect to a device
    func connectToDevice()
    {
        centralManager.connect(nurseryBoard!, options: nil)
    }
    
    // a device connection is complete
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("Connection complete \(nurseryBoard) \(peripheral)")
        nurseryBoard!.delegate = self
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: RCNotifications.ConnectionComplete), object: nil)
    }
    
    
    // MARK: - Functions to discover the services on a device
    func discoverServices()
    {
        nurseryBoard!.discoverServices(nil)
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        print("discovered services")
        for service in peripheral.services! {
            print("Found service \(service)")
            if service.uuid == BLEParameters.nurseryService {
                nurseryService = service // as! CBService
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: RCNotifications.ServiceScanComplete), object: nil)
        
    }
    
    // MARK: - Functions to discover the characteristics
    
    func discoverCharacteristics()
    {
        nurseryBoard!.discoverCharacteristics(nil, for: nurseryService)
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        for characteristic in service.characteristics!
        {
            
            print("Found characteristic \(characteristic)")
            switch characteristic.uuid {
            case BLEParameters.capsenseCharactersticUUID:  capsenseCharacteristic = characteristic
            case BLEParameters.ledCharactersticUUID: ledCharacteristic = characteristic
            default: break
            }
            
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: RCNotifications.CharacteristicScanComplete), object: nil)
    }
    
    // MARK: - Functions to handle disconnection
    func disconnectDevice()
    {
        centralManager.cancelPeripheralConnection(nurseryBoard!)
    }
    
    // disconnected a device
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("Disconnected \(peripheral)")
        nurseryBoard = nil
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: RCNotifications.DisconnectedDevice), object: nil)
    }
    
    
    // MARK: - Functions to write/read from the device
    func writeLedCharacteristic( val: inout Int8)
    {
        let ns = NSData(bytes: &val, length: 1)  //guessing that int8 has length 1 (byte?)
        nurseryBoard!.writeValue(ns as Data, for: ledCharacteristic, type: CBCharacteristicWriteType.withResponse)
    }
    
    func writeCapsenseNotify(state: Bool)
    {
        nurseryBoard!.setNotifyValue(state, for: capsenseCharacteristic)
    }
    
    var capsenseValue = 0
    
    // This delegate function is called when an updated value is received from the Bluetooth Stack
    // this is important but just throws errors so for now it does nothing.
    func peripheral(_: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic == capsenseCharacteristic {
            var out: NSInteger = 0
            //characteristic.value!.getBytes(&out, length:8)  // guessing NSInteger is 8 bytes
            capsenseValue = out
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: RCNotifications.UpdatedCapsense), object: nil)
        }
    }
    
}
