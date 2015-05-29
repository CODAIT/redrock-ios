//
//  ViewController.swift
//  Spark Insights
//
//  Created by Jonathan Alter on 5/27/15.
//  Copyright (c) 2015 IBM. All rights reserved.
//

import UIKit

@objc
protocol CenterViewControllerDelegate {
    optional func toggleRightPanel()
    optional func collapseSidePanels()
}

class CenterViewController: UIViewController, UIWebViewDelegate {

    var delegate: CenterViewControllerDelegate?
    
    @IBOutlet weak var dummyView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var footerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    
        self.setupScrollView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setupScrollView() {
        var colors = [UIColor.blueColor(), UIColor.darkGrayColor(), UIColor.grayColor()]
        
        
        // REQUESTS
        let treeFilePath = NSBundle.mainBundle().URLForResource("Visualizations/treemap", withExtension: "html")
        let treeRequest = NSURLRequest(URL: treeFilePath!)
        
        let greenFilePath = NSBundle.mainBundle().URLForResource("Visualizations/circlepacking", withExtension: "html")
        let greenRequest = NSURLRequest(URL: greenFilePath!)
        
        let blueFilePath = NSBundle.mainBundle().URLForResource("Visualizations/blue", withExtension: "html")
        let blueRequest = NSURLRequest(URL: blueFilePath!)
        
        var requests = [treeRequest, greenRequest, blueRequest]
        
        var numberOfViews = 3
        
        for i in 0..<numberOfViews {
            var myOrigin = CGFloat(i) * self.dummyView.frame.size.width
            
            var myWebView = UIWebView(frame: CGRectMake(myOrigin, 0, self.dummyView.frame.size.width, self.dummyView.frame.size.height))
            myWebView.backgroundColor = colors[i % numberOfViews]
            
            myWebView.loadRequest(requests[i])
            
            myWebView.delegate = self
            
            self.scrollView.addSubview(myWebView)
        }
        
        self.scrollView.contentSize = CGSizeMake(self.dummyView.frame.size.width * CGFloat(numberOfViews), self.dummyView.frame.size.height)
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        //var data = receiveData();
        //println("data: \(data)")
        
        // should tell it which webView I am with some property
        
        // SCRIPTS
        var treeScript = "var data7 = '{\"name\": \"all\",\"children\": [{\"name\": \"accountant\",\"children\": [{\"name\": \"accountant\", \"size\": 3938}]},{\"name\": \"cop\",\"children\": [{\"name\": \"cop\", \"size\": 743}]}]}'; renderChart(data7);"
                
        //var greenScript = ""
        //var blueScript = ""
        //var scripts = [treeScript, greenScript, blueScript]
        //var numberOfViews = 3

        webView.stringByEvaluatingJavaScriptFromString(treeScript)
        
        //println("webViewDidFinishLoad")
    }
    
    @IBAction func searchClicked(sender: UIButton) {
        delegate?.toggleRightPanel?()
    }
    
}

