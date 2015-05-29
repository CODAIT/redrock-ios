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

    var searchText: String?
    var delegate: CenterViewControllerDelegate?
    
    // the name of the HTML file corresponding to a visualization in /Visualizations
    let numberOfViews = 3
    let visualizationNames = ["treemap", "circlepacking", "worddistance"]
    
    @IBOutlet weak var dummyView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var leftView: UIView!
    @IBOutlet weak var headerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.setupTweetsTableView()
        self.setupScrollView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupTweetsTableView()
    {
        if let tweetsController = self.storyboard?.instantiateViewControllerWithIdentifier("TweetsTableViewController") as?TweetsTableViewController
        {
            addChildViewController(tweetsController)
            let height = self.view.frame.height - self.footerView.frame.height - self.headerView.frame.height
            tweetsController.view.frame = CGRectMake(0, headerView.frame.height , self.leftView.frame.width, height);
            self.leftView.addSubview(tweetsController.view)
            tweetsController.didMoveToParentViewController(self)
        }
    }

    /*
        Creates UIWebViews for the 3 views
    */
    func setupScrollView() {
        var colors = [UIColor.blueColor(), UIColor.darkGrayColor(), UIColor.grayColor()]
        
        for i in 0..<numberOfViews {
            
            let filePath = NSBundle.mainBundle().URLForResource("Visualizations/"+visualizationNames[i], withExtension: "html")
            let request = NSURLRequest(URL: filePath!)
            
            var myOrigin = CGFloat(i) * self.dummyView.frame.size.width
            
            var myWebView = UIWebView(frame: CGRectMake(myOrigin, 0, self.dummyView.frame.size.width, self.dummyView.frame.size.height))
            myWebView.backgroundColor = colors[i % numberOfViews]
            
            myWebView.loadRequest(request)
            
            // set the delegate so data can be loaded in
            myWebView.delegate = self
            
            self.scrollView.addSubview(myWebView)
        }
        
        self.scrollView.contentSize = CGSizeMake(self.dummyView.frame.size.width * CGFloat(numberOfViews), self.dummyView.frame.size.height)
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        //get the data in there somehow
        println(webView.request!.URL!.lastPathComponent!)
        
        // should tell it which webView I am with some property
        switch webView.request!.URL!.lastPathComponent!{
        case visualizationNames[0]+".html":
            transformDataForTreemapping(webView)
        case visualizationNames[1]+".html":
            transformDataForCirclepacking(webView)
        case visualizationNames[2]+".html":
            transformDataForWorddistance(webView)
        default:
            break
        }
    }
    
    func transformDataForTreemapping(webView: UIWebView){
        var treeScript = "var data7 = '{\"name\": \"all\",\"children\": [{\"name\": \"accountant\",\"children\": [{\"name\": \"accountant\", \"size\": 3938}]},{\"name\": \"cop\",\"children\": [{\"name\": \"cop\", \"size\": 743}]}]}'; renderChart(data7);"
        
        webView.stringByEvaluatingJavaScriptFromString(treeScript)
    }
    
    func transformDataForCirclepacking(webView: UIWebView){
        var treeScript = "var data7 = '{\"name\": \"all\",\"children\": [{\"name\": \"accountant\",\"children\": [{\"name\": \"accountant\", \"size\": 3938}]},{\"name\": \"cop\",\"children\": [{\"name\": \"cop\", \"size\": 743}]}]}'; renderChart(data7);"
        
        webView.stringByEvaluatingJavaScriptFromString(treeScript)
    }
    
    func transformDataForWorddistance(webView: UIWebView){
        var wordScript = "var myData = '{\"name\": \"cat\",\"children\": [{\"name\": \"feline\", \"distance\": 0.6, \"size\": 44},{\"name\": \"dog\", \"distance\": 0.4, \"size\": 22},{\"name\": \"bunny\", \"distance\": 0.0, \"size\": 10},{\"name\": \"gif\", \"distance\": 1.0, \"size\": 55},{\"name\": \"tail\", \"distance\": 0.2, \"size\": 88},{\"name\": \"fur\", \"distance\": 0.7, \"size\": 50}]}'; renderChart(myData);"

        webView.stringByEvaluatingJavaScriptFromString(wordScript)
    }
    
    @IBAction func searchClicked(sender: UIButton) {
        delegate?.toggleRightPanel?()
    }
    
}

