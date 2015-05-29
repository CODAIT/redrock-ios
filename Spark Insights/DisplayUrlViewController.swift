//
//  DisplayUrlViewController.swift
//  TwiiterCellView
//
//  Created by Barbara Gomes on 5/27/15.
//  Copyright (c) 2015 Barbara Gomes. All rights reserved.
//

import UIKit

class DisplayUrlViewController: UIViewController {

    @IBOutlet weak var URLwebView: UIWebView!
    var loadUrl = ""
    
    @IBAction func dismissViewController(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let url = NSURL (string: loadUrl)
        {
            let requestObj = NSURLRequest(URL: url)
            URLwebView.loadRequest(requestObj);
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
