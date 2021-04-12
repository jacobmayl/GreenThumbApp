
//
//  ViewController.swift
//  Green Thumb
//
//  Created by Jacob Mayl on 3/28/21.
//

import UIKit
import CoreBluetooth
//import BlueToothNeightborhood

// save all UUIDS for use here
private struct BLEParamters {
    //get reading service:
    static let getReadingsServiceUUID = CBUUID(string: "AF7A")
    static let tempCharacteristicUUID = CBUUID(string: "2A6E")
    static let moistCharacteristicUUID = CBUUID(string: "2A6F")
    static let phCharacteristicUUID = CBUUID(string: "2A70")
    //water service:
    static let waterServiceUUID = CBUUID(string: "AAAA")
    static let waterNowCharacteristicUUID = CBUUID(string: "A001")
    static let waterFreqCharacteristicUUID = CBUUID(string: "A002")
    static let waterTimeCharacteristicUUID = CBUUID(string: "A003")
    static let automateCharacteristicUUID = CBUUID(string: "A004")
    static let waterOptionCharacteristicUUID = CBUUID(string: "A005")
    //light service:
    static let lightServiceUUID = CBUUID(string: "BBBB")
    static let toggleLightsCharacteristicUUID = CBUUID(string: "B001")
    static let timeTillStartCharacteristicUUID = CBUUID(string: "B002")
    static let lightTimeCharacteristicUUID = CBUUID(string: "B003")
    static let lightOptionCharacteristicUUID = CBUUID(string: "B004")
}


struct RCNotifications {
    static let BluetoothReady = "team7.greenthumb.bluetoothReady"
    static let FoundDevice = "team7.greenthumb.founddevice"
    static let ConnectionComplete = "team7.greenthumb.connectioncomplete"
    static let ServiceScanComplete = "team7.greenthumb.servicescancomplete"
    static let CharacteristicScanComplete = "team7.greenthumb.characteristicsscancomplete"
    static let DisconnectedDevice = "team7.greenthumb.disconnecteddevice"
    static let UpdatedCapsense = "team7.greenthumb.updatedcapsense"
}

struct ble {
    //peripheral is board
    static var myPeripheral: CBPeripheral!
    // Vars for Get Readings Service:
    static var getReadingsService : CBService? = nil
    static var tempCharacteristic : CBCharacteristic? = nil
    static var moistCharacteristic : CBCharacteristic? = nil
    static var phCharacteristic : CBCharacteristic? = nil
    //vars for water service
    static var waterService : CBService? = nil
    static var waterNowCharacteristic : CBCharacteristic? = nil
    static var waterFreqCharacteristic : CBCharacteristic? = nil
    static var waterTimeCharacteristic : CBCharacteristic? = nil
    static var automateCharacteristic : CBCharacteristic? = nil
    static var waterOptionCharacteristic : CBCharacteristic? = nil
    //vars for light service
    static var lightService : CBService? = nil
    static var toggleLightsCharacteristic : CBCharacteristic? = nil
    static var timeTillStartCharacteristic : CBCharacteristic? = nil
    static var lightTimeCharacteristic : CBCharacteristic? = nil
    static var lightOptionCharacteristic : CBCharacteristic? = nil
}


class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    //properties:
    var centralManager: CBCentralManager!  //central is phone
    var myPeripheral: CBPeripheral!
    
    
    //for debug
    var totServices = 3;
    var totChars = 12;
    var numServices = 0;
    var numChars = 0;
    
    var setup = 0; // 0 = not tried, 1 = fail, 2 = succ UNUSED
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) { // gets called when you define cbcentralmanager in viewDid load
        if central.state == CBManagerState.poweredOn {
            print("BLE powered on")  // turned on
            central.scanForPeripherals(withServices: nil, options: nil) // looks for all devices. Calls next func many times
        }
        else {
            statusLabel.tintColor = UIColor.red
            statusLabel.text = "Try Again."
            print("Something wrong with BLE")
            // Not on, but can have different issues
        }
    }
    
    /* function called when looking device is discovered */
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if let pname = peripheral.name {
            print("FOUND: \(pname)")
            if pname == "Green Thumb" {  // or whatever we call it. Should check UUID too.
                print("MATCH FOUND!")
                self.centralManager.stopScan()  // stop scanning
                self.myPeripheral = peripheral  // assign the myPeripheral obj to this peripheral
                ble.myPeripheral = peripheral
                //
                self.myPeripheral.delegate = self  //  not sure but important. Makes somethig conform
                self.centralManager.connect(peripheral, options: nil)  // connect peripheral. Calls next function
                        
                    }
        }
    }
    
    /* function called after device is connected*/
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("CONNECTED TO DEVICE")                   // ^^ NOTICE THE DIFFERENCE HERE
        self.myPeripheral.discoverServices(nil) // get bluetooth services (next func)
    }
    // the manager has done its set up now. Now we run functions from the peripheral...
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("Discovering Services...")
        
        guard let services = peripheral.services else {
                return
        }
        
        for service in services {
            //print("SERVICE FOUND: \(service)")
            // assign this service to the correct var:
            switch service.uuid {
            case BLEParamters.getReadingsServiceUUID:
                ble.getReadingsService = service
                print("FOUND getReadingsService")
                numServices += 1
                self.myPeripheral.discoverCharacteristics(nil, for: service)
            case BLEParamters.waterServiceUUID:
                ble.waterService = service
                print("FOUND waterService")
                numServices += 1
                self.myPeripheral.discoverCharacteristics(nil, for: service)
            case BLEParamters.lightServiceUUID:
                ble.lightService = service
                print("FOUND lightService")
                numServices += 1
                peripheral.discoverCharacteristics(nil, for: service)
            // add other services here as they come
            default:
                //self.myPeripheral.discoverCharacteristics(nil, for: service) // added one more so light would flash
                break
            }

        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("Discovering characteristics...")
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        for characteristic in characteristics {
            //print("CHARACTERISTIC FOUND: \(characteristic)")
            switch characteristic.uuid // if this is the alert char
            {
            // for Get Readings Service:
            case BLEParamters.moistCharacteristicUUID:
                ble.moistCharacteristic = characteristic
                print("FOUND moistCharacteristic")
                numChars += 1
            case BLEParamters.tempCharacteristicUUID:
                ble.tempCharacteristic = characteristic
                print("FOUND tempCharacteristic")
                numChars += 1
            case BLEParamters.phCharacteristicUUID:
                ble.phCharacteristic = characteristic
                print("FOUND phCharacteristic")
                numChars += 1
            // for water service:
            case BLEParamters.waterNowCharacteristicUUID:
                ble.waterNowCharacteristic = characteristic
                print("FOUND waterNowCharacteristic")
                numChars += 1
            case BLEParamters.waterFreqCharacteristicUUID:
                ble.waterFreqCharacteristic = characteristic
                print("FOUND waterFreqCharacteristic")
                numChars += 1
            case BLEParamters.waterTimeCharacteristicUUID:
                ble.waterTimeCharacteristic = characteristic
                print("FOUND waterTimeCharacteristic")
                numChars += 1
            case BLEParamters.automateCharacteristicUUID:
                ble.automateCharacteristic = characteristic
                print("FOUND automateCharacteristic")
                numChars += 1
            case BLEParamters.waterOptionCharacteristicUUID:
                ble.waterOptionCharacteristic = characteristic
                print("FOUND waterOptionCharacteristic")
                numChars += 1
            // for light service:
            case BLEParamters.toggleLightsCharacteristicUUID:
                ble.toggleLightsCharacteristic = characteristic
                print("FOUND toggleLightsCharacteristic")
                numChars += 1
            case BLEParamters.timeTillStartCharacteristicUUID:
                ble.timeTillStartCharacteristic = characteristic
                print("FOUND timeTillStartCharacteristic")
                numChars += 1
            case BLEParamters.lightTimeCharacteristicUUID:
                ble.lightTimeCharacteristic = characteristic
                print("FOUND lightTimeCharacteristic")
                numChars += 1
            case BLEParamters.lightOptionCharacteristicUUID:
                ble.lightOptionCharacteristic = characteristic
                print("FOUND lightOptionCharacteristic")
                numChars += 1
            default: break
            }
            
        }
        // then can we save it and change it?
        //setup = 2;
        statusLabel.textColor = UIColor.systemGreen
        statusLabel.text = "Connection Successful!"
        ContinueButton?.isHidden = false;
        connectBluetoothButton.isEnabled = false;
        print("Services found: \(numServices)/\(totServices)")
        print("Characteristics found: \(numChars)/\(totChars)\n")
        //print()
    }
    
    /* write value for some characteristic*/
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
                // Handle error
            print("ERROR writing value to characteristic \(characteristic.uuid)")
                return
            }
        // else successful ?
    }

    func write(value: Data, characteristic: CBCharacteristic) {
        //self.myPeripheral.writeValue(value, for: characteristic, type: .withResponse)
        // OR
       //self.myPeripheral.writeValue(value, for: characteristic, type: .withoutResponse)
        ble.myPeripheral?.writeValue(value, for: characteristic, type: .withResponse)
     }
    
    func toggleLights( val: Int8)
    {
        var parameter = NSInteger(val)  // sets write val
        let data = NSData(bytes: &parameter, length: 1)
        ble.myPeripheral!.writeValue(data as Data, for: ble.toggleLightsCharacteristic!, type: CBCharacteristicWriteType.withResponse)
    }
    
//-------------------------StoryBoard Code below here------------------------------
    
    override func viewDidLoad() {
        // all set up to do after loading the view
        print("App running...")
        super.viewDidLoad()
        ContinueButton?.isHidden = true;
        statusLabel?.isHidden = true;
        helpLabel?.isHidden = true;
    }
    
    //LANDING PAGE:
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var ContinueButton: UIButton!
    @IBOutlet weak var connectBluetoothButton: UIButton!
    @IBAction func connectBluetoothAction(_ sender: Any) {
        centralManager = CBCentralManager(delegate: self, queue: nil)  // set up central manager.
        setup = 1;
        statusLabel.textColor = UIColor.black
        statusLabel.isHidden = false;
    }
    
    //READINGS PAGE
    @IBOutlet weak var TempLabel: UILabel!
    @IBOutlet weak var MoistLabel: UILabel!
    @IBOutlet weak var phLabel: UILabel!
    
    //LIGHTS PAGE:
    var lightingOption = 0;
    
    @IBOutlet weak var lightswitch: UISwitch!
    @IBAction func lightswitchAction(_ sender: UISwitch) {
        
        if sender.isOn {
            var parameter = NSInteger(1)  // sets high alert
            let data = NSData(bytes: &parameter, length: 1)
            //if toggleLightsCharacteristic == nil { print("in write: TOGGLE LIGHTS CHAR IS NIL") } // is printed
            if ble.toggleLightsCharacteristic != nil{
                //write(value: data as Data, characteristic: characteristicvars.toggleLightsCharacteristic!);
                //characteristicvars.myPeripheral!.writeValue(data as Data, for: characteristicvars.toggleLightsCharacteristic!, type: .withoutResponse)
                toggleLights(val: 1)
                print("LIGHTS: wrote value 1")
            }
            
        } else {
            var parameter = NSInteger(0)  // sets high alert
            let data = NSData(bytes: &parameter, length: 1)
            if ble.toggleLightsCharacteristic != nil{
                //write(value: data as Data, characteristic: characteristicvars.toggleLightsCharacteristic!);
                //characteristicvars.myPeripheral!.writeValue(data as Data, for: characteristicvars.toggleLightsCharacteristic!, type: .withoutResponse)
                toggleLights(val: 0)
                print("LIGHTS: wrote value 0")
            }
        }
    }
    
    @IBOutlet weak var StartTime: UIDatePicker!
    @IBAction func StartTimeAction(_ sender: Any) {
    }
    @IBOutlet weak var EndTime: UIDatePicker!
    @IBAction func EndTimeAction(_ sender: Any) {
    }
    @IBOutlet weak var SetTimeButton: UIButton!
    @IBAction func SetTimeAction(_ sender: Any) {
        var startDiff = abs(NSDate().timeIntervalSince(StartTime.date))
        var endDiff = abs(NSDate().timeIntervalSince(EndTime.date))
        var lightTime = abs(startDiff-endDiff)
        
        if(NSDate().timeIntervalSince(StartTime.date) > 0) // if the time already passed today
        {
            // have the start time be one day in the future from right now minus the difference.
            startDiff = (60*60*24) - startDiff;
        }
        if(startDiff-endDiff > 0) {
            lightTime = (60*60*24) - lightTime;
        }
        
        // this is all just for debugging
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.short
        dateFormatter.timeStyle = DateFormatter.Style.short
        let strDate = dateFormatter.string(from: StartTime.date)
        let endDate = dateFormatter.string(from: EndTime.date)
        
        print("SENDING LIGHT SCHEDULE DATA:")
        print("Start time: \(strDate)")
        print("End time: \(endDate)")
        //these are the two times to send:
        print("Total: seconds of light: \(lightTime)")
        print("Starting in \(startDiff)sec from now")
        
        //then  need to send data
        // TODO: The numbers are being truncated to a uint8.
        // need uint16
        var parameter1 = NSInteger(Int(startDiff))
        let data1  = NSData(bytes: &parameter1, length: 2)
        
        var parameter2 = NSInteger(Int(lightTime))
        let data2  = NSData(bytes: &parameter2, length: 2)
        print("sending: \(data1) \(data2)")
        ble.myPeripheral!.writeValue(data1 as Data, for: ble.timeTillStartCharacteristic!, type: CBCharacteristicWriteType.withResponse)
        ble.myPeripheral!.writeValue(data2 as Data, for: ble.lightTimeCharacteristic!, type: CBCharacteristicWriteType.withResponse)
        
        
    }
    
// WATER PAGE
    @IBOutlet weak var WaterFreq: UITextField!
    @IBAction func WaterFreqAction(_ sender: Any) {
    }
    
    @IBOutlet weak var WaterTime: UIDatePicker!
    @IBAction func WaterTimeAction(_ sender: Any) {
    }
    
    @IBOutlet weak var helpLabel: UILabel!
    
    @IBOutlet weak var helpButton: UIButton!
    @IBAction func helpButtonAction(_ sender: Any) {
        if helpLabel.isHidden == false {
            helpLabel.isHidden = true;
        } else {
        helpLabel.isHidden = false;
        }
    }
    
    @IBOutlet weak var automateSwitch: UISwitch!
    @IBAction func automateAction(_ sender: UISwitch) {
        
            if sender.isOn {
                if ble.automateCharacteristic != nil{
                    var parameter = NSInteger(1)
                    let data  = NSData(bytes: &parameter, length: 1)
                    ble.myPeripheral!.writeValue(data as Data, for: ble.automateCharacteristic!, type: CBCharacteristicWriteType.withResponse)
                    print("Automate Watering ON")
                }
            }
            else {
                if ble.automateCharacteristic != nil{
                    var parameter = NSInteger(0)
                    let data  = NSData(bytes: &parameter, length: 1)
                    ble.myPeripheral!.writeValue(data as Data, for: ble.automateCharacteristic!, type: CBCharacteristicWriteType.withResponse)
                    print("Automate Watering OFF")
                }
            }
            
    }
    @IBOutlet weak var waterNowButton: UIButton!
    @IBAction func WaterNowAction(_ sender: Any) {
        //if toggleLightsCharacteristic == nil { print("in write: TOGGLE LIGHTS CHAR IS NIL") } // is printed
        if ble.waterNowCharacteristic != nil{
            var parameter = NSInteger(1)
            let data  = NSData(bytes: &parameter, length: 1)
            ble.myPeripheral!.writeValue(data as Data, for: ble.waterNowCharacteristic!, type: CBCharacteristicWriteType.withResponse)
            print("Manually watering now")
        }
    // do i need to write back to a 0 to turn pump off? We'll see.
    //My guess is we need to make sure the write goes through, then send a 0 after X seconds to turn the pump off.
    }
    
    
    @IBOutlet weak var SetWaterButton: UIButton!
    @IBAction func SetWaterAction(_ sender: Any) {
        if(WaterTime == nil || WaterFreq.text == nil) {
            print("Missing required fields")
            return
        }
        var time = abs(NSDate().timeIntervalSince(WaterTime.date))
        if(NSDate().timeIntervalSince(WaterTime.date) > 0) // if the time already passed today
        {
            // have the start time be one day in the future from right now minus the difference.
            print("this time has passed")
            time = (60*60*24) - time;
        }
        var waterFreqInt = Int(WaterFreq.text ?? "0")!;
        var waterFreqSeconds = (60*60*24*waterFreqInt)
        // this is all just for debugging
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.short
        dateFormatter.timeStyle = DateFormatter.Style.short
        let strDate = dateFormatter.string(from: WaterTime.date)
        
        print("SENDING WATER SCHEDULE DATA:")
        print("Start time: \(strDate) (\(time) seconds from now)")
        print("Every \(waterFreqInt) days (\(waterFreqSeconds) seconds)")
        
        // send data:
        var parameter2 = NSInteger(waterFreqInt)
        let data2  = NSData(bytes: &parameter2, length: 1)
        ble.myPeripheral!.writeValue(data2 as Data, for: ble.waterFreqCharacteristic!, type: CBCharacteristicWriteType.withResponse)
        
        var parameter1 = NSInteger(time)
        let data1  = NSData(bytes: &parameter1, length: 1)
        ble.myPeripheral!.writeValue(data1 as Data, for: ble.waterTimeCharacteristic!, type: CBCharacteristicWriteType.withResponse)
        
    }

}

