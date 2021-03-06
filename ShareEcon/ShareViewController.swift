//
//  ShareViewController.swift
//  ShareEcon
//
//  Created by Martin L on 6/18/16.
//  Copyright © 2016 Martin L. All rights reserved.
//

import UIKit
import ArcGIS
import SwiftyJSON
import CoreLocation

class ShareViewController: UIViewController, UITableViewDelegate, CLLocationManagerDelegate, UITableViewDataSource {

    @IBOutlet weak var textShare: UITextField!
    
    @IBOutlet weak var addShare: UIButton!
    
    @IBOutlet weak var tableShare: UITableView!
    
    var data = [""]
    var currentLocation = ""
    var lat: Double = 0.0
    var long: Double = 0.0
    
    var  locationManager:CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableShare.dataSource = self
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()

        // Do any additional setup after loading the view.
    }

    @IBAction func addSharePress(sender: AnyObject) {
        if textShare.text != ""{
            data.append(textShare.text!)
            postData(textShare.text!)
            textShare.text = ""
            tableShare.reloadData()
        }
        
    }
    
    func postData(itemName: String){
        let request = NSMutableURLRequest(URL: NSURL(string: "http://localhost:3000/" + itemName)!)
        request.HTTPMethod = "POST"
        let postString = "name=\(itemName)&lat=\(lat)&long=\(long)"
        request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
            guard error == nil && data != nil else {                                                          // check for fundamental networking error
                print("error=\(error)")
                return
            }
            
            if let httpStatus = response as? NSHTTPURLResponse where httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
            }
            
            let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print("responseString = \(responseString)")
        }
        task.resume()
    }
    
    func locationManager(manager:CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        lat = locations[0].coordinate.latitude;
        long = locations[0].coordinate.longitude;
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Default, reuseIdentifier: nil)
        cell.textLabel?.text = data[indexPath.row]
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
