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
import MessageUI
import Social

@objc
protocol CenterViewControllerDelegate {
    optional func toggleRightPanel(close: Bool)
    optional func collapseSidePanels()
    optional func displaySearchViewController()
}

class CenterViewController: UIViewController, UIWebViewDelegate, UIScrollViewDelegate, PageControlDelegate, MFMailComposeViewControllerDelegate, NetworkDelegate{

    var searchText: String? {
        didSet {
            self.cleanViews()
            self.loadDataFromServer()
        }
    }
    weak var delegate: CenterViewControllerDelegate?
    var lineSeparatorWidth = CGFloat(4)
    
    var visualizationHandler: VisualizationHandler = VisualizationHandler()
    
    // last visited page
    var previousPage = 0
   
    //Can update search
    var canUpdateSearch = false
    
    @IBOutlet weak var headerLabel: UIButton!
    @IBOutlet weak var tweetsPerHourNumberLabel: UILabel!
    @IBOutlet weak var totalUsersNumberLabel: UILabel!
    @IBOutlet weak var totalTweetsNumberLabel: UILabel!
    @IBOutlet weak var pageControlViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var dummyView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var leftView: UIView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var scrollViewLoadingView: UIView!
    
    // Rosstin: I made these separate so that if one finishes before the other, they don't both disappear
    //  alternatively we could write some logic to check both conditions before removing the view
    // if we have more than one loading view, we could iterate a static variable and then decrement it until it was 0
    private var loadingView1 :LoadingView! // the loading view for the executeRequest
    //private var loadingView2 :LoadingView! // the loading view for the tweets
    
    @IBOutlet weak var statusBarSeparator: UIView!
    @IBOutlet weak var pageControlView: PageControlView!
    
    @IBOutlet weak var tweetsFooterView: UIView!
    @IBOutlet weak var tweetsFooterLabel: UILabel!
    @IBOutlet weak var tweetsFooterSeparatorLine: UIView!
    
    @IBOutlet weak var searchButtonView: UIView!
    
    var tweetsTableViewController: TweetsTableViewController!
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        print("Webview \(webView.request) fail with error \(error)");
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        visualizationHandler.firstLoad = true
        self.setupTweetsTableView()
        self.setupWebViews()
        self.setupScrollView()
        visualizationHandler.searchText = searchText!
        Log(visualizationHandler.searchText)

        // currently this relies on the order of elements
        pageControlView.buttonSelectedBackgroundColor = Config.tealColor
        
        for i in 0..<Config.visualizationNames.count{
            pageControlView.buttonData.append(PageControlButtonData(imageName: Config.visualizationButtons[i], selectedImageName: Config.visualizationButtonsSelected[i]))
        }
        
        pageControlView.delegate = self
        self.pageControlViewWidthConstraint.constant = CGFloat(pageControlView.buttonData.count * pageControlView.buttonWidth)
        
        //Display time of last update
        self.configureGestureRecognizerForTweetFooterView()
        self.changeLastUpdated()
        
        //search icon
        self.configureGestureRecognizerForSearchIconView()
        
        self.headerLabel.setTitle(self.searchText, forState: UIControlState.Normal)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        self.resetViewController()
    }
    
    // MARK: - Reset UI
    
    func resetViewController() {
        // Use this function to reset the view controller's UI to a clean state
        Log("Resetting \(__FILE__)")
    }
    
    func configureGestureRecognizerForSearchIconView()
    {
        let tapGesture = UILongPressGestureRecognizer(target: self, action: "searchClicked:")
        tapGesture.minimumPressDuration = 0.001
        self.searchButtonView.addGestureRecognizer(tapGesture)
        self.searchButtonView.userInteractionEnabled = true
    }
    
    func configureGestureRecognizerForTweetFooterView()
    {
        let tapGesture = UILongPressGestureRecognizer(target: self, action: "updateSearchRequested:")
        tapGesture.minimumPressDuration = 0.001
        self.tweetsFooterView.addGestureRecognizer(tapGesture)
        self.tweetsFooterView.userInteractionEnabled = true
    }
    
    func updateSearchRequested(gesture: UIGestureRecognizer)
    {
        if self.canUpdateSearch
        {
            if gesture.state == UIGestureRecognizerState.Began
            {
                self.tweetsFooterView.alpha = 0.5
            }
            else if gesture.state == UIGestureRecognizerState.Ended
            {
                let currentSearch = self.searchText
                self.searchText = currentSearch
                self.tweetsFooterView.alpha = 0.5
            }
        }
    }
    
    func changeLastUpdated()
    {
        var dateNow = NSDate()
        var dateFormat = NSDateFormatter()
        dateFormat.dateFormat = "E, MMM d hh:mm aa"
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
        let delay = 500.0 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            self.canUpdateSearch = true
            UIView.animateWithDuration(2, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: UIViewAnimationOptions.TransitionFlipFromBottom, animations: {
                self.tweetsFooterLabel.text = "Refresh Available"
                self.tweetsFooterView.backgroundColor = Config.mediumGreen
                self.tweetsFooterSeparatorLine.hidden = true
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    func setupTweetsTableView()
    {
        self.tweetsTableViewController = self.storyboard?.instantiateViewControllerWithIdentifier("TweetsTableViewController") as?TweetsTableViewController
        
        addChildViewController(tweetsTableViewController)
        let height = self.view.frame.height - self.footerView.frame.height - self.headerView.frame.height - self.lineSeparatorWidth - self.statusBarSeparator.frame.height
        self.tweetsTableViewController.view.frame = CGRectMake(0, headerView.frame.height+self.statusBarSeparator.frame.height , self.leftView.frame.width, height);
        self.leftView.addSubview(self.tweetsTableViewController.view)
        tweetsTableViewController.didMoveToParentViewController(self)
    }
    
    func formatNumberToDisplay(number: Int64) -> String
    {
        let billion = Int64(999999999)
        let million = Int64(999999)
        let thousand = Int64(999)
        var div = 0.0
        var letter = ""
        if number > billion
        {
            div = Double(number)/Double((billion+1))
            letter = "B"
        }
        else if number > million
        {
            div = Double(number)/Double((million+1))
            letter = "M"
        }
        else if number > thousand
        {
            div = Double(number)/Double((thousand+1))
            letter = "K"
        }
        else
        {
            return String(number)
        }
        
        return String(format: "%.1f", div) + String(letter)
    }
    
    /*
        creates the webviews
    */
    func setupWebViews() {
        for i in 0..<Config.getNumberOfVisualizations(){
            let filePath = NSBundle.mainBundle().URLForResource("Visualizations/"+Config.visualizationNames[i], withExtension: "html")
            let request = NSURLRequest(URL: filePath!)
            
            var myOrigin = CGFloat(i) * self.scrollView.frame.size.width
            
            var myWebView : UIWebView

            visualizationHandler.scrollViewWidth = self.scrollView.frame.size.width
            visualizationHandler.scrollViewHeight = self.scrollView.frame.size.height

            myWebView = UIWebView(frame: CGRectMake(myOrigin, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height))
            
            myWebView.scalesPageToFit = Config.scalePagesToFit[i]
            //myWebView.backgroundColor = colors[i % Config.getNumberOfVisualizations()]
            
            myWebView.loadRequest(request)
            
            // don't let webviews scroll
            myWebView.scrollView.scrollEnabled = false;
            myWebView.scrollView.bounces = false;
            
            // set the delegate so data can be loaded in
            myWebView.delegate = self
            
            visualizationHandler.webViews.append(myWebView)
            
            // set initial loading state
            myWebView.hidden = true

            
        }
    }
    
    /*
        sets up the scrollview that contains the webviews
    */
    func setupScrollView() {
        for i in 0..<Config.getNumberOfVisualizations() {
            let myWebView = visualizationHandler.webViews[i]
            self.scrollView.addSubview(myWebView)
            var myOrigin = CGFloat(i) * self.scrollView.frame.size.width
            self.scrollView.delegate = self
            
            // scroll view center
            var center = self.scrollView.center
            center.x = myOrigin + center.x
            
            //Loading view
            let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
            activityIndicator.frame = CGRectMake(myOrigin, 0, 100, 100);
            activityIndicator.center = center
            activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.WhiteLarge
            activityIndicator.color = Config.darkBlueColor
            activityIndicator.startAnimating()
            self.scrollView.addSubview(activityIndicator)
            visualizationHandler.loadingViews.append(activityIndicator)
            
            //Results Label
            let label = UILabel()
            label.frame = CGRectMake(myOrigin, 0, 300, 300);
            label.numberOfLines = 3
            label.center = center
            label.textColor = Config.darkBlueColor
            label.text = Config.noDataMessage
            label.font = UIFont(name: "HelveticaNeue-Medium", size: 19)
            label.textAlignment = NSTextAlignment.Center
            label.hidden = true
            self.scrollView.addSubview(label)
            visualizationHandler.resultsLabels.append(label)
            
            //loading control
            visualizationHandler.isloadingVisualization.append(true)
            visualizationHandler.errorDescription.append("")
        }
        
        self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * CGFloat(Config.getNumberOfVisualizations()), self.scrollView.frame.size.height)
        self.visualizationHandler.firstLoad = false
    }
    
    // MARK: - UIScrollViewDelegate
    
    //detect when the page was changed
    func scrollViewDidScroll(scrollView: UIScrollView) {
        var pageWidth = scrollView.frame.size.width
        var fractionalPage = Float(scrollView.contentOffset.x / pageWidth)
        var page : Int = Int(round(fractionalPage))
        
        if(page >= Config.getNumberOfVisualizations()){
            page = Config.getNumberOfVisualizations()-1
        }
        if(previousPage != page){
            previousPage = page
            //visualizationHandler.reloadAppropriateView(page)
            pageControlView.selectedIndex = page
        }
    }
    
    // MARK: - UIWebViewDelegate
    
    /*
        When a page finishes loading, load in the javascript
    */
    func webViewDidFinishLoad(webView: UIWebView) {
        //get the data in there somehow
        //Log("I finished my load..." + webView.request!.URL!.lastPathComponent!)
        visualizationHandler.transformData(webView)

    }
    
    // MARK: - PageControlDelegate
    
    func pageChanged(index: Int) {
        //Log("Page Changed to index: \(index)")
        var offset = scrollView.frame.size.width * CGFloat(index)
        scrollView.setContentOffset(CGPointMake(offset, 0), animated: true)
    }
    
    func searchClicked(gesture: UIGestureRecognizer) {
        if gesture.state == UIGestureRecognizerState.Began
        {
            self.searchButtonView.alpha = 0.5
        }
        else if gesture.state == UIGestureRecognizerState.Ended
        {
            delegate?.toggleRightPanel?(false)
            self.searchButtonView.alpha = 1.0
        }
    }
    
    // MARK - Actions
    
    @IBAction func shareScreenClicked(sender: UIButton){
        
        let mailComposeViewController = configuredMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            self.presentViewController(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        mailComposerVC.setSubject("IBM RedRock")
        mailComposerVC.addAttachmentData(UIImageJPEGRepresentation(getScreenShot(), 1), mimeType: "image/jpeg", fileName: "IBMSparkInsightsScreenShot.jpeg")
        return mailComposerVC
    }
    
    func getScreenShot() -> UIImage
    {
        let layer = UIApplication.sharedApplication().keyWindow!.layer
        let scale = UIScreen.mainScreen().scale
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale);
        
        layer.renderInContext(UIGraphicsGetCurrentContext())
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        UIImageWriteToSavedPhotosAlbum(screenshot, nil, nil, nil)
        
        return screenshot
    }
    
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertView(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", delegate: self, cancelButtonTitle: "OK")
        sendMailErrorAlert.show()
    }
    
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func headerTitleClicked(sender: AnyObject) {
        delegate?.toggleRightPanel!(true)
        delegate?.displaySearchViewController?()
    }
    
    func cleanViews()
    {
        if self.tweetsTableViewController != nil
        {
            tweetsTableViewController.emptySearchResult = false
            tweetsTableViewController.errorMessage = nil
            tweetsTableViewController.tweets = []
            tweetsTableViewController.tableView.reloadData()
        }
        
        if self.totalTweetsNumberLabel != nil
        {
            self.totalTweetsNumberLabel.text = ""
        }
        if self.totalUsersNumberLabel != nil
        {
            self.totalUsersNumberLabel.text = ""
        }
        if self.tweetsPerHourNumberLabel != nil
        {
            self.tweetsPerHourNumberLabel.text = ""
        }
        if self.tweetsFooterView != nil && self.tweetsFooterLabel != nil
        {
            self.changeLastUpdated()
        }
        if self.headerLabel != nil
        {
            self.headerLabel.setTitle(self.searchText, forState: UIControlState.Normal)
        }
        self.visualizationHandler.cleanWebViews()
    }
    
    func getIncludeAndExcludeSeparated() -> (include: String, exclude: String)
    {
        let terms = self.searchText!.componentsSeparatedByString(",")
        var includeStr = ""
        var excludeStr = ""
        for var i = 0; i < terms.count; i++
        {
            var term = terms[i]
            if term != ""
            {
                var aux = Array(term)
                if aux[0] == "-"
                {
                    aux.removeAtIndex(0)
                    excludeStr = excludeStr + String(aux) + ","
                }
                else
                {
                    includeStr = includeStr + term + ","
                }
            }
        }
        
        var vector = Array(includeStr)
        if vector.count > 0
        {
            vector.removeLast()
        }
        includeStr = String(vector)
        vector = Array(excludeStr)
        if vector.count > 0
        {
            vector.removeLast()
        }
        excludeStr = String(vector)
        
        return (includeStr, excludeStr)

    }
    // MARK: - Network
    
    func loadDataFromServer()
    {
        if (Config.useDummyData) {
            //loadingView1 = LoadingView(frame: view.frame)
            //view.addSubview(loadingView1!)
            
            let delay = Config.dummyDataDelay * Double(NSEC_PER_SEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            dispatch_after(time, dispatch_get_main_queue()) {
                self.onDummyRequestSuccess(nil)
                self.changeLastUpdated()
                //self.loadingView1.removeFromSuperview()
            }
        } else {
            //loadingView1 = LoadingView(frame: view.frame)
            //view.addSubview(loadingView1!)
            var search = self.getIncludeAndExcludeSeparated()
            var networkConnection = Network()
            networkConnection.delegate = self
            networkConnection.getDataFromServer(search.include, exclude: search.exclude)
        }
    }
    
    // MARK: - Network Delegate
    
    func handleTweetsCallBack(json: JSON?, error: NSError?) {
        if ((error) != nil) {
            self.tweetsTableViewController.errorMessage = error!.localizedDescription
        }
        else if json != nil
        {
            //select the json content according to appropriate request
            var tweetsContent = json!
            if Config.serverMakeSingleRequest
            {
                tweetsContent = json!["toptweets"]
            }
            
            if tweetsContent != nil
            {
                if tweetsContent["tweets"].count == 0
                {
                    self.tweetsTableViewController.emptySearchResult = true
                }
                self.tweetsTableViewController.tweets = tweetsContent["tweets"]
            }
            else
            {
                self.tweetsTableViewController.errorMessage = Config.serverErrorMessage
            }
        }
        else
        {
            self.tweetsTableViewController.errorMessage = Config.serverErrorMessage
        }
        self.tweetsTableViewController.tableView.reloadData()
    }
    
    func handleLocationCallBack(json: JSON?, error: NSError?) {
        if (error != nil) {
            visualizationHandler.errorDescription[Config.visualizationsIndex.timemap.rawValue] = "\(error!.localizedDescription)"
            visualizationHandler.errorState(Config.visualizationsIndex.timemap.rawValue, error: "\(error!.localizedDescription)")
            return
        }
        var numberOfColumns = 3        // number of columns
        var containerName = "location" // name of container for data //TODO: unknown
        
        var contentJson = json
        if contentJson != nil
        {
            if Config.serverMakeSingleRequest
            {
                contentJson = json![containerName]
            }
            if contentJson != nil
            {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    var data = self.returnArrayOfData(numberOfColumns, containerName: containerName, json: contentJson!, chartIndex: Config.visualizationsIndex.timemap.rawValue)
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        if(data != nil){
                            self.visualizationHandler.timemapData = data!
                            self.visualizationHandler.isloadingVisualization[Config.visualizationsIndex.timemap.rawValue] = false
                            self.visualizationHandler.reloadAppropriateView(Config.visualizationsIndex.timemap.rawValue) //reload the current page
                        }
                        else{
                            self.visualizationHandler.errorDescription[Config.visualizationsIndex.timemap.rawValue] = Config.serverErrorMessage
                            self.visualizationHandler.errorState(Config.visualizationsIndex.timemap.rawValue, error: Config.serverErrorMessage)
                        }
                    })
                })
            }
            else
            {
                self.visualizationHandler.errorDescription[Config.visualizationsIndex.timemap.rawValue] = Config.serverErrorMessage
                self.visualizationHandler.errorState(Config.visualizationsIndex.timemap.rawValue, error: Config.serverErrorMessage)
            }
        }
        else
        {
            self.visualizationHandler.errorDescription[Config.visualizationsIndex.timemap.rawValue] = Config.serverErrorMessage
            self.visualizationHandler.errorState(Config.visualizationsIndex.timemap.rawValue, error: Config.serverErrorMessage)
        }
    }

    func handleSentimentsCallBack(json: JSON?, error: NSError?) {
        if (error != nil) {
            visualizationHandler.errorDescription[Config.visualizationsIndex.stackedbar.rawValue] = "\(error!.localizedDescription)"
            visualizationHandler.errorState(Config.visualizationsIndex.stackedbar.rawValue, error: "\(error!.localizedDescription)")
            return
        }
        var numberOfColumns = 4        // number of columns
        var containerName = "sentiment" // name of container for data //TODO: unknown
        
        
        var contentJson = json
        if contentJson != nil
        {
            if Config.serverMakeSingleRequest
            {
                contentJson = json![containerName]
            }
            
            if contentJson != nil
            {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    var data = self.returnArrayOfData(numberOfColumns, containerName: containerName, json: contentJson!, chartIndex: Config.visualizationsIndex.stackedbar.rawValue)
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        if(data != nil){
                            self.visualizationHandler.stackedbarData = data!
                            self.visualizationHandler.isloadingVisualization[Config.visualizationsIndex.stackedbar.rawValue] = false
                            self.visualizationHandler.reloadAppropriateView(Config.visualizationsIndex.stackedbar.rawValue) //reload the current page
                        }
                        else{
                            self.visualizationHandler.errorDescription[Config.visualizationsIndex.stackedbar.rawValue] = Config.serverErrorMessage
                            self.visualizationHandler.errorState(Config.visualizationsIndex.stackedbar.rawValue, error: Config.serverErrorMessage)
                        }
                    })
                })
            }
            else
            {
                self.visualizationHandler.errorDescription[Config.visualizationsIndex.stackedbar.rawValue] = Config.serverErrorMessage
                self.visualizationHandler.errorState(Config.visualizationsIndex.stackedbar.rawValue, error: Config.serverErrorMessage)
            }
        }
        else
        {
            self.visualizationHandler.errorDescription[Config.visualizationsIndex.stackedbar.rawValue] = Config.serverErrorMessage
            self.visualizationHandler.errorState(Config.visualizationsIndex.stackedbar.rawValue, error: Config.serverErrorMessage)
        }
        
    }
    
    func handleWordDistanceCallBack(json: JSON?, error: NSError?) {
        //Log("handleWordDistanceCallBack")
        if (error != nil) {
            visualizationHandler.errorDescription[Config.visualizationsIndex.forcegraph.rawValue] = "\(error!.localizedDescription)"
            visualizationHandler.errorState(Config.visualizationsIndex.forcegraph.rawValue, error: "\(error!.localizedDescription)")
            return
        }
        var numberOfColumns = 3        // number of columns
        var containerName = "distance" // name of container for data
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            var data = self.returnArrayOfData(numberOfColumns, containerName: containerName, json: json!, chartIndex: Config.visualizationsIndex.forcegraph.rawValue)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if(data != nil){
                    //Log("forcegraph data wasn't nil")
                    self.visualizationHandler.forcegraphData = data!
                    self.visualizationHandler.searchText = self.searchText!
                    self.visualizationHandler.isloadingVisualization[Config.visualizationsIndex.forcegraph.rawValue] = false
                    self.visualizationHandler.reloadAppropriateView(Config.visualizationsIndex.forcegraph.rawValue) //reload the current page
                }
                else{
                    self.visualizationHandler.errorDescription[Config.visualizationsIndex.forcegraph.rawValue] = Config.serverErrorMessage
                    self.visualizationHandler.errorState(Config.visualizationsIndex.forcegraph.rawValue, error: Config.serverErrorMessage)
                }
            })
        })
    }
    func handleWordClusterCallBack(json: JSON?, error: NSError?) {
        if (error != nil) {
            visualizationHandler.errorDescription[Config.visualizationsIndex.circlepacking.rawValue] = "\(error!.localizedDescription)"
            visualizationHandler.errorState(Config.visualizationsIndex.circlepacking.rawValue, error: "\(error?.localizedDescription)")
            return
        }
        else if(json == nil){
            self.visualizationHandler.errorDescription[Config.visualizationsIndex.circlepacking.rawValue] = Config.serverErrorMessage
            visualizationHandler.errorState(Config.visualizationsIndex.circlepacking.rawValue, error: Config.serverErrorMessage)
            return
        }
        
        var numberOfColumns = 4        // number of columns
        var containerName = "cluster" // name of container for data
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            var data = self.returnArrayOfData(numberOfColumns, containerName: containerName, json: json!, chartIndex: Config.visualizationsIndex.circlepacking.rawValue)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if(data != nil){
                    self.visualizationHandler.circlepackingData = data!
                    self.visualizationHandler.isloadingVisualization[Config.visualizationsIndex.circlepacking.rawValue] = false
                    self.visualizationHandler.reloadAppropriateView(Config.visualizationsIndex.circlepacking.rawValue) //reload the current page
                }
                else{
                    self.visualizationHandler.errorDescription[Config.visualizationsIndex.circlepacking.rawValue] = Config.serverErrorMessage
                    self.visualizationHandler.errorState(Config.visualizationsIndex.circlepacking.rawValue, error: Config.serverErrorMessage)
                }
            })
        })
    }
    
    func handleProfessionCallBack(json: JSON?, error: NSError?) {
        if (error != nil) {
            visualizationHandler.errorDescription[Config.visualizationsIndex.treemap.rawValue] = "\(error!.localizedDescription)"
            visualizationHandler.errorState(Config.visualizationsIndex.treemap.rawValue, error: "\(error!.localizedDescription)")
            return
        }
        
        var contentJson = json
        if contentJson != nil
        {
            if Config.serverMakeSingleRequest
            {
                contentJson = json!["profession"]
            }
            
            if contentJson != nil
            {
                
                if let professions = contentJson!["profession"].dictionaryObject as? Dictionary<String,Int>
                {
                    var keys = professions.keys
                    var treemap = [[String]]()
                    for profession in keys
                    {
                        if (professions[profession] != nil || professions[profession] != 0)
                        {
                            treemap.append([profession, String(professions[profession]!)])
                        }
                    }
                    visualizationHandler.treemapData = treemap
                    visualizationHandler.isloadingVisualization[Config.visualizationsIndex.treemap.rawValue] = false
                    visualizationHandler.reloadAppropriateView(Config.visualizationsIndex.treemap.rawValue)
                }
                else
                {
                    visualizationHandler.errorDescription[Config.visualizationsIndex.treemap.rawValue] = "JSON conversion error."
                    visualizationHandler.errorState(Config.visualizationsIndex.treemap.rawValue, error:"JSON conversion error.")
                }

            }
            else
            {
                visualizationHandler.errorDescription[Config.visualizationsIndex.treemap.rawValue] = Config.serverErrorMessage
                visualizationHandler.errorState(Config.visualizationsIndex.treemap.rawValue, error: Config.serverErrorMessage)
            }
        }
        else
        {
            visualizationHandler.errorDescription[Config.visualizationsIndex.treemap.rawValue] = Config.serverErrorMessage
            visualizationHandler.errorState(Config.visualizationsIndex.treemap.rawValue, error: Config.serverErrorMessage)
        }
    }
    
    func handleWordCloudCallBack(json: JSON?, error: NSError?) {
        if (error != nil) {
            visualizationHandler.errorDescription[Config.visualizationsIndex.wordcloud.rawValue] = "\(error!.localizedDescription)"
            visualizationHandler.errorState(Config.visualizationsIndex.wordcloud.rawValue, error: "\(error!.localizedDescription)")
            return
        }
        var numberOfColumns = 3        // number of columns
        var containerName = "topic" // name of container for data
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            var data = self.returnArrayOfData(numberOfColumns, containerName: containerName, json: json!, chartIndex: Config.visualizationsIndex.wordcloud.rawValue)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if(data != nil){
                    self.visualizationHandler.wordcloudData = data!
                    self.visualizationHandler.isloadingVisualization[Config.visualizationsIndex.wordcloud.rawValue] = false
                    self.visualizationHandler.reloadAppropriateView(Config.visualizationsIndex.wordcloud.rawValue) //reload the current page
                }
                else{
                    self.visualizationHandler.errorDescription[Config.visualizationsIndex.wordcloud.rawValue] = Config.serverErrorMessage
                    self.visualizationHandler.errorState(Config.visualizationsIndex.wordcloud.rawValue, error: Config.serverErrorMessage)
                }
            })
        })
    }
    
    func handleTopMetrics(json: JSON?, error: NSError?) {
        if (error != nil) {
            self.totalTweetsNumberLabel.text = "Error"
            self.totalUsersNumberLabel.text = "Error"
            self.tweetsPerHourNumberLabel.text = "Error"
            return
        }
        else
        {
            if json!["tweetsperhour"] != nil
            {
                self.tweetsPerHourNumberLabel.text = self.formatNumberToDisplay(Int64(json!["tweetsperhour"].intValue))
            }
            else
            {
                self.tweetsPerHourNumberLabel.text = "Error"
            }
            if json!["totalusers"] != nil
            {
                self.totalUsersNumberLabel.text = self.formatNumberToDisplay(Int64(json!["totalusers"].intValue))
            }
            else
            {
                self.totalUsersNumberLabel.text = "Error"
            }
            if json!["totaltweets"] != nil
            {
                 self.totalTweetsNumberLabel.text = self.formatNumberToDisplay(Int64(json!["totaltweets"].intValue))
            }
            else
            {
                self.totalTweetsNumberLabel.text = "Error"
            }
        }
    }
    
    func returnArrayOfData(numberOfColumns: Int, containerName: String, json: JSON, chartIndex: Int) -> Array<Array<String>>? {
        let col_cnt: Int? = numberOfColumns
        let row_cnt: Int? = json[containerName].array?.count
        
        if(row_cnt == nil || col_cnt == nil){
            visualizationHandler.errorState(chartIndex, error: Config.serverErrorMessage)
            return nil
        }
        
        var tableData = Array(count: row_cnt!, repeatedValue: Array(count: col_cnt!, repeatedValue: ""))
        
        // populates the 2d array
        for (row: String, rowJson: JSON) in json[containerName] {
            for (col: String, cellJson: JSON) in rowJson {
                //println(row, col, cellJson)
                let r: Int = row.toInt()!
                let c: Int = col.toInt()!
                //self.tableData[r][c] = cellJson.stringValue
                Log(cellJson.stringValue)
                
                tableData[r][c] = cellJson.stringValue.stringByReplacingOccurrencesOfString("\"", withString: "").stringByReplacingOccurrencesOfString("'", withString: "") //remove quotes
            }
        }
        return tableData
    }
    
    // Keeping this in case we switch back to using one call
    func displayRequestError(message: String) {
        self.tweetsFooterLabel.numberOfLines = 4
        self.tweetsFooterLabel.text = message
        self.tweetsFooterView.backgroundColor = UIColor.redColor()
    }
    
    //MARK: Dummy Data
    
    func onDummyRequestSuccess(json: JSON) {
        Log(__FUNCTION__)
        
        if (Config.serverMakeSingleRequest) {
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                
                let filePath = NSBundle.mainBundle().pathForResource("response_spark", ofType:"json")
                
                var readError:NSError?
                if let fileData = NSData(contentsOfFile:filePath!,
                    options: NSDataReadingOptions.DataReadingUncached,
                    error:&readError)
                {
                    // Read success
                    var parseError: NSError?
                    if let JSONObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(fileData, options: NSJSONReadingOptions.AllowFragments, error: &parseError)
                    {
                        // Parse success
                        let json = JSON(JSONObject!)
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.populateUI(json)
                        })
                    } else {
                        // Parse error
                        // TODO: handle error
                        Log("Error Parsing demo data: \(parseError?.localizedDescription)")
                    }
                } else {
                    // Read error
                    // TODO: handle error
                    Log("Error Reading demo data: \(readError?.localizedDescription)")
                }
                
            })
            
        } else {
            populateUI(json)
        }
    }
    
    func populateUI(json: JSON){
        self.handleTweetsCallBack(json, error: nil)
        self.handleTopMetrics(json, error: nil)
        
        Log("location")
        self.handleLocationCallBack(json, error: nil )

        Log("profession")
        self.handleProfessionCallBack(json, error: nil)
        
        Log("sentiment")
        self.handleSentimentsCallBack(json, error: nil)
        
        Log("distance")
        self.handleWordDistanceCallBack(json, error: nil) // "distance" is not being doublepacked
        
        Log("topic") //topic??
        self.handleWordCloudCallBack(json, error: nil) // "topic" but not double-nested
        
        Log("cluster") //cluster??
        self.handleWordClusterCallBack(json, error: nil) // "cluster" but not double-nested
    }
    
    func populateCharts(json : JSON){
        if(Config.useDummyData){
            visualizationHandler.circlepackingData = [["1","spark","222"],["1","sparksummit","344"],["2","#ibm","111"],["3","bigdata","577"],["3","analytics","99"],["4","@mapr","233"],["4","hadoop","333"],["4","hdfs","288"],["4","hortonworks","555"],["1","#sparkinsight","444"],["3","datamining","55"]]
            visualizationHandler.reorderCirclepackingData()
            
            visualizationHandler.treemapData = [["data scientist","222"],["programmer","344"],["designer","111"],["roboticist","577"],["marketer","99"],["barista","233"],["ceo","333"],["founder","288"],["fortune500","555"],["analyst","444"],["gamedev","55"]]
            
            visualizationHandler.stackedbarData = [["11/17","43","33"],["11/18","22", "22"],["11/19","22", "22"],["11/20","22", "22"],["11/21","22", "22"],["11/22","22", "22"],["11/23","22", "22"]]
            
            visualizationHandler.worddistanceData = [ [ "#datamining", "0.66010167854665769", "457" ], [ "#analytics", "0.66111733184244015", "3333" ], [ "#rstats", "0.69084306092036141", "361" ], [ "@hortonworks", "0.66914077012093209", "166" ], [ "#neo4j", "0.69127034015170996", "63" ], [ "#datascience", "0.67888717822606814", "4202" ], [ "#azure", "0.66226415367181413", "667" ], [ "@mapr", "0.66354464393456225", "165" ], [ "#deeplearning", "0.66175874534547685", "396" ], [ "#machinelearning", "0.6964340180591716", "2260" ], [ "#nosql", "0.75678772608504818", "877" ], [ "#sas", "0.70367785412709649", "145" ], [ "#mongodb", "0.6993281653000063", "225" ], [ "#hbase", "0.78010979167439309", "138" ], [ "#python", "0.69931247945181596", "2821" ], [ "#mapreduce", "0.72372695100578921", "62" ], [ "#apache", "0.75935793530857787", "244" ], [ "#cassandra", "0.76777460490727012", "128" ], [ "#hadoop", "0.82618702428574087", "1831" ], [ "#r", "0.76732526060916861", "277" ] ]
            
            visualizationHandler.wordcloudData = [["0", "link", "0.2"], ["0", "Very", "0.3"], ["0", "worry", "0.3"], ["0", "hold", "0.00001"], ["0", "City", "0.0002"], ["0", "Ackles", "0.01"], ["0", "places", "0.1"], ["0", "Followers", "0.001"], ["0", "donxe2x80x99t", "0.002"], ["0", "seems", "0.01"], ["1", "power", "0.1"], ["1", "keep", "0.22"], ["1", "Scherzinger", "0.3"], ["1", "@justinbieber:", "0.12"], ["1", "SUPER", "0.16"], ["1", "#ChoiceTVBreakOutStar", "0.09"], ["1", "#ChoiceMaleHottie", "0.35"], ["1", "call", "0.05"], ["1", "years", "0.2"], ["1", "change", "0.3"], ["2", "pretty", "0.15"], ["2", "needed", "0.12"], ["2", "like", "0.16"], ["2", "song", "0.002"], ["2", "SEHUN", "0.0000002"], ["2", "team", "0.01"], ["2", "Because", "0.012"], ["2", "needs", "0.004"], ["2", "forever", "0.12"], ["2", "stop", "0.17"], ["3", "fucking", "0.07"], ["3", "Followers", "0.16"], ["3", "#TheOriginals", "0.14"], ["3", "move", "0.02"], ["3", "close", "0.004"], ["3", "dream", "0.002"], ["3", "Update", "0.001"], ["3", "picture", "0.1"], ["3", "President", "0.015"], ["3", "play", "0.12"]]
            
            visualizationHandler.forcegraphData = [ [ "#datamining", "0.66010167854665769", "457" ], [ "#analytics", "0.66111733184244015", "3333" ], [ "#rstats", "0.69084306092036141", "361" ], [ "@hortonworks", "0.66914077012093209", "166" ], [ "#neo4j", "0.69127034015170996", "63" ], [ "#datascience", "0.67888717822606814", "4202" ], [ "#azure", "0.66226415367181413", "667" ], [ "@mapr", "0.66354464393456225", "165" ], [ "#deeplearning", "0.66175874534547685", "396" ], [ "#machinelearning", "0.6964340180591716", "2260" ], [ "#nosql", "0.75678772608504818", "877" ], [ "#sas", "0.70367785412709649", "145" ], [ "#mongodb", "0.6993281653000063", "225" ], [ "#hbase", "0.78010979167439309", "138" ], [ "#python", "0.69931247945181596", "2821" ], [ "#mapreduce", "0.72372695100578921", "62" ], [ "#apache", "0.75935793530857787", "244" ], [ "#cassandra", "0.76777460490727012", "128" ], [ "#hadoop", "0.82618702428574087", "1831" ], [ "#r", "0.76732526060916861", "277" ] ]
            
            visualizationHandler.timemapData =
                [ [  "20-Apr", "United States", "754" ], [ "20-Apr", "United Kingdom", "347" ], [ "21-Apr", "United States", "1687" ], ["21-Apr", "United Kingdom", "555"], [ "22-Apr", "United States", "2222" ], ["22-Apr", "United Kingdom", "155"], [ "23-Apr", "United States", "4343" ], ["23-Apr", "United Kingdom", "1214"], [ "24-Apr", "United States", "9999" ], ["24-Apr", "United Kingdom", "3333"], [ "25-Apr", "United States", "1687" ], ["25-Apr", "United Kingdom", "555"], [ "26-Apr", "United States", "1687" ], ["26-Apr", "United Kingdom", "555"] ]
        }
        visualizationHandler.reloadAppropriateView(previousPage) //reload the current page
        // other pages will get loaded when they are swiped to
    }
}

