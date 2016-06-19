//
//  ShareViewController.swift
//  ShareEcon
//
//  Created by Martin L on 6/18/16.
//  Copyright © 2016 Martin L. All rights reserved.
//

import UIKit
import ArcGIS

class ShareViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var textShare: UITextField!
    
    @IBOutlet weak var addShare: UIButton!
    
    @IBOutlet weak var tableShare: UITableView!
    
    var data = ["Shovel"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableShare.dataSource = self

        // Do any additional setup after loading the view.
    }

    @IBAction func addSharePress(sender: AnyObject) {
        if textShare.text != ""{
            data.append(textShare.text!)
            textShare.text = ""
            tableShare.reloadData()
        }
        
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
