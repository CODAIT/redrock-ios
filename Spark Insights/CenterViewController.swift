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
import MapKit
import Darwin

@objc
protocol CenterViewControllerDelegate {
    optional func toggleRightPanel(close: Bool)
    optional func collapseSidePanels()
    optional func displaySearchViewController()
}

class CenterViewController: UIViewController, WKNavigationDelegate, MKMapViewDelegate, UIScrollViewDelegate, PageControlDelegate, LeftViewControllerDelegate, MFMailComposeViewControllerDelegate, NetworkDelegate{

    var searchText: String? {
        didSet {
            self.cleanViews()
            self.loadDataFromServer()
        }
    }
    weak var delegate: CenterViewControllerDelegate?
    var lineSeparatorWidth = CGFloat(4)
    
    var visualizationHandler: VisualizationHandler = VisualizationHandler()
    
    var leftViewController: LeftViewController!
    static var leftViewOpen = false
    
    // last visited page
    var currentPage : Int = 0
    var previousPage : Int = 0
    var pageChanged = false
    
    //Can update search
    var canUpdateSearch = false
    
    @IBOutlet weak var headerLabel: UIButton!
    
    @IBOutlet weak var pageControlViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var dummyView: UIView!
    @IBOutlet weak var scrollView: ResizingScrollView!
    @IBOutlet weak var holderView: UIView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var scrollViewLoadingView: UIView!
    
    @IBOutlet weak var statusBarSeparator: UIView!
    @IBOutlet weak var pageControlView: PageControlView!
    
    @IBOutlet weak var holderViewLeadingEdge: NSLayoutConstraint!
    @IBOutlet weak var dummyViewLeadingEdge: NSLayoutConstraint!
    @IBOutlet weak var footerViewLeadingEdge: NSLayoutConstraint!
    
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
        self.setupScrollView()
        visualizationHandler.searchText = searchText!
        //Log(visualizationHandler.searchText)

        pageControlView.buttonBackgroundColor = UIColor.clearColor()
        pageControlView.buttonSelectedBackgroundColor = Config.darkBlueColor
        
        for i in 0..<Config.visualizationNames.count{
            pageControlView.buttonData.append(PageControlButtonData(imageName: Config.visualizationButtons[i], selectedImageName: Config.visualizationButtonsSelected[i]))
        }
        
        pageControlView.delegate = self
        self.pageControlViewWidthConstraint.constant = CGFloat(pageControlView.buttonData.count * pageControlView.buttonWidth)
        
        self.headerLabel.setTitle(self.searchText, forState: UIControlState.Normal)
        
        addLeftPanelViewController()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        self.resetViewController()
    }
    
    func addLeftPanelViewController() {
        leftViewController = UIStoryboard.leftViewController()
        leftViewController.view.frame = CGRectMake(-350, 0, 354, 768)
        leftViewController.delegate = self
        view.addSubview(leftViewController.view)
        addChildViewController(leftViewController)
        leftViewController.didMoveToParentViewController(self)
    }
    
    @IBAction func toggleFeedButtonClicked(sender: UIButton) {
        toggleLeftPanel()
    }
    
    @IBAction func showInfoView(sender: UIButton) {
        let controller = UIStoryboard.infoViewController()
        controller?.modalPresentationStyle = UIModalPresentationStyle.Popover
        
        let popover = controller?.popoverPresentationController
        popover?.sourceView = sender
        popover?.sourceRect = sender.bounds
        popover?.permittedArrowDirections = UIPopoverArrowDirection.Any
        
        self.presentViewController(controller!, animated: true, completion: nil)
    }
    
    // MARK: - LeftViewControllerDelegate
    
    func toggleLeftPanel() {
        if (CenterViewController.leftViewOpen) { //get bigger
            // animate out
            self.animateLeftPanelXPosition(targetPosition: -350)
            CenterViewController.leftViewOpen = false
            
            visualizationHandler.hideRangeSliderBarChartAndLabels()
            
            visualizationHandler.scrollViewWidth = self.scrollView.frame.size.width + 350.0
            //reloadAllViews()
            

            //should move this code into animateLeftPanelXPosition so it's not hardcoded this ugly way
            let myOrigin = (CGFloat(Config.visualizationsIndex.stackedbar.rawValue) * (1024.0))
            repositionSliderForBarChart(myOrigin, widthShrinkFactor: -350.0)
        } else { //get smaller
            // animate in
            self.animateLeftPanelXPosition(targetPosition: 0)
            CenterViewController.leftViewOpen = true
            
            visualizationHandler.hideRangeSliderBarChartAndLabels()
            
            visualizationHandler.scrollViewWidth = self.scrollView.frame.size.width - 350.0
            //reloadAllViews()
            
            //should move this code into animateLeftPanelXPosition so it's not hardcoded this ugly way
            let myOrigin = (CGFloat(Config.visualizationsIndex.stackedbar.rawValue) * 674.0)
            repositionSliderForBarChart(myOrigin, widthShrinkFactor: 350.0)
        }
    }
    
    func animateLeftPanelXPosition(targetPosition targetPosition: CGFloat, completion: ((Bool) -> Void)! = nil) {
        leftViewController.onAnimationStart()
        self.scrollView.viewWillResize()
        self.footerViewLeadingEdge.constant = targetPosition + 350
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            self.leftViewController.view.frame.origin.x = targetPosition
            self.footerView.layoutIfNeeded()
            }, completion: { finished in
                self.dummyViewLeadingEdge.constant = targetPosition + 350
                self.leftViewController.onAnimationComplete()
                self.scrollView.viewDidResize()
                self.visualizationHandler.reloadAllViews()

                // should move slider bar code here to be better
        })
    }
    
    // MARK: - Reset UI
    
    func resetViewController() {
        // Use this function to reset the view controller's UI to a clean state
        Log("Resetting \(__FILE__)")
    }
    
//    func changeLastUpdated(callWaitToSearch: Bool, waitingResponse: Bool)
//    {
//        let dateNow = NSDate()
//        let dateFormat = NSDateFormatter()
//        dateFormat.dateFormat = "E, MMM d hh:mm aa"
//        dateFormat.timeZone = NSTimeZone.localTimeZone()
//        if waitingResponse
//        {
//             self.tweetsFooterLabel.text = "Loading ..."
//        }
//        else
//        {
//           self.tweetsFooterLabel.text = "Last updated: " + dateFormat.stringFromDate(dateNow)
//        }
//    }
//    
//    func waitToUpdateSearch()
//    {
//        // 5min until new update be available
//        let delay = 300.0 * Double(NSEC_PER_SEC)
//        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
//        dispatch_after(time, dispatch_get_main_queue()) {
//            self.canUpdateSearch = true
//            UIView.animateWithDuration(2, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: UIViewAnimationOptions.TransitionFlipFromBottom, animations: {
//                self.tweetsFooterLabel.text = "Refresh Available"
//                self.tweetsFooterView.backgroundColor = Config.mediumGreen
//                self.tweetsFooterSeparatorLine.hidden = true
//                self.view.layoutIfNeeded()
//                }, completion: nil)
//        }
//    }
    
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
        TODO: Change name from setupWebViews to something else like setupVisualizations
        creates the webviews
    */
    func setupWebViews()
    {
        for i in 0..<Config.getNumberOfVisualizations(){
            let tempVisPath = NSURL(fileURLWithPath: Config.visualisationFolderPath).URLByAppendingPathComponent(NSURL(fileURLWithPath: Config.visualizationNames[i]).URLByAppendingPathExtension("html").path!)
            let request = NSURLRequest(URL: tempVisPath)
            
            let myOrigin = CGFloat(i) * self.scrollView.frame.size.width
            
            if i == Config.visualizationsIndex.timemap.rawValue // this visualization is native iOS, not a webview
            {
                var mapTopPadding = 0.0
                if(CenterViewController.leftViewOpen){
                    mapTopPadding = Config.smallscreenMapTopPadding
                }
                else{
                    mapTopPadding = Config.fullscreenMapTopPadding
                }
                
                visualizationHandler.scrollViewWidth = self.scrollView.frame.size.width
                visualizationHandler.scrollViewHeight = self.scrollView.frame.size.height

                let mySuperView : TimeMapView = TimeMapView(frame: CGRectMake(myOrigin, CGFloat(mapTopPadding), self.scrollView.frame.size.width, self.scrollView.frame.size.height))
                
                let myMapView : UIImageView
                let image = UIImage(named: "bluewebmercatorprojection_whitebg.png")
                
                myMapView = UIImageView(frame: CGRectMake(0, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height))
                myMapView.image = image
                
                visualizationHandler.visualizationViews.append(mySuperView)
                self.scrollView.addVisualisation(mySuperView)
                
                // THE MAP
                mySuperView.addSubview(myMapView)
                mySuperView.baseMapView = myMapView
            }
            else //this visualization is one of the webviews
            {
            
                var myWebView : WKWebView

                visualizationHandler.scrollViewWidth = self.scrollView.frame.size.width
                visualizationHandler.scrollViewHeight = self.scrollView.frame.size.height
                
                myWebView = WKWebView(frame: CGRectMake(myOrigin, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height))
                
                //myWebView.scalesPageToFit = Config.scalePagesToFit[i] //TODO: stackoverflow this, there is a long solution
                myWebView.navigationDelegate = self
                
                // don't let webviews scroll
                myWebView.scrollView.scrollEnabled = false;
                myWebView.scrollView.bounces = false;
                
                visualizationHandler.visualizationViews.append(myWebView)
                self.scrollView.addVisualisation(myWebView)
                // set initial loading state
                myWebView.hidden = true
                
                if i == Config.visualizationsIndex.stackedbar.rawValue
                {
                    createSliderForBarChart(myOrigin)
                }
                
                myWebView.loadRequest(request)
            }
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
        let leftLabel = createUILabelRange(CGFloat(origin + 80), align: NSTextAlignment.Left)
        let rightLabel = createUILabelRange(CGFloat(origin + (self.scrollView.frame.width - 160)), align: NSTextAlignment.Right)
        
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
    
    func repositionSliderForBarChart(newOrigin: CGFloat, widthShrinkFactor: CGFloat)
    {
        visualizationHandler.rangeSliderBarChart.frame = CGRect(x: newOrigin + 80, y: self.scrollView.frame.height - 55,
            width: self.scrollView.frame.width - 160 - widthShrinkFactor, height: 18.0)
        
        for label in visualizationHandler.rangeLabels
        {
            label.hidden = true
            if(label.textAlignment == NSTextAlignment.Left){
                label.frame = CGRectMake(newOrigin + 80, self.scrollView.frame.height - 36, 80, 18);
            }
            else if(label.textAlignment == NSTextAlignment.Right){
                label.frame = CGRectMake(newOrigin + (self.scrollView.frame.width - 160 - widthShrinkFactor), self.scrollView.frame.height - 36, 80, 18);
            }
            label.hidden = false
        }
        
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
        
        let maxDate = Double(visualizationHandler.stackedbarData.count) - 1
        
        //Transform range from 0-1 to 0-count
        let lowerIndex: Int = Int(round(maxDate * rangeSlider.lowerValue))
        let upperIndex: Int = Int(round(rangeSlider.upperValue * maxDate))
        
        self.visualizationHandler.redrawStackedBarWithNewRange(lowerIndex, upperIndex: upperIndex)
    }
    
    /*
        sets up the scrollview that contains the webviews
    */
    func setupScrollView() {
        for i in 0..<Config.getNumberOfVisualizations() {
            let myOrigin = CGFloat(i) * self.scrollView.frame.size.width
            self.scrollView.delegate = self
            
            // scroll view center
            var center = self.scrollView.center
            center.x = myOrigin + center.x
            
            //Loading view
            let activityIndicator = createActivityIndicatorView(myOrigin, center: center)
            self.scrollView.addSubview(activityIndicator)
            visualizationHandler.loadingViews.append(activityIndicator)
            
            //Results Label
            let label = createUILabelForError(myOrigin, center: center)
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
        let pageWidth = scrollView.frame.size.width
        let fractionalPage = Float(scrollView.contentOffset.x / pageWidth)
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
            if let myWebView = visualizationHandler.visualizationViews[previousPage] as? WKWebView {
                let webViewScrollView = myWebView.scrollView
                webViewScrollView.zoomScale = webViewScrollView.minimumZoomScale
            }
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        visualizationHandler.transformData(webView)
    }
    
    
    
    // MARK: - PageControlDelegate
    
    func pageChanged(index: Int) {
        //Log("Page Changed to index: \(index)")
        let offset = scrollView.frame.size.width * CGFloat(index)
        scrollView.setContentOffset(CGPointMake(offset, 0), animated: true)
    }
    
    @IBAction func searchClicked(sender: UIButton) {
        delegate?.toggleRightPanel?(false)
    }
    
    // MARK - Actions
    
    @IBAction func shareButtonClicked(sender: UIButton) {
        
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
        mailComposerVC.addAttachmentData(UIImageJPEGRepresentation(getScreenShot(), 1)!, mimeType: "image/jpeg", fileName: "IBMSparkInsightsScreenShot.jpeg")
        return mailComposerVC
    }
    
    func getScreenShot() -> UIImage
    {
        let layer = UIApplication.sharedApplication().keyWindow!.layer
        let scale = UIScreen.mainScreen().scale
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale);
        
        layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        UIImageWriteToSavedPhotosAlbum(screenshot, nil, nil, nil)
        
        return screenshot
    }
    
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertView(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", delegate: self, cancelButtonTitle: "OK")
        sendMailErrorAlert.show()
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func headerTitleClicked(sender: AnyObject) {
        delegate?.toggleRightPanel!(true)
        delegate?.displaySearchViewController?()
    }
    
    func cleanViews()
    {
        if leftViewController != nil && leftViewController.tweetsTableViewController != nil
        {
            leftViewController.tweetsTableViewController.emptySearchResult = false
            leftViewController.tweetsTableViewController.errorMessage = nil
            leftViewController.tweetsTableViewController.tweets = []
            leftViewController.tweetsTableViewController.tableView.reloadData()
        }
        
        if leftViewController != nil
        {
            if leftViewController.searchedTweetsNumberLabel != nil
            {
                leftViewController.searchedTweetsNumberLabel.text = ""
            }
            if leftViewController.foundUsersNumberLabel != nil
            {
                leftViewController.foundUsersNumberLabel.text = ""
            }
            if leftViewController.foundTweetsNumberLabel != nil
            {
                leftViewController.foundTweetsNumberLabel.text = ""
            }
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
            let term = terms[i]
            if term != ""
            {
                var aux = Array(term.characters)
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
        
        var vector = Array(includeStr.characters)
        if vector.count > 0
        {
            vector.removeLast()
        }
        includeStr = String(vector)
        vector = Array(excludeStr.characters)
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
            let search = self.getIncludeAndExcludeSeparated()
            let networkConnection = Network()
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
        
    }
    
    func handleTweetsCallBack(json: JSON?, error: NSError?) {
        if ((error) != nil) {
            leftViewController.tweetsTableViewController.errorMessage = error!.localizedDescription
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
                    leftViewController.tweetsTableViewController.emptySearchResult = true
                }
                leftViewController.tweetsTableViewController.tweets = tweetsContent["tweets"]
            }
            else
            {
                leftViewController.tweetsTableViewController.errorMessage = Config.serverErrorMessage
            }
        }
        else
        {
            leftViewController.tweetsTableViewController.errorMessage = Config.serverErrorMessage
        }
        leftViewController.tweetsTableViewController.tableView.reloadData()
    }
    
    func handleLocationCallBack(json: JSON?, error: NSError?) {
        // Log("handleLocationCallBack")
        
        if (error != nil) {
            visualizationHandler.errorDescription[Config.visualizationsIndex.timemap.rawValue] = "\(error!.localizedDescription)"
            visualizationHandler.errorState(Config.visualizationsIndex.timemap.rawValue, error: "\(error!.localizedDescription)")
            return
        }
        let numberOfColumns = 3        // number of columns
        let containerName = "location" // name of container for data //TODO: unknown
        
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
                    let data = self.returnArrayOfData(numberOfColumns, containerName: containerName, json: contentJson!, chartIndex: Config.visualizationsIndex.timemap.rawValue)
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
        let numberOfColumns = 4        // number of columns
        let containerName = "sentiment" // name of container for data //TODO: unknown
        
        
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
                    let data = self.returnArrayOfData(numberOfColumns, containerName: containerName, json: contentJson!, chartIndex: Config.visualizationsIndex.stackedbar.rawValue)
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
        let numberOfColumns = 3        // number of columns
        let containerName = "distance" // name of container for data
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let data = self.returnArrayOfData(numberOfColumns, containerName: containerName, json: json!, chartIndex: Config.visualizationsIndex.forcegraph.rawValue)
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
        
        let numberOfColumns = 4        // number of columns
        let containerName = "cluster" // name of container for data
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let data = self.returnArrayOfData(numberOfColumns, containerName: containerName, json: json!, chartIndex: Config.visualizationsIndex.circlepacking.rawValue)
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
            
                //visualizationHandler.treemapData = contentJson!["profession"].description

                visualizationHandler.treemapData = contentJson!.description
                
                //Log("What did we get back?")
                //println(visualizationHandler.treemapData)
                //Log("Was it anything?")
                
                visualizationHandler.isloadingVisualization[Config.visualizationsIndex.treemap.rawValue] = false
                visualizationHandler.reloadAppropriateView(Config.visualizationsIndex.treemap.rawValue)

                /*
                Log("if contentJson != nil")
                
                if let professions = contentJson!["profession"].dictionaryObject as? Dictionary<String,Dictionary<String,Int>>
                {
                    
                    Log("not conversion error")
                    //Log(professions)
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
                */

            /*
            else
            {
                visualizationHandler.errorDescription[Config.visualizationsIndex.treemap.rawValue] = Config.serverErrorMessage
                visualizationHandler.errorState(Config.visualizationsIndex.treemap.rawValue, error: Config.serverErrorMessage)
            }*/
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
        let numberOfColumns = 3        // number of columns
        let containerName = "topic" // name of container for data
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let data = self.returnArrayOfData(numberOfColumns, containerName: containerName, json: json!, chartIndex: Config.visualizationsIndex.wordcloud.rawValue)
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
            leftViewController.searchedTweetsNumberLabel.text = "Error"
            leftViewController.foundTweetsNumberLabel.text = "Error"
            leftViewController.foundUsersNumberLabel.text = "Error"
            return
        }
        else
        {
            if json!["totalusers"] != nil
            {
                leftViewController.foundUsersNumberLabel.text = self.formatNumberToDisplay(Int64(json!["totalusers"].intValue))
            }
            else
            {
                leftViewController.foundUsersNumberLabel.text = "Error"
            }
            if json!["totaltweets"] != nil
            {
                leftViewController.searchedTweetsNumberLabel.text = self.formatNumberToDisplay(Int64(json!["totaltweets"].intValue))
            }
            else
            {
                leftViewController.searchedTweetsNumberLabel.text = "Error"
            }
            if json!["totalfilteredtweets"] != nil
            {
                leftViewController.foundTweetsNumberLabel.text = self.formatNumberToDisplay(Int64(json!["totalfilteredtweets"].intValue))
            }
            else
            {
                leftViewController.foundTweetsNumberLabel.text = "Error"
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
        for (row, rowJson): (String, JSON) in json[containerName] {
            for (col, cellJson): (String, JSON) in rowJson {
                //println(row, col, cellJson)
                let r: Int = Int(row)!
                let c: Int = Int(col)!
                //self.tableData[r][c] = cellJson.stringValue
                //Log(cellJson.stringValue)
                
                tableData[r][c] = cellJson.stringValue.stringByReplacingOccurrencesOfString("\"", withString: "").stringByReplacingOccurrencesOfString("'", withString: "").stringByReplacingOccurrencesOfString("\n", withString: "") //remove quotes
            }
        }
        return tableData
    }
    
    //MARK: Dummy Data
    
    func onDummyRequestSuccess(json: JSON) {
        Log(__FUNCTION__)
        
        if (Config.serverMakeSingleRequest) {
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                
                let filePath = NSBundle.mainBundle().pathForResource("response_spark", ofType:"json")
                
                var readError:NSError?
                do {
                    let fileData = try NSData(contentsOfFile:filePath!,
                        options: NSDataReadingOptions.DataReadingUncached)
                    // Read success
                    var parseError: NSError?
                    do {
                        let JSONObject: AnyObject? = try NSJSONSerialization.JSONObjectWithData(fileData, options: NSJSONReadingOptions.AllowFragments)
                        // Parse success
                        let json = JSON(JSONObject!)
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.populateUI(json)
                        })
                    } catch let error as NSError {
                        parseError = error
                        // Parse error
                        // TODO: handle error
                        Log("Error Parsing demo data: \(parseError?.localizedDescription)")
                    }
                } catch let error as NSError {
                    readError = error
                    // Read error
                    // TODO: handle error
                    Log("Error Reading demo data: \(readError?.localizedDescription)")
                } catch {
                    fatalError()
                }
                
            })
            
        } else {
            populateUI(json)
        }
    }
    
    func populateUI(json: JSON){ //THIS IS ONLY USED FOR DUMMY DATA NOW
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

