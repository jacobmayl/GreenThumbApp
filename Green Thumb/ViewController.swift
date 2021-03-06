
//
//  ViewController.swift
//  Green Thumb
//
//  Created by Jacob Mayl on 3/28/21.
//

import UIKit
import CoreBluetooth
import CoreFoundation
//import BlueToothNeightborhood

// save all UUIDS for use here
private struct BLEParamters {
    //get reading service:
    static let getReadingsServiceUUID = CBUUID(string: "AF7A")
    static let tempCharacteristicUUID = CBUUID(string: "2A6E")
    static let moistCharacteristicUUID = CBUUID(string: "2A69")  //was 2A6F
    static let phCharacteristicUUID = CBUUID(string: "2A70")
    static let temp2CharacteristicUUID = CBUUID(string: "278B")
    //water service:
    static let waterServiceUUID = CBUUID(string: "AAAA")
    static let waterNowCharacteristicUUID = CBUUID(string: "A001")
    static let waterFreqCharacteristicUUID = CBUUID(string: "A002")
    static let waterTimeCharacteristicUUID = CBUUID(string: "A003")
    static let automateCharacteristicUUID = CBUUID(string: "A004")
    static let waterOptionCharacteristicUUID = CBUUID(string: "A005")
    static let waterCupsCharacteristicUUID = CBUUID(string: "A006")
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
    static var temp2Characteristic : CBCharacteristic? = nil
    //vars for water service
    static var waterService : CBService? = nil
    static var waterNowCharacteristic : CBCharacteristic? = nil
    static var waterFreqCharacteristic : CBCharacteristic? = nil
    static var waterTimeCharacteristic : CBCharacteristic? = nil
    static var automateCharacteristic : CBCharacteristic? = nil
    static var waterOptionCharacteristic : CBCharacteristic? = nil
    static var waterCupsCharacteristic : CBCharacteristic? = nil
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
    var totChars = 14;
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
                ble.myPeripheral.setNotifyValue(true, for: ble.moistCharacteristic!)  // allow for update notifications
                ble.myPeripheral.readValue(for: characteristic)  // sends value to peripheral: didUpdateValueForCharacteristic
                print("FOUND moistCharacteristic")
                numChars += 1
            case BLEParamters.tempCharacteristicUUID:
                ble.tempCharacteristic = characteristic
                ble.myPeripheral.setNotifyValue(true, for: ble.tempCharacteristic!)
                ble.myPeripheral.readValue(for: characteristic)
                print("FOUND tempCharacteristic")
                numChars += 1
            case BLEParamters.phCharacteristicUUID:
                ble.phCharacteristic = characteristic
                ble.myPeripheral.setNotifyValue(true, for: characteristic)
                //ble.myPeripheral.readValue(for: characteristic)
                print("FOUND phCharacteristic")
                numChars += 1
            case BLEParamters.temp2CharacteristicUUID:
                ble.temp2Characteristic = characteristic
                ble.myPeripheral.setNotifyValue(true, for: characteristic)
                //ble.myPeripheral.readValue(for: characteristic)
                print("FOUND phCharacteristic")
                numChars += 1
            // for water service:
            case BLEParamters.waterCupsCharacteristicUUID:
                ble.waterCupsCharacteristic = characteristic
                print("FOUND waterCupsCharacteristic")
                numChars += 1
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
    /* Read, update a characteristic */
    
    func decode_temp(x: Int, y: Int ) -> Double {
        
        let x = x
        var y = y

        var arr = [0,0,0,0,0,0,0,0]
        var i = 0
        var res = Double(x)

        if(y > 0){
            while( y > 0){
                arr[7-i] = y % 2
                i+=1
                y = y/2
            }
        }

        if((arr[0]) != 0) {
            res += 0.5
        }
        if((arr[1]) != 0) {
            res += 0.25
        }
        if((arr[2]) != 0) {
            res += 0.125
        }
        res = (res*9/5)+32
        
        return Double(round(10*res)/10)
    }
    
    //TODO: UPDATE VALUES IN VC
    var tempReading = 0;
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid {
        case BLEParamters.moistCharacteristicUUID:
            var perc = Int((characteristic.value?.first)!)
            print("New MOIST reading: \(perc)") //gets first byte of data
            vc.moistString = "\(perc)%"
            MoistLabel?.text = "\(perc)%"
            break
        case BLEParamters.tempCharacteristicUUID:
            //tempReading = characteristic.value
            //print("New TEMP reading: \(characteristic.value?.first), \(characteristic.value?.last)") //gets first byte of data
            var tempReading = decode_temp( x: Int((characteristic.value?.first)!), y: Int((characteristic.value?.last)!))
            print("new TEMP reading: \(tempReading)")
            vc.tempString = "\(tempReading)"
            TempLabel?.text = "\(tempReading)"
            break
        case BLEParamters.phCharacteristicUUID:
            //tempReading = characteristic.value
            print("New PH reading: \(characteristic.value?.first)") //gets first byte of data
            break
        default:
            print("ERROR: unknown read occured from \(characteristic.uuid)")
        }
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
    
    
    struct vc {
        //store new values as they change.
        //readings
        static var tempString = "0"
        static var moistString = "0%"
        static var phString = "6.5"
        //lights
        static var lightSwitchVal = false
        static var lightStart = NSDate()
        static var lightEnd = NSDate()
        static var lightOption = 0
        //water
        static var waterFreqString = "0"
        static var waterStart = NSDate()
        static var waterSwitchVal = false
        static var waterOption = 0
    }
    
    func application(_ application: UIApplication,
                shouldSaveApplicationState coder: NSCoder) -> Bool {
       // Save the current app version to the archive.
       coder.encode(11.0, forKey: "MyAppVersion")
            
       // Always save state information.
       return true
    }
        
    func application(_ application: UIApplication,
                shouldRestoreApplicationState coder: NSCoder) -> Bool {
       // Restore the state only if the app version matches.
       let version = coder.decodeFloat(forKey: "MyAppVersion")
       if version == 11.0 {
          return true
       }
        
       // Do not restore from old data.
       return false
    }
    
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    override func viewDidLoad() {
        // all set up to do after loading the view
        print("App running...")
        super.viewDidLoad()
        ContinueButton?.isHidden = true;
        statusLabel?.isHidden = true;
        helpLabel?.isHidden = true;
        //for exiting number keyboards
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))  //see func above
        view.addGestureRecognizer(tap)
        
        //reading page set in didUpdateValueFor above
        TempLabel?.text = vc.tempString
        MoistLabel?.text = vc.moistString
        phLabel?.text = vc.phString
        //light page
        lightswitch?.isOn = vc.lightSwitchVal
        StartTime?.date = vc.lightStart as Date
        EndTime?.date = vc.lightEnd as Date
        switch(vc.lightOption){
        case(0):
            lightToggleStack?.backgroundColor = UIColor.systemBackground
            lightTimerStack?.backgroundColor = UIColor.systemBackground
            break
        case(1):
            lightToggleStack?.backgroundColor = UIColor.systemGray5
            lightTimerStack?.backgroundColor = UIColor.systemBackground
            break
        case(2):
            lightToggleStack?.backgroundColor = UIColor.systemBackground
            lightTimerStack?.backgroundColor = UIColor.systemGray5
            break
        default:
            break
        }
        // do case statement for option?
        //water
        WaterTime?.date = vc.waterStart as Date
        WaterFreq?.text = vc.waterFreqString
        automateSwitch?.isOn = vc.waterSwitchVal
        switch(vc.waterOption){
        case(0):
            waterTimeStack?.backgroundColor = UIColor.systemBackground
            waterAutomateStack?.backgroundColor = UIColor.systemBackground
            break
        case(1):
            waterTimeStack?.backgroundColor = UIColor.systemBackground
            waterAutomateStack?.backgroundColor = UIColor.systemGray5
            break
        case(2):
            waterNowStack?.backgroundColor = UIColor.systemGray5
            waterTimeStack?.backgroundColor = UIColor.systemBackground
            waterAutomateStack?.backgroundColor = UIColor.systemBackground
            break
        case(3):
            waterTimeStack?.backgroundColor = UIColor.systemGray5
            waterAutomateStack?.backgroundColor = UIColor.systemBackground
            break
        default:
            break
        }
        
    }
    
    //LANDING PAGE:
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var ContinueButton: UIButton!
    @IBOutlet weak var connectBluetoothButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    @IBAction func connectBluetoothAction(_ sender: Any) {
        centralManager = CBCentralManager(delegate: self, queue: nil)  // set up central manager.
        setup = 1;
        statusLabel.textColor = UIColor.black
        statusLabel.isHidden = false;
        skipButton.isHidden = true;
        UserDefaults.standard.synchronize()
    }
    
    //READINGS PAGE
    @IBOutlet weak var TempLabel: UILabel!
    @IBOutlet weak var MoistLabel: UILabel!
    @IBOutlet weak var phLabel: UILabel!
    
    //LIGHTS PAGE:
    var lightingOption = 0;
    
    @IBOutlet weak var lightTimerStack: UIStackView!
    @IBOutlet weak var lightToggleStack: UIStackView!
    
    @IBOutlet weak var lightswitch: UISwitch!
    @IBAction func lightswitchAction(_ sender: UISwitch) {
        
        if sender.isOn {
            //var parameter = NSInteger(1)  // sets high alert
            //let data = NSData(bytes: &parameter, length: 1)
            if ble.toggleLightsCharacteristic != nil {
                toggleLights(val: 1)
                print("LIGHTS: wrote value 1")
            }
            
        } else {
            var parameter = NSInteger(0)
            let data = NSData(bytes: &parameter, length: 1)
            if ble.toggleLightsCharacteristic != nil {
                toggleLights(val: 0)
                print("LIGHTS: wrote value 0")
            }
        }
        
        //set LightOption to 1
        var parameter = NSInteger(1);
        let data  = NSData(bytes: &parameter, length: 1)
        ble.myPeripheral!.writeValue( data as Data, for: ble.lightOptionCharacteristic!, type: CBCharacteristicWriteType.withResponse)
        
        //update viewDidLoad
        lightToggleStack?.backgroundColor = UIColor.systemGray5
        lightTimerStack?.backgroundColor = UIColor.systemBackground
        vc.lightSwitchVal = sender.isOn
        vc.lightOption = 1
        //print("set to \(vc.lightSwitchVal)")
        
    }
    
    @IBOutlet weak var StartTime: UIDatePicker!
    @IBAction func StartTimeAction(_ sender: Any) {
    }
    @IBOutlet weak var EndTime: UIDatePicker!
    @IBAction func EndTimeAction(_ sender: Any) {
    }
    
    
    
    @IBOutlet weak var SetTimeButton: UIButton!
    // has problems when you set the time to start to be the current time.
    @IBAction func SetTimeAction(_ sender: Any) {
        
        
        var startDiff = NSDate().timeIntervalSince(StartTime.date)
        let endDiff = NSDate().timeIntervalSince(EndTime.date)
        var lightTime = 0.0
        var startTime = 0.0
        
        if( startDiff > 0 && endDiff > 0){ // if both times have passed
            lightTime = startDiff - endDiff
            startTime = (60*60*24) - startDiff
        }
        else if( startDiff > 0 && endDiff < 0){ // if the start date has passed and the end date hasnt
            lightTime = abs(startDiff - endDiff)
            startTime = (60*60*24) - startDiff
        }
        else if( startDiff < 0 && endDiff > 0){  // if the start date hasn't passed but the end date has
            lightTime = (60*60*24) - abs( startDiff - endDiff)
            startTime = abs(startDiff)
        }
        else if( startDiff < 0 && endDiff < 0) {  // if neither times have passed
            lightTime = startDiff - endDiff
            startTime = abs(startDiff)
        }
        
        if(startDiff > 0 && startDiff < 60){  // if the start time is this current minute
            startTime = 1 // have it start immediatly
        }
        
        
        // this is all just for debugging
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.short
        dateFormatter.timeStyle = DateFormatter.Style.short
        let strDate = dateFormatter.string(from: StartTime.date)
        let endDate = dateFormatter.string(from: EndTime.date)
        
        
        let startTimeInt = Int(round(startTime));
        let lightTimeInt = Int(round(lightTime));
        
        //let startDiffInt = startDiff;
        //let lightTimeInt = lightTime;
        
        print("SENDING LIGHT SCHEDULE DATA:")
        print("Start time: \(strDate)")
        print("End time: \(endDate)")
        //these are the two times to send:
        print("Total: seconds of light: \(lightTimeInt)")
        print("Starting in \(startTimeInt) sec from now")
        
        //then  need to send data
        var parameter1 = NSInteger(Int(startTimeInt))
        let data1  = NSData(bytes: &parameter1, length: 4)
        
        var parameter2 = NSInteger(Int(lightTimeInt))
        let data2  = NSData(bytes: &parameter2, length: 4)
        
        //print("sending: \(data1) \(data2)")
        ble.myPeripheral!.writeValue(data1 as Data, for: ble.timeTillStartCharacteristic!, type: CBCharacteristicWriteType.withResponse)
        ble.myPeripheral!.writeValue(data2 as Data, for: ble.lightTimeCharacteristic!, type: CBCharacteristicWriteType.withResponse)
        
        //set option to 2
        var parameter3 = NSInteger(2);
        let data3  = NSData(bytes: &parameter3, length: 1)
        ble.myPeripheral!.writeValue( data3 as Data, for: ble.lightOptionCharacteristic!, type: CBCharacteristicWriteType.withResponse)
        
        //update VC
        vc.lightStart = StartTime.date as NSDate
        vc.lightEnd = EndTime.date as NSDate
        vc.lightOption = 2
        lightToggleStack?.backgroundColor = UIColor.systemBackground
        lightTimerStack?.backgroundColor = UIColor.systemGray5
        
        
    }
    
// WATER PAGE
    
    func isNumber(text:String)->Bool
    {
        if let intVal = Double(text)
            {return true}
        else
            {return false}
    }
    
    @IBOutlet weak var waterTimeStack: UIStackView!
    @IBOutlet weak var waterAutomateStack: UIStackView!
    
    @IBOutlet weak var WaterFreq: UITextField!
    @IBAction func WaterFreqAction(_ sender: Any) {
    }
    
    @IBOutlet weak var WaterTime: UIDatePicker!
    @IBAction func WaterTimeAction(_ sender: Any) {
    }
    
    
    @IBOutlet weak var setWaterCupsButton: UIButton!
    @IBAction func setWaterCupsAction(_ sender: Any) {
        if isNumber(text: waterCups.text!) {
            let waterCupsFloat = Double(waterCups.text ?? "0")!;
            print("CUPS: \(waterCupsFloat)")
            
            var parameter = NSInteger(waterCupsFloat*4)
            print(parameter)
            let data  = NSData(bytes: &parameter, length: 1)
            ble.myPeripheral!.writeValue(data as Data, for: ble.waterCupsCharacteristic!, type: CBCharacteristicWriteType.withResponse)
            
        } else {
            print("\(waterCups.text!) IS NOT NUM")
        }
    }
    @IBOutlet weak var waterCups: UITextField!
    
    
    
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
                    
                    //set WaterOption to 1
                    var parameter2 = NSInteger(1);
                    let data2  = NSData(bytes: &parameter2, length: 1)
                    ble.myPeripheral!.writeValue( data2 as Data, for: ble.waterOptionCharacteristic!, type: CBCharacteristicWriteType.withResponse)
                }
            }
            else {
                if ble.automateCharacteristic != nil{
                    var parameter = NSInteger(0)
                    let data  = NSData(bytes: &parameter, length: 1)
                    ble.myPeripheral!.writeValue(data as Data, for: ble.automateCharacteristic!, type: CBCharacteristicWriteType.withResponse)
                    print("Automate Watering OFF")
                    
                    // set waterOption to 0
                    var parameter2 = NSInteger(0);
                    let data2  = NSData(bytes: &parameter2, length: 1)
                    ble.myPeripheral!.writeValue( data2 as Data, for: ble.waterOptionCharacteristic!, type: CBCharacteristicWriteType.withResponse)
                }
            }
        //update vc
        vc.waterStart = WaterTime.date as NSDate
        vc.waterSwitchVal = sender.isOn
        vc.waterOption = 1;
        waterTimeStack?.backgroundColor = UIColor.systemBackground
        waterNowStack?.backgroundColor = UIColor.systemBackground
        waterAutomateStack?.backgroundColor = UIColor.systemGray5
        
    }
    
    @IBOutlet weak var waterNowStack: UIStackView!
    
    @IBOutlet weak var waterNowButton: UIButton!
    @IBAction func WaterNowAction(_ sender: Any) {
        if ble.waterNowCharacteristic != nil{
            var parameter = NSInteger(1)
            let data  = NSData(bytes: &parameter, length: 1)
            ble.myPeripheral!.writeValue(data as Data, for: ble.waterNowCharacteristic!, type: CBCharacteristicWriteType.withResponse)
            print("Manually watering now")
            
            // Set waterOption to 2
            var parameter2 = NSInteger(2);
            let data2  = NSData(bytes: &parameter2, length: 1)
            ble.myPeripheral!.writeValue( data2 as Data, for: ble.waterOptionCharacteristic!, type: CBCharacteristicWriteType.withResponse)
            
            //update vc
            vc.waterOption = 2
            waterNowStack?.backgroundColor = UIColor.systemGray5
            waterTimeStack?.backgroundColor = UIColor.systemBackground
            waterAutomateStack?.backgroundColor = UIColor.systemBackground
            
        }
    // do i need to write back to a 0 to turn pump off? We'll see.
    //My guess is we need to make sure the write goes through, then send a 0 after X seconds to turn the pump off.
    // later... im thingking now if we write a 1 than a 0 immediatly, each val gets read sequentially and we can say if (1) waterPlant()
    // that way itll get tripped once and then turn not run again. We'll see tho.
    }
    
    
    @IBOutlet weak var SetWaterButton: UIButton!
    
    // TODO: fix water like you fixed lights
    @IBAction func SetWaterAction(_ sender: Any) {
        if(WaterTime == nil || WaterFreq.text == nil) {
            print("Missing required fields")
            return
        }
        
        var time = abs(NSDate().timeIntervalSince(WaterTime.date))
        //var extraTime = 0.0;
        if(NSDate().timeIntervalSince(WaterTime.date) > 0) // if the time already passed today
        {
            if( time < 60){ // this time is this current minute. Start it immediatly
                // extraTime = time  // need to add this remaining time to the timer so it still ends at top of minute.
                // if we used this ^^ we would need to have it run longer for the first time and then back to normal after. Leave it for now
                // the only diff will be if they start it on the minute it runs the second they pushed, not top of minute.
                time = 0
            }
            else { // this time has passed. Have it start tomorrow
                print("this time has passed")
                time = (60*60*24) - time;
            }
        }
        let waterFreqInt = Int(WaterFreq.text ?? "0")!;  // if no feild is entered freq set to 0
        let waterFreqSeconds = (60*60*24*waterFreqInt)
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
        
        // Set waterOption to 3
        var parameter3 = NSInteger(3);
        let data3  = NSData(bytes: &parameter3, length: 1)
        ble.myPeripheral!.writeValue( data3 as Data, for: ble.waterOptionCharacteristic!, type: CBCharacteristicWriteType.withResponse)
        
        //update VC
        vc.waterFreqString = WaterFreq.text!
        vc.waterStart = WaterTime.date as NSDate
        waterTimeStack?.backgroundColor = UIColor.systemGray5
        waterAutomateStack?.backgroundColor = UIColor.systemBackground
        waterNowStack?.backgroundColor = UIColor.systemBackground
        vc.waterOption = 3
        
    }

}

