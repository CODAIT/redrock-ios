//
//  DisplayUrlViewController.swift
//  TwiiterCellView
//
//  Created by Barbara Gomes on 5/27/15.
//

/**
* (C) Copyright IBM Corp. 2015, 2015
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

class DisplayUrlViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var URLwebView: UIWebView!
    var loadUrl = ""
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    @IBAction func dismissViewController(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadingIndicator.startAnimating()
        self.URLwebView.delegate = self
        if let url = NSURL (string: loadUrl)
        {
            let requestObj = NSURLRequest(URL: url)
            URLwebView.loadRequest(requestObj);
        }
        // Do any additional setup after loading the view.
    }

    func webViewDidFinishLoad(webView: UIWebView) {
        self.loadingIndicator.stopAnimating()
        self.loadingIndicator.hidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
