//
//  ViewController.swift
//  Spark Insights
//
//  Created by Jonathan Alter on 5/27/15.
//  Copyright (c) 2015 IBM. All rights reserved.
//

// make some request
// comes back as a JSON
// parse the JSOn

import UIKit

@objc
protocol CenterViewControllerDelegate {
    optional func toggleRightPanel()
    optional func collapseSidePanels()
}

class CenterViewController: UIViewController, UIWebViewDelegate, UIScrollViewDelegate, PageControlDelegate {

    var searchText: String?
    weak var delegate: CenterViewControllerDelegate?
    var lineSeparatorWidth = CGFloat(4)
    
    var visualizationHandler: VisualizationHandler = VisualizationHandler()
    let visualizationNames = ["circlepacking", "stackedbar", "treemap", "timemap", "worddistance"] // currently this needs to manually match the buttondata positions //these are the names of the HTML files
    
    var colors = [UIColor.blueColor(), UIColor.darkGrayColor(), UIColor.grayColor(), UIColor.purpleColor(), UIColor.redColor()]

    // last visited page
    var previousPage = 0
   
    //Can update search
    var canUpdateSearch = false
    
    @IBOutlet weak var pageControlViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var dummyView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var leftView: UIView!
    @IBOutlet weak var headerView: UIView!
    
    @IBOutlet weak var pageControlView: PageControlView!
    
    @IBOutlet weak var tweetsFooterView: UIView!
    @IBOutlet weak var tweetsFooterLabel: UILabel!
    @IBOutlet weak var tweetsFooterSeparatorLine: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.setupTweetsTableView()
        self.setupVisualizationHandler()
        self.setupWebViews()
        self.setupScrollView()

        // currently this relies on the order of elements
        pageControlView.buttonSelectedBackgroundColor = Config.tealColor
        pageControlView.buttonData = [
            PageControlButtonData(imageName: "Bubble_TEAL", selectedImageName: "Bubble_WHITE"),
            PageControlButtonData(imageName: "Bar_TEAL", selectedImageName: "Bar_WHITE"),
            PageControlButtonData(imageName: "Tree_TEAL", selectedImageName: "Tree_WHITE"),
            PageControlButtonData(imageName: "Map_TEAL", selectedImageName: "Map_WHITE"),
            PageControlButtonData(imageName: "Network_TEAL", selectedImageName: "Network_WHITE")
        ]
        pageControlView.delegate = self
        self.pageControlViewWidthConstraint.constant = CGFloat(pageControlView.buttonData.count * pageControlView.buttonWidth)
        
        //Display time of last update
        self.configureGestureRecognizerForTweetFooterView()
        self.changeLastUpdated()

        //makeARequestToGetTheData();
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureGestureRecognizerForTweetFooterView()
    {
        let tapGesture = UITapGestureRecognizer(target: self, action: "updateSearchRequested:")
        self.tweetsFooterView.addGestureRecognizer(tapGesture)
        self.tweetsFooterView.userInteractionEnabled = true
    }
    
    func updateSearchRequested(gesture: UIGestureRecognizer)
    {
        if self.canUpdateSearch
        {
            //Update all necessary data
            self.tweetsFooterView.alpha = 0.5
            self.changeLastUpdated()
        }
    }
    
    func changeLastUpdated()
    {
        var dateNow = NSDate()
        var dateFormat = NSDateFormatter()
        dateFormat.dateFormat = "hh:mm aa"
        dateFormat.timeZone = NSTimeZone.localTimeZone()
        self.tweetsFooterLabel.text = "Last updated: " + dateFormat.stringFromDate(dateNow)
        self.canUpdateSearch = false
        self.tweetsFooterView.backgroundColor = Config.darkBlueColor
        self.tweetsFooterSeparatorLine.hidden = false
        self.tweetsFooterView.alpha = 1.0
        self.waitToUpdateSearch()
    }
    
    func waitToUpdateSearch()
    {
        // 5min until new update be available
        let delay = 300.0 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            self.canUpdateSearch = true
            self.tweetsFooterLabel.text = "Refresh Available"
            self.tweetsFooterView.backgroundColor = Config.mediumGreen
            self.tweetsFooterSeparatorLine.hidden = true
        }
    }
    
    func setupTweetsTableView()
    {
        if let tweetsController = self.storyboard?.instantiateViewControllerWithIdentifier("TweetsTableViewController") as?TweetsTableViewController
        {
            addChildViewController(tweetsController)
            let height = self.view.frame.height - self.footerView.frame.height - self.headerView.frame.height - self.lineSeparatorWidth
            tweetsController.view.frame = CGRectMake(0, headerView.frame.height + 1 , self.leftView.frame.width, height);
            self.leftView.addSubview(tweetsController.view)
            
            // Simulating request delay
            let delay = 2.0 * Double(NSEC_PER_SEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            dispatch_after(time, dispatch_get_main_queue()) {
                tweetsController.tweets = ReadTweetsData.readJSON()!
                tweetsController.tableView.reloadData()
            }
            //-----
            
            tweetsController.didMoveToParentViewController(self)
        }
    }

    /*
    func gotDataResponseHandler(String: data){
        //var jsonData = jsonifyData(data)
        visualizationHandler.reloadViewsWithData(jsonData)
    }
    */
    
    /*
        populates the visualizationHandler
    */
    func setupVisualizationHandler() {
        visualizationHandler.visualizationNames = self.visualizationNames // the name of the HTML file corresponding to a visualization in /Visualizations
    }
    
    /*
        creates the webviews
    */
    func setupWebViews() {
        for i in 0..<visualizationHandler.getNumberOfVisualizations(){
            let filePath = NSBundle.mainBundle().URLForResource("Visualizations/"+visualizationHandler.visualizationNames[i], withExtension: "html")
            let request = NSURLRequest(URL: filePath!)
            
            var myOrigin = CGFloat(i) * self.scrollView.frame.size.width
            
            var myWebView = UIWebView(frame: CGRectMake(myOrigin, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height))
            myWebView.backgroundColor = colors[i % visualizationHandler.getNumberOfVisualizations()]
            
            myWebView.loadRequest(request)
            
            // don't let webviews scroll
            myWebView.scrollView.scrollEnabled = false;
            myWebView.scrollView.bounces = false;
            
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
            if((page+1)<visualizationHandler.getNumberOfVisualizations()){ //preload the next view to avoid "pop"
                visualizationHandler.reloadAppropriateView(page+1)
            }
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
        visualizationHandler.transformData(webView)
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

