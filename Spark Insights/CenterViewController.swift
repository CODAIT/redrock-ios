//
//  ViewController.swift
//  Spark Insights
//
//  Created by Jonathan Alter on 5/27/15.
//  Copyright (c) 2015 IBM. All rights reserved.
//

import UIKit
import WebKit
import MessageUI
import Social

@objc
protocol CenterViewControllerDelegate {
    optional func toggleRightPanel(close: Bool)
    optional func collapseSidePanels()
    optional func displaySearchViewController()
}

class CenterViewController: UIViewController, WKNavigationDelegate, UIScrollViewDelegate, PageControlDelegate, MFMailComposeViewControllerDelegate, NetworkDelegate{

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
    var currentPage : Int = 0
    var previousPage : Int = 0
    var pageChanged = false
   
    //Can update search
    var canUpdateSearch = false
    
    @IBOutlet weak var headerLabel: UIButton!
    
    @IBOutlet weak var foundUsersNumberLabel: UILabel!
    @IBOutlet weak var foundTweetsNumberLabel: UILabel!
    @IBOutlet weak var searchedTweetsNumberLabel: UILabel!
    @IBOutlet weak var pageControlViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var dummyView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var leftView: UIView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var scrollViewLoadingView: UIView!
    
    @IBOutlet weak var statusBarSeparator: UIView!
    @IBOutlet weak var pageControlView: PageControlView!
    
    @IBOutlet weak var tweetsFooterView: UIView!
    @IBOutlet weak var tweetsFooterLabel: UILabel!
    @IBOutlet weak var tweetsFooterSeparatorLine: UIView!
    
    @IBOutlet weak var searchButtonView: UIView!
    
    var tweetsTableViewController: TweetsTableViewController!
    var firstLoad = true
    /* TODO: replace this function with equiv
    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        print("Webview \(webView.request) fail with error \(error)");
    }
    */
    override func viewDidAppear(animated: Bool) {
        if firstLoad
        {
            self.setupWebViews()
        }
        firstLoad = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        visualizationHandler.firstLoad = true
        self.setupTweetsTableView()
        self.setupScrollView()
        visualizationHandler.searchText = searchText!
        //Log(visualizationHandler.searchText)

        pageControlView.buttonSelectedBackgroundColor = Config.tealColor
        
        for i in 0..<Config.visualizationNames.count{
            pageControlView.buttonData.append(PageControlButtonData(imageName: Config.visualizationButtons[i], selectedImageName: Config.visualizationButtonsSelected[i]))
        }
        
        pageControlView.delegate = self
        self.pageControlViewWidthConstraint.constant = CGFloat(pageControlView.buttonData.count * pageControlView.buttonWidth)
        
        //Display time of last update
        self.configureGestureRecognizerForTweetFooterView()
        self.changeLastUpdated(false, waitingResponse: true)
        
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
                changeLastUpdated(false, waitingResponse: true)
            }
        }
        
    }
    
    func changeLastUpdated(callWaitToSearch: Bool, waitingResponse: Bool)
    {
        var dateNow = NSDate()
        var dateFormat = NSDateFormatter()
        dateFormat.dateFormat = "E, MMM d hh:mm aa"
        dateFormat.timeZone = NSTimeZone.localTimeZone()
        if waitingResponse
        {
             self.tweetsFooterLabel.text = "Waiting ..."
        }
        else
        {
           self.tweetsFooterLabel.text = "Last updated: " + dateFormat.stringFromDate(dateNow)
        }
        self.canUpdateSearch = false
        self.tweetsFooterView.backgroundColor = Config.darkBlueColor
        self.tweetsFooterSeparatorLine.hidden = false
        self.tweetsFooterView.alpha = 1.0
        if callWaitToSearch && Config.displayRefreshAvailable
        {
           self.waitToUpdateSearch()
        }
    }
    
    func waitToUpdateSearch()
    {
        // 5min until new update be available
        let delay = 300.0 * Double(NSEC_PER_SEC)
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
    func setupWebViews()
    {
        for i in 0..<Config.getNumberOfVisualizations(){
            let tempVisPath = Config.visualisationFolderPath.stringByAppendingPathComponent(Config.visualizationNames[i].stringByAppendingPathExtension("html")!)
            let request = NSURLRequest(URL: NSURL.fileURLWithPath(tempVisPath)!)
            
            var myOrigin = CGFloat(i) * self.scrollView.frame.size.width
            
            var myWebView : WKWebView

            visualizationHandler.scrollViewWidth = self.scrollView.frame.size.width
            visualizationHandler.scrollViewHeight = self.scrollView.frame.size.height
            
            myWebView = WKWebView(frame: CGRectMake(myOrigin, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height))
            
            //myWebView.scalesPageToFit = Config.scalePagesToFit[i] //TODO: stackoverflow this, there is a long solution
            myWebView.navigationDelegate = self
            
            // don't let webviews scroll
            myWebView.scrollView.scrollEnabled = false;
            myWebView.scrollView.bounces = false;
            
            visualizationHandler.webViews.append(myWebView)
            self.scrollView.addSubview(myWebView)
            // set initial loading state
            myWebView.hidden = true
            
            if i == Config.visualizationsIndex.stackedbar.rawValue
            {
                createSliderForBarChart(myOrigin)
            }
            
            myWebView.loadRequest(request)
        }
    }

    func createSliderForBarChart(origin: CGFloat)
    {
        let rangeSlider = RangeSliderUIControl(frame: CGRectZero)
        rangeSlider.frame = CGRect(x: origin + 80, y: self.scrollView.frame.height - 55,
            width: self.scrollView.frame.width - 160, height: 18.0)
        rangeSlider.addTarget(self, action: "rangeSliderValueChanged:", forControlEvents: .ValueChanged)
        
        visualizationHandler.rangeSliderBarChart = rangeSlider
        self.scrollView.addSubview(rangeSlider)
        var leftLabel = createUILabelRange(CGFloat(origin + 80), align: NSTextAlignment.Left)
        var rightLabel = createUILabelRange(CGFloat(origin + (self.scrollView.frame.width - 160)), align: NSTextAlignment.Right)
        
        self.scrollView.addSubview(leftLabel)
        self.scrollView.addSubview(rightLabel)
        visualizationHandler.rangeLabels.append(leftLabel)
        visualizationHandler.rangeLabels.append(rightLabel)
        
        /* send the touch began event to the uiView in that position 
        instead of always try to scroll*/
        self.scrollView.delaysContentTouches = false
        
        rangeSlider.hidden = true
        rightLabel.hidden = true
        leftLabel.hidden = true
    }
    
    func createUILabelRange(origin: CGFloat, align: NSTextAlignment) -> UILabel
    {
        let rangeLabel = UILabel()
        rangeLabel.frame = CGRectMake(origin, self.scrollView.frame.height - 36, 80, 18);
        rangeLabel.numberOfLines = 1
        rangeLabel.font = UIFont(name: "HelveticaNeue-Thin", size: 10)
        rangeLabel.textColor = Config.darkGrayTextColor
        rangeLabel.textAlignment = align
        rangeLabel.text = "May 30"
        rangeLabel.backgroundColor = UIColor.whiteColor()
        return rangeLabel
    }
    
    func rangeSliderValueChanged(rangeSlider: RangeSliderUIControl) {
        
        var maxDate = Double(visualizationHandler.stackedbarData.count) - 1
        
        //Transform range from 0-1 to 0-count
        var lowerIndex: Int = Int(round(maxDate * rangeSlider.lowerValue))
        var upperIndex: Int = Int(round(rangeSlider.upperValue * maxDate))
        
        self.visualizationHandler.redrawStackedBarWithNewRange(lowerIndex, upperIndex: upperIndex)
    }
    
    /*
        sets up the scrollview that contains the webviews
    */
    func setupScrollView() {
        for i in 0..<Config.getNumberOfVisualizations() {
            var myOrigin = CGFloat(i) * self.scrollView.frame.size.width
            self.scrollView.delegate = self
            
            // scroll view center
            var center = self.scrollView.center
            center.x = myOrigin + center.x
            
            //Loading view
            var activityIndicator = createActivityIndicatorView(myOrigin, center: center)
            self.scrollView.addSubview(activityIndicator)
            visualizationHandler.loadingViews.append(activityIndicator)
            
            //Results Label
            var label = createUILabelForError(myOrigin, center: center)
            self.scrollView.addSubview(label)
            visualizationHandler.resultsLabels.append(label)
            
            //Title Labels
            //self.scrollView.addSubview(createUILabel(Config.visualizationTitles[i], origin: myOrigin))
            
            //loading control
            visualizationHandler.isloadingVisualization.append(true)
            visualizationHandler.errorDescription.append("")
        }
        
        self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * CGFloat(Config.getNumberOfVisualizations()), self.scrollView.frame.size.height)
        self.visualizationHandler.firstLoad = false
    }
    
    func createActivityIndicatorView(origin: CGFloat, center: CGPoint) -> UIActivityIndicatorView
    {
        let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        activityIndicator.frame = CGRectMake(origin, 0, 100, 100);
        activityIndicator.center = center
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.WhiteLarge
        activityIndicator.color = Config.darkBlueColor
        activityIndicator.startAnimating()
        return activityIndicator
    }
    
    func createUILabelForError(origin: CGFloat, center: CGPoint) -> UILabel
    {
        let label = UILabel()
        label.frame = CGRectMake(origin, 0, 300, 300);
        label.numberOfLines = 3
        label.center = center
        label.textColor = Config.darkBlueColor
        label.text = Config.noDataMessage
        label.font = UIFont(name: "HelveticaNeue-Medium", size: 19)
        label.textAlignment = NSTextAlignment.Center
        label.hidden = true
        return label
    }
    
    func createUILabel(text: String, origin: CGFloat) -> UILabel
    {
        let titleLabel = UILabel()
        titleLabel.frame = CGRectMake(origin, 0, self.scrollView.frame.size.width, 40);
        titleLabel.numberOfLines = 1
        titleLabel.font = UIFont(name: "HelveticaNeue-Medium", size: 16)
        titleLabel.textColor = Config.darkGrayTextColor
        titleLabel.text = text
        titleLabel.textAlignment = NSTextAlignment.Center
        titleLabel.backgroundColor = Config.lightWhiteIce
        return titleLabel
    }
    
    // MARK: - UIScrollViewDelegate
    
    //detect when the page was changed
    func scrollViewDidScroll(scrollView: UIScrollView) {
        var pageWidth = scrollView.frame.size.width
        var fractionalPage = Float(scrollView.contentOffset.x / pageWidth)
        var page : Int = Int(round(fractionalPage))
        
        if (page >= Config.getNumberOfVisualizations()) {
            page = Config.getNumberOfVisualizations()-1
        }
        if (currentPage != page) { //page was changed
            //Log("page was changed from \(previousPage) to \(page)")
            pageChanged = true
            previousPage = currentPage
            currentPage = page
            pageControlView.selectedIndex = page
            
            if previousPage == Config.visualizationsIndex.timemap.rawValue{
                //Log("left timemap so stop animation")
                visualizationHandler.stopTimemap()
            }
            if page == Config.visualizationsIndex.timemap.rawValue{
                //Log("entered timemap so start animation")
                visualizationHandler.startTimemap()
            }
            
            if previousPage == Config.visualizationsIndex.forcegraph.rawValue{
                //Log("left forcegraph so stop animation")
                self.visualizationHandler.stopForcegraph()
            }
            if page == Config.visualizationsIndex.forcegraph.rawValue{
                //Log("entered forcegraph so start animation")
                self.visualizationHandler.startForcegraph()
            }
        }
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        resetZoomOnLastPage()
    }
    
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        resetZoomOnLastPage()
    }
    
    // MARK: UIScrollViewDelegate helpers
    
    func resetZoomOnLastPage() {
        if (pageChanged) {
            pageChanged = false
            // Resetting the zoom level on the previous page when it is no longer visible
            var webViewScrollView = visualizationHandler.webViews[previousPage].scrollView
            webViewScrollView.zoomScale = webViewScrollView.minimumZoomScale
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
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
        
        if self.searchedTweetsNumberLabel != nil
        {
            self.searchedTweetsNumberLabel.text = ""
        }
        if self.foundUsersNumberLabel != nil
        {
            self.foundUsersNumberLabel.text = ""
        }
        if self.foundTweetsNumberLabel != nil
        {
            self.foundTweetsNumberLabel.text = ""
        }
        if self.tweetsFooterView != nil && self.tweetsFooterLabel != nil
        {
            self.changeLastUpdated(false, waitingResponse: true)
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
            let delay = Config.dummyDataDelay * Double(NSEC_PER_SEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            dispatch_after(time, dispatch_get_main_queue()) {
                self.onDummyRequestSuccess(nil)
            }
        } else {
            var search = self.getIncludeAndExcludeSeparated()
            var networkConnection = Network()
            networkConnection.delegate = self
            networkConnection.getDataFromServer(search.include, exclude: search.exclude)
        }
    }
    
    // MARK: - Network Delegate
    
    func displayRequestTime(time: String) {
        let alertController = UIAlertController(title: "Request Time", message:
            time, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func responseProcessed() {
        self.changeLastUpdated(true, waitingResponse: false)
    }
    
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
        
        /*
        var numberOfColumns = 2        // number of columns
        var containerName = "profession" // name of container for data
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            var data = self.returnArrayOfData(numberOfColumns, containerName: containerName, json: json!, chartIndex: Config.visualizationsIndex.treemap.rawValue)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if(data != nil){
                    self.visualizationHandler.treemapData = data!
                    Log("data for treemap!")
                    Log(data!.count)
                    self.visualizationHandler.isloadingVisualization[Config.visualizationsIndex.treemap.rawValue] = false
                    self.visualizationHandler.reloadAppropriateView(Config.visualizationsIndex.treemap.rawValue) //reload the current page
                }
                else{
                    self.visualizationHandler.errorDescription[Config.visualizationsIndex.treemap.rawValue] = Config.serverErrorMessage
                    self.visualizationHandler.errorState(Config.visualizationsIndex.treemap.rawValue, error: Config.serverErrorMessage)
                }
            })
        })*/

        
        var contentJson = json
        if contentJson != nil
        {
            if Config.serverMakeSingleRequest
            {
                contentJson = json!["profession"]
            }
        
            visualizationHandler.treemapData = contentJson!.description
        
            visualizationHandler.isloadingVisualization[Config.visualizationsIndex.treemap.rawValue] = false
            visualizationHandler.reloadAppropriateView(Config.visualizationsIndex.treemap.rawValue)

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
            self.searchedTweetsNumberLabel.text = "Error"
            self.foundTweetsNumberLabel.text = "Error"
            self.foundUsersNumberLabel.text = "Error"
            return
        }
        else
        {
            if json!["totalusers"] != nil
            {
                self.foundUsersNumberLabel.text = self.formatNumberToDisplay(Int64(json!["totalusers"].intValue))
            }
            else
            {
                self.foundUsersNumberLabel.text = "Error"
            }
            if json!["totaltweets"] != nil
            {
                self.searchedTweetsNumberLabel.text = self.formatNumberToDisplay(Int64(json!["totaltweets"].intValue))
            }
            else
            {
                self.searchedTweetsNumberLabel.text = "Error"
            }
            if json!["totalfilteredtweets"] != nil
            {
                self.foundTweetsNumberLabel.text = self.formatNumberToDisplay(Int64(json!["totalfilteredtweets"].intValue))
            }
            else
            {
                self.foundTweetsNumberLabel.text = "Error"
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
                //Log(cellJson.stringValue)
                
                tableData[r][c] = cellJson.stringValue.stringByReplacingOccurrencesOfString("\"", withString: "").stringByReplacingOccurrencesOfString("'", withString: "").stringByReplacingOccurrencesOfString("\n", withString: "") //remove quotes
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
        
        self.changeLastUpdated(true, waitingResponse: false)
    }
    
    func populateUI(json: JSON){
        self.handleTweetsCallBack(json, error: nil)
        self.handleTopMetrics(json, error: nil)
        
        //Log("location")
        self.handleLocationCallBack(json, error: nil )

        //Log("profession")
        self.handleProfessionCallBack(json, error: nil)
        
        //Log("sentiment")
        self.handleSentimentsCallBack(json, error: nil)
        
        //Log("distance")
        self.handleWordDistanceCallBack(json, error: nil) // "distance" is not being doublepacked
        
        //Log("topic") //topic??
        //self.handleWordCloudCallBack(json, error: nil) // "topic" but not double-nested
        
        //Log("cluster") //cluster??
        self.handleWordClusterCallBack(json, error: nil) // "cluster" but not double-nested
    }
    
}

