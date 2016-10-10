//
//  HelpViewController.swift
//  RedRock
//
//  Created by Jonathan Alter on 10/10/16.
//  Copyright © 2016 IBM. All rights reserved.
//

/**
 * (C) Copyright IBM Corp. 2016, 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

import UIKit

class HelpViewController: UIViewController, UIWebViewDelegate {
    @IBOutlet weak var webView: UIWebView!
    
    var mainFile = "help.html"
    
    override func viewDidLoad() {
        Log("loading \(mainFile)")
        let tempVisPath = NSURL(fileURLWithPath: Config.visualizationFolderPath).URLByAppendingPathComponent(NSURL(fileURLWithPath: self.mainFile).path!)
        let request = NSURLRequest(URL: tempVisPath)
        webView.loadRequest(request)
    }
    
    override func viewWillAppear(animated: Bool) {
        self.preferredContentSize = CGSizeMake(400, 400)
    }
    
    // MARK: - UIWebViewDelegate
    
    func  webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType == UIWebViewNavigationType.LinkClicked {
            UIApplication.sharedApplication().openURL(request.URL!)
            return false
        }
        return true
    }
}
