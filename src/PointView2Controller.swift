//
//  ViewController.swift
//
//  Created by Kevin Stumph on 1/19/19.
//  Copyright © 2019 Kevin Stumph. All rights reserved.
//

import Cocoa

class PointView2Controller: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func kdtreeMenuItemSelected(_ sender: Any) {
//        kdtreeButtonClicked(sender)
        Swift.print("KDTree Menu Item Clicked")
    }
}

