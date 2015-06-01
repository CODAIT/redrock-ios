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

class CenterViewController: UIViewController, UIWebViewDelegate, UIScrollViewDelegate, PageControlDelegate {

    var searchText: String?
    weak var delegate: CenterViewControllerDelegate?
    
    var visualizationHandler: VisualizationHandler = VisualizationHandler()
    
    var colors = [UIColor.blueColor(), UIColor.darkGrayColor(), UIColor.grayColor()]

    // last visited page
    var previousPage = 0
    
    @IBOutlet weak var dummyView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var leftView: UIView!
    @IBOutlet weak var headerView: UIView!
    
    @IBOutlet weak var pageControlView: PageControlView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.setupTweetsTableView()
        self.setupVisualizationHandler()
        self.setupWebViews()
        self.setupScrollView()
        
        pageControlView.buttonData = [
            PageControlButtonData(imageName: "Bar_TEAL", selectedImageName: "Bar_WHITE"),
            PageControlButtonData(imageName: "Tree_TEAL", selectedImageName: "Tree_WHITE"),
            PageControlButtonData(imageName: "Map_TEAL", selectedImageName: "Map_WHITE")
        ]
        pageControlView.delegate = self
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
        populates the visualizationHandler
    */
    func setupVisualizationHandler() {
        // the name of the HTML file corresponding to a visualization in /Visualizations
        visualizationHandler.visualizationNames = ["treemap", "circlepacking", "worddistance"]
    }
    
    /*
        creates the webviews
    */
    func setupWebViews() {
        for i in 0..<visualizationHandler.getNumberOfVisualizations(){
            let filePath = NSBundle.mainBundle().URLForResource("Visualizations/"+visualizationHandler.visualizationNames[i], withExtension: "html")
            let request = NSURLRequest(URL: filePath!)
            
            var myOrigin = CGFloat(i) * self.dummyView.frame.size.width
            
            var myWebView = UIWebView(frame: CGRectMake(myOrigin, 0, self.dummyView.frame.size.width, self.dummyView.frame.size.height))
            myWebView.backgroundColor = colors[i % visualizationHandler.getNumberOfVisualizations()]
            
            myWebView.loadRequest(request)
            
            // set the delegate so data can be loaded in
            myWebView.delegate = self
            
            visualizationHandler.webViews.append(myWebView)
            
        }
        
    }
    
    /*
        sets up the scrollview that contains the webviews
    */
    func setupScrollView() {
        for i in 0..<visualizationHandler.getNumberOfVisualizations() {
            let myWebView = visualizationHandler.webViews[i]
            self.scrollView.addSubview(myWebView)
            self.scrollView.delegate = self
        }
        
        self.scrollView.contentSize = CGSizeMake(self.dummyView.frame.size.width * CGFloat(visualizationHandler.getNumberOfVisualizations()), self.dummyView.frame.size.height)
    }
    
    // MARK: UIScrollViewDelegate
    
    //detect when the page was changed
    func scrollViewDidScroll(scrollView: UIScrollView) {
        var pageWidth = scrollView.frame.size.width
        var fractionalPage = Float(scrollView.contentOffset.x / pageWidth)
        var page : Int = Int(round(fractionalPage))
        if(previousPage != page){
            println("page was changed to... \(page)")
            previousPage = page
            visualizationHandler.reloadAppropriateView(page)
            pageControlView.selectedIndex = page
        }
    }
    
    // MARK: UIWebViewDelegate
    
    /*
        When a page finishes loading, load in the javascript
    */
    func webViewDidFinishLoad(webView: UIWebView) {
        //get the data in there somehow
        println("I finished my load..." + webView.request!.URL!.lastPathComponent!)
        
        // should tell it which webView I am with some property
        // can do better than this
        switch webView.request!.URL!.lastPathComponent!{
        case visualizationHandler.visualizationNames[0]+".html":
            visualizationHandler.transformDataForTreemapping(webView)
        case visualizationHandler.visualizationNames[1]+".html":
            visualizationHandler.transformDataForCirclepacking(webView)
        case visualizationHandler.visualizationNames[2]+".html":
            visualizationHandler.transformDataForWorddistance(webView)
        default:
            break
        }
    }
    
    // MARK: PageControlDelegate
    
    func pageChanged(index: Int) {
        println("Page Changed to index: \(index)")
        var offset = scrollView.frame.size.width * CGFloat(index)
        scrollView.setContentOffset(CGPointMake(offset, 0), animated: true)
    }
    
    // MARK: Actions
    
    @IBAction func searchClicked(sender: UIButton) {
        delegate?.toggleRightPanel?()
    }
    
}

