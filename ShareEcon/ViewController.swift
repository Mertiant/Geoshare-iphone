//
//  ViewController.swift
//  ShareEcon
//
//  Created by Martin L on 6/18/16.
//  Copyright © 2016 Martin L. All rights reserved.
//

import UIKit
import ArcGIS

class ViewController: UIViewController {

    @IBOutlet weak var tabControll: UISegmentedControl!
    @IBOutlet weak var BorrowView: UIView!
    @IBOutlet weak var ShareView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func changedTab(sender: UISegmentedControl) {
        if (tabControll.selectedSegmentIndex == 0){
            ShareView.hidden = true
            BorrowView.hidden = false
        }
        else if(tabControll.selectedSegmentIndex == 1){
            ShareView.hidden = false
            BorrowView.hidden = true
        }
    }


}

