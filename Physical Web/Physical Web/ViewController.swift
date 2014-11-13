//
//  ViewController.swift
//  Physical Web
//
//  Created by Mathias Dahlstrom on 13/11/2014.
//  Copyright (c) 2014 Skyscanner. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, UITableViewDataSource {

    @IBOutlet var tableView:UITableView?
    
    var btleManager:CBCentralManager?
    var beacons = [PhysicalWebBeacon]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btleManager = CBCentralManager(delegate:self, queue:nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        switch central.state {
        case CBCentralManagerState.PoweredOff:
            println("Power off")
        case CBCentralManagerState.PoweredOn:
            println("Power On")
            btleManager?.scanForPeripheralsWithServices([CBUUID(string: "FED8")], options: nil)
        case CBCentralManagerState.Resetting:
            println("Reset")
        case CBCentralManagerState.Unauthorized:
            println("Unauthorized")
        case CBCentralManagerState.Unsupported:
            println("Unsupported")
        case CBCentralManagerState.Unknown:
            println("Unknown")
        }
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        if let info = advertisementData[CBAdvertisementDataServiceDataKey] as? Dictionary<CBUUID,NSData> {
            if let data = info[CBUUID(string: "FED8")] {
                if let validData = PhysicalWebBeacon.validatePhysicalWebGadget(data) {
                    beacons.append(PhysicalWebBeacon(scannedValues:validData))
                }
            }
            
        }
    }
    
    // MARK: - UITtableViewDelegate
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return beacons.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BeaconCell", forIndexPath: indexPath) as UITableViewCell
        cell.textLabel.text = beacons[indexPath.row].url?.absoluteString
        return cell
    }
}

class PhysicalWebBeacon {
    var name:String?
    var url:NSURL?
    var batteryLevel:Int?
    var flags:Int?
    
    init(scannedValues:Dictionary<NSString,AnyObject>) {
        name = scannedValues["Name"] as? String
        flags = scannedValues["Flags"] as? Int
        batteryLevel = scannedValues["PowerLevel"] as? Int
        let urlString = NSString(data: (scannedValues["URL"] as NSData), encoding: NSASCIIStringEncoding)
        url = NSURL(string: urlString!)
    }
    
    class func validatePhysicalWebGadget(data:NSData) -> Dictionary<NSString,AnyObject>? {
        var dataArray = [UInt8](count:data.length, repeatedValue:0)
        data.getBytes(&dataArray, length:data.length)
        //Invalid length
        if(dataArray.count < 2){
            return nil
        }
        return ["Flags": NSNumber(unsignedChar: dataArray[0]), "PowerLevel": NSNumber(unsignedChar: dataArray[1]), "URL": data.subdataWithRange(NSMakeRange(2, data.length-2))]
    }
}