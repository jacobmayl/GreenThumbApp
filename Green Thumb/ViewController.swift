//
//  ViewController.swift
//  Green Thumb
//
//  Created by Jacob Mayl on 3/28/21.
//

import UIKit

class ViewController: UIViewController {
    
    // global booleans acting as flags:
    var lights_on: Bool = false;
    var start_watering: Bool = false;
    var automate_watering: Bool = false;
    
    //HOME PAGE
    // connect device button
    @IBOutlet weak var connect: UIButton!
    
    //READINGS PAGE
    // cant get the labels to come over here...
    @IBOutlet weak var temp_reading: UILabel!
    //LIGHTING PAGE

    @IBAction func lightswitch(_ sender: UISwitch) {
        if(sender.isOn) {
            lights_on = true;
        }
        else {
            lights_on = false;
        }
    }
    @IBAction func start_time(_ sender: Any) {
    }
    @IBAction func end_time(_ sender: Any) {
    }
    
    //WATER PAGE
    @IBAction func water_now(_ sender: UIButton) {
        start_watering = true;
        // need this to get set to false sometime.
        //Not sure where
    }
    @IBAction func number_days(_ sender: Any) {
    }
    @IBAction func water_time(_ sender: Any) {
    }
    @IBAction func automate(_ sender: Any) {
        automate_watering = true;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

}

