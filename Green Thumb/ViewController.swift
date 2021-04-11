
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
    static let startTimeCharacteristicUUID = CBUUID(string: "B002")
    static let stopTimeCharacteristicUUID = CBUUID(string: "B003")
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

struct characteristicvars {
    static var toggleLightsCharacteristic : CBCharacteristic? = nil
    static var myPeripheral : CBPeripheral? = nil
}


class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    //properties:
    var centralManager: CBCentralManager!  //central is phone
    var myPeripheral: CBPeripheral!  //peripheral is board
    // Vars for Get Readings Service:
    var getReadingsService : CBService!
    var tempCharacteristic : CBCharacteristic!
    var moistCharacteristic : CBCharacteristic!
    var phCharacteristic : CBCharacteristic!
    //vars for water service
    var waterService : CBService!
    var waterNowCharacteristic : CBCharacteristic!
    var waterFreqCharacteristic : CBCharacteristic!
    var waterTimeCharacteristic : CBCharacteristic!
    var automateCharacteristic : CBCharacteristic!
    var waterOptionCharacteristic : CBCharacteristic!
    //vars for light service
    private var lightService : CBService?
    private var toggleLightsCharacteristic : CBCharacteristic?
    var startTimeCharacteristic : CBCharacteristic!
    var stopTimeCharacteristic : CBCharacteristic!
    var lightOptionCharacteristic : CBCharacteristic!
    
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
                characteristicvars.myPeripheral = peripheral
                characteristicvars.myPeripheral?.delegate = self
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
                getReadingsService = service
                print("FOUND getReadingsService")
                numServices += 1
                self.myPeripheral.discoverCharacteristics(nil, for: service)
            case BLEParamters.waterServiceUUID:
                waterService = service
                print("FOUND waterService")
                numServices += 1
                self.myPeripheral.discoverCharacteristics(nil, for: service)
            case BLEParamters.lightServiceUUID:
                lightService = service
                print("FOUND lightService")
                numServices += 1
                if(lightService == nil) { print("LIGHT SERVICE IS STILL NIL") }
                peripheral.discoverCharacteristics(nil, for: service)
            // add other services here as they come
            default:
                self.myPeripheral.discoverCharacteristics(nil, for: service) // added one more so light would flash
                break
            }
            //self.myPeripheral.discoverCharacteristics(nil, for: service)
        }
        // this have UUIDS we need to check for.
        // Immediate alert has UUID of 1802
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
            case CBUUID(string: "2A06"): // if alert level
                // these three lines use the  send alert service to flash LED, proving connection
                var parameter = NSInteger(2)  // sets high alert
                let data = NSData(bytes: &parameter, length: 1)
                write(value: data as Data, characteristic: characteristic);
            // for Get Readings Service:
            case BLEParamters.moistCharacteristicUUID:
                moistCharacteristic = characteristic
                print("FOUND moistCharacteristic")
                numChars += 1
            case BLEParamters.tempCharacteristicUUID:
                tempCharacteristic = characteristic
                print("FOUND tempCharacteristic")
                numChars += 1
            case BLEParamters.phCharacteristicUUID:
                phCharacteristic = characteristic
                print("FOUND phCharacteristic")
                numChars += 1
            // for water service:
            case BLEParamters.waterNowCharacteristicUUID:
                waterNowCharacteristic = characteristic
                print("FOUND waterNowCharacteristic")
                numChars += 1
            case BLEParamters.waterFreqCharacteristicUUID:
                waterFreqCharacteristic = characteristic
                print("FOUND waterFreqCharacteristic")
                numChars += 1
            case BLEParamters.waterTimeCharacteristicUUID:
                waterTimeCharacteristic = characteristic
                print("FOUND waterTimeCharacteristic")
                numChars += 1
            case BLEParamters.automateCharacteristicUUID:
                automateCharacteristic = characteristic
                print("FOUND automateCharacteristic")
                numChars += 1
            case BLEParamters.waterOptionCharacteristicUUID:
                waterOptionCharacteristic = characteristic
                print("FOUND waterOptionCharacteristic")
                numChars += 1
            // for light service:
            case BLEParamters.toggleLightsCharacteristicUUID:
                toggleLightsCharacteristic = characteristic
                characteristicvars.toggleLightsCharacteristic = characteristic
                var parameter = NSInteger(1)  // sets write val
                let data = NSData(bytes: &parameter, length: 1)
                self.myPeripheral.writeValue(data as Data, for: characteristic, type: .withoutResponse)
                print("FOUND toggleLightsCharacteristic")
                numChars += 1
                if(toggleLightsCharacteristic == nil) { print("TOGGLE LIGHTS CHAR IS STILL NIL") } // is not printed
            case BLEParamters.startTimeCharacteristicUUID:
                startTimeCharacteristic = characteristic
                print("FOUND startTimeCharacteristic")
                numChars += 1
            case BLEParamters.stopTimeCharacteristicUUID:
                stopTimeCharacteristic = characteristic
                print("FOUND stopTimeCharacteristic")
                numChars += 1
            case BLEParamters.lightOptionCharacteristicUUID:
                lightOptionCharacteristic = characteristic
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
                print("ERROR writing value")
                return
            }
        // else successful ?
    }

    func write(value: Data, characteristic: CBCharacteristic) {
        //self.myPeripheral.writeValue(value, for: characteristic, type: .withResponse)
        // OR
       self.myPeripheral.writeValue(value, for: characteristic, type: .withoutResponse)
     }
    
    func toggleLights( val: Int8)
    {
        var parameter = NSInteger(val)  // sets write val
        let data = NSData(bytes: &parameter, length: 1)
        characteristicvars.myPeripheral!.writeValue(data as Data, for: characteristicvars.toggleLightsCharacteristic!, type: CBCharacteristicWriteType.withoutResponse)
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
    
    @IBOutlet weak var connectBluetoothButton: UIButton!
    @IBAction func connectBluetoothAction(_ sender: Any) {
        centralManager = CBCentralManager(delegate: self, queue: nil)  // set up central manager.
        setup = 1;
        statusLabel.textColor = UIColor.black
        statusLabel.isHidden = false;
    }
    

    //LANDING PAGE:
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var ContinueButton: UIButton!
    @IBOutlet weak var startBluetoothButton: UIButton!
    @IBAction func startBluetoothAction(_ sender: Any) {
        //bleLand.startUpCentralManager()
        startBluetoothButton.isEnabled = false
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
            if characteristicvars.toggleLightsCharacteristic != nil{
                //write(value: data as Data, characteristic: characteristicvars.toggleLightsCharacteristic!);
                //characteristicvars.myPeripheral!.writeValue(data as Data, for: characteristicvars.toggleLightsCharacteristic!, type: .withoutResponse)
                toggleLights(val: 1)
                print("LIGHTS: wrote value 1")
            }
            
        } else {
            var parameter = NSInteger(0)  // sets high alert
            let data = NSData(bytes: &parameter, length: 1)
            if characteristicvars.toggleLightsCharacteristic != nil{
                //write(value: data as Data, characteristic: toggleLightsCharacteristic);
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
            //print("this time has passed")
            startDiff = (60*60*24) - startDiff;
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
        print("Total: seconds of light: \(lightTime)")
        print("Starting in \(startDiff)sec from now")
        
        //then  need to send data
        
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
                var parameter = NSInteger(1)  // write val 1
                let data = NSData(bytes: &parameter, length: 1)
                //if toggleLightsCharacteristic == nil { print("in write: TOGGLE LIGHTS CHAR IS NIL") } // is printed
                if waterNowCharacteristic != nil{
                    print("Automate Watering on")
                }
                print("Automate Watering: ON")
                }
                else {
                    var parameter = NSInteger(0)  // write val 1
                    let data = NSData(bytes: &parameter, length: 1)
                    //if toggleLightsCharacteristic == nil { print("in write: TOGGLE LIGHTS CHAR IS NIL") } // is printed
                    if automateCharacteristic != nil{
                        print("Automate Watering off")
                    }
                    print("Automate Watering: OFF")
                }
            
    }
    @IBOutlet weak var waterNowButton: UIButton!
    @IBAction func WaterNowAction(_ sender: Any) {
        var parameter = NSInteger(1)  // write val 1
        let data = NSData(bytes: &parameter, length: 1)
        //if toggleLightsCharacteristic == nil { print("in write: TOGGLE LIGHTS CHAR IS NIL") } // is printed
        if waterNowCharacteristic != nil{
            print("Watering now")
        }
        print("Watering now")
    // do i need to write back to a 0 to turn pump off? We'll see
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
        
    }
    
    
// OLD JUNK IM TOO AFRAID TO DELETE------------------------------
    
    func blueToothOn()
    {
        searchButton.isEnabled = true
    }
    
    @IBOutlet weak var searchButton: UIButton!
    @IBAction func SearchAction(_ sender: AnyObject) {
        //bleLand.discoverDevice()
        searchButton.isEnabled = false
    }
    
    func foundDevice()
    {
        connectDeviceButton.isEnabled = true
    }
    
    @IBOutlet weak var connectDeviceButton: UIButton!
    @IBAction func connectDeviceAction(sender: AnyObject){
        connectDeviceButton.isEnabled = false
        //bleLand.connectToDevice()
    }
    
    func connectionComplete()
    {
        discoverServicesButton.isEnabled = true
        disconnectButton.isEnabled = true
    }
    
    @IBOutlet weak var discoverServicesButton: UIButton!
    @IBAction func discoverServicesAction(sender: AnyObject) {
        //bleLand.discoverServices()
        discoverServicesButton.isEnabled = false
    }
    
    func discoveredServices()
    {
        discoverCharacteristicsButton.isEnabled = true
    }
  
    
    @IBOutlet weak var discoverCharacteristicsButton: UIButton!
    
    @IBAction func discoverCharacteristicsAction(sender: AnyObject) {
        //bleLand.discoverCharacteristics()
        discoverCharacteristicsButton.isEnabled = false
    }
    
    func discoveredCharacteristics()
    {
        //ledSwitch.enabled = true
        //capsenseNotifySwitch.enabled = true
    }
   
    
    @IBOutlet weak var disconnectButton: UIButton!
    
    @IBAction func disconnectAction(sender: AnyObject) {
        //bleLand.disconnectDevice()
    }
    func disconnectedComplete()
    {
        searchButton.isEnabled = true
        connectDeviceButton.isEnabled = false
        discoverServicesButton.isEnabled = false
        discoverCharacteristicsButton.isEnabled = false
        disconnectButton.isEnabled = false
        //ledSwitch.isEnabled = false
        //capsenseNotifySwitch.isEnabled = false
        //capsenseNotifySwitch.isOn = false
    }
    

}

