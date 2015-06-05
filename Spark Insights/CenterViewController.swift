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

class CenterViewController: UIViewController, UIWebViewDelegate, UIScrollViewDelegate, PageControlDelegate, MFMailComposeViewControllerDelegate {

    var searchText: String? {
        didSet {
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
    
    @IBOutlet weak var tweetsPerHourNumberLabel: UILabel!
    @IBOutlet weak var totalRetweetsNumberLabel: UILabel!
    @IBOutlet weak var totalTweetsNumberLabel: UILabel!
    @IBOutlet weak var pageControlViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var dummyView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var leftView: UIView!
    @IBOutlet weak var headerView: UIView!
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.setupTweetsTableView()
        self.setupWebViews()
        self.setupScrollView()
        self.setupMetricsNumber()

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
        println("Resetting \(__FILE__)")
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
                self.changeLastUpdated()
            }
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
    
    func setupMetricsNumber()
    {
        let metrics = self.getMetricsNumber()
        self.totalTweetsNumberLabel.text = self.formatNumberToDisplay(metrics.totalTweets)
        self.totalRetweetsNumberLabel.text = self.formatNumberToDisplay(metrics.totalRetweets)
        self.tweetsPerHourNumberLabel.text = self.formatNumberToDisplay(metrics.tweetsPerHour)
    }

    func getMetricsNumber() -> (totalTweets: Int64, totalRetweets: Int64, tweetsPerHour: Int64)
    {
        //get metric values
        // strtoll - String to long long int
        var tweets = strtoll("99780009800", nil,10)
        var retweets = strtoll("547800", nil,10)
        var tweetsHour = strtoll("6778000", nil,10)
        
        return (tweets, retweets, tweetsHour)
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

            
            myWebView = UIWebView(frame: CGRectMake(myOrigin, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height))
            
            //myWebView.backgroundColor = colors[i % Config.getNumberOfVisualizations()]
            
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
        for i in 0..<Config.getNumberOfVisualizations() {
            let myWebView = visualizationHandler.webViews[i]
            self.scrollView.addSubview(myWebView)
            self.scrollView.delegate = self
        }
        
        self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * CGFloat(Config.getNumberOfVisualizations()), self.scrollView.frame.size.height)
    }
    
    // MARK: - UIScrollViewDelegate
    
    //detect when the page was changed
    func scrollViewDidScroll(scrollView: UIScrollView) {
        var pageWidth = scrollView.frame.size.width
        var fractionalPage = Float(scrollView.contentOffset.x / pageWidth)
        var page : Int = Int(round(fractionalPage))
        if(page >= Config.getNumberOfVisualizations()){
            //println("page is greater than the number of visualizations (\(Config.getNumberOfVisualizations())) : \(page)")
            page = Config.getNumberOfVisualizations()-1
        }
        if(previousPage != page){
            //println("page was changed to... \(page)")
            previousPage = page
            visualizationHandler.reloadAppropriateView(page)
            if((page+1)<Config.getNumberOfVisualizations()){ //preload the next view to avoid "pop"
                visualizationHandler.reloadAppropriateView(page+1)
            }
            // we might also want to load the page before this page
            pageControlView.selectedIndex = page
        }
    }
    
    // MARK: - UIWebViewDelegate
    
    /*
        When a page finishes loading, load in the javascript
    */
    func webViewDidFinishLoad(webView: UIWebView) {
        //get the data in there somehow
        //println("I finished my load..." + webView.request!.URL!.lastPathComponent!)
        visualizationHandler.transformData(webView)
    }
    
    // MARK: - PageControlDelegate
    
    
    // this doesn't get called?
    func pageChanged(index: Int) {
        println("Page Changed to index: \(index)")
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
        mailComposerVC.setSubject("IBM Spark Insights")
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
            loadingView1 = LoadingView(frame: view.frame)
            view.addSubview(loadingView1!)
            
            let delay = Config.dummyDataDelay * Double(NSEC_PER_SEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            dispatch_after(time, dispatch_get_main_queue()) {
                self.onDummyRequestSuccess(nil)
                self.loadingView1.removeFromSuperview()
            }
        } else {
            var search = self.getIncludeAndExcludeSeparated()
            self.executeTweetRequest(search.include, exclude: search.exclude)
        }

    }
    
    func executeTweetRequest(include: String, exclude: String)
    {
        var parameters = Dictionary<String,String>()
        parameters["user"] = "ssdemo"
        parameters["termsInclude"] = include
        parameters["termsExclude"] = exclude
        parameters["top"] = "100"
        let req = self.createRequest(Config.serverTweetsPath, paremeters: parameters)
        executeRequest(req, callBack: self.populateTweetsTable)
    }
    
    func createRequest(serverPath: String, paremeters: Dictionary<String,String>) -> String{
        println("createRequest")
        
        var urlPath:String = "\(Config.serverAddress)/\(serverPath)"
        if paremeters.count > 0
        {
            urlPath += "?"
            let keys = paremeters.keys
            for key in keys
            {
                urlPath += key + "=" + paremeters[key]! + "&"
            }
            var aux = Array(urlPath)
            aux.removeLast()
            urlPath = String(aux)
        }
        return urlPath
    }
    
    func executeRequest(req: String, callBack: (json: JSON) -> ()) {
        //let urlPath :String = "\(Config.serverAddress)/\(req)"
        
        //var escapedAddress = req.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        
        println("Sending Request: " + req)
        let url: NSURL = NSURL(string: req)!
        let session = NSURLSession.sharedSession()
        session.configuration.timeoutIntervalForRequest = 300
        
        loadingView1 = LoadingView(frame: view.frame)
        view.addSubview(loadingView1!)
        
        let task = session.dataTaskWithURL(url, completionHandler: {data, response, error -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                self.loadingView1.removeFromSuperview()
            })
            
            if error != nil {
                // If there is an error in the web request, print it to the console
                // TODO: handle request error
                println(error.localizedDescription)
                return
            }
            
            //println(NSString(data: data, encoding: NSUTF8StringEncoding))
            
            var err: NSError?
            var jsonResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err) as! NSDictionary
            if err != nil {
                // If there is an error parsing JSON, print it to the console
                // TODO: handle parsing error
                println("JSON Error \(err!.localizedDescription)")
                return
            }
            
            let json = JSON(jsonResult)
            let status = json["status"].intValue
            
            if( status == 1 ) {
                let msg = json["message"].stringValue
                // TODO: handle error message
                println("Error: " + msg)
                return
            }
            
            // Success
            println("Request completed: Status = OK")
            
            dispatch_async(dispatch_get_main_queue(), {
                // Success on main thread
                callBack(json: json)
            })
        })
        task.resume()
    }
    
    func onRequestSuccess(json: JSON) {
        println(__FUNCTION__)
        // Populate UI
        self.tweetsTableViewController.tweets = ReadTweetsData.getTweetsObjects(json["tweets"])!
        self.tweetsTableViewController.tableView.reloadData()
        //populateUI(json)
    }
    
    func onDummyRequestSuccess(json: JSON) {
        println(__FUNCTION__)
        populateUI(json)
    }
    
    func populateUI(json: JSON){
        populateCharts(json)
        populateTweetsTable(json)
    }
    
    func populateTweetsTable(json: JSON)
    {
        // Simulating request delay
        /*let delay = 1.0 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {*/
            self.tweetsTableViewController.tweets = ReadTweetsData.readJSON()!
            self.tweetsTableViewController.tableView.reloadData()
        //}
        //-----
    }
    
    func populateCharts(json : JSON){
        //something like this maybe
        visualizationHandler.circlepackingData = [["1","ecstatic","222"],["1","glad","344"],["2","bummed","111"],["3","drunk","577"],["3","trashed","99"],["4","lovesick","233"],["4","crushing","333"],["4","cloud9","288"],["4","turned-on","555"],["1","happy","444"],["3","wasted","55"]]
        visualizationHandler.reorderCirclepackingData()
        
        visualizationHandler.treemapData = [["ecstatic","222"],["glad","344"],["bummed","111"],["drunk","577"],["trashed","99"],["lovesick","233"],["crushing","333"],["cloud9","288"],["turned-on","555"],["happy","444"],["wasted","55"]]
        
        visualizationHandler.stackedbarData = [["11/17","43","33"],["11/18","22", "22"],["11/19","22", "22"],["11/20","22", "22"],["11/21","22", "22"],["11/22","22", "22"],["11/23","22", "22"]]
        
        visualizationHandler.worddistanceData = [ [ "#datamining", "0.66010167854665769", "457" ], [ "#analytics", "0.66111733184244015", "8904" ], [ "#rstats", "0.69084306092036141", "361" ], [ "@hortonworks", "0.66914077012093209", "166" ], [ "#neo4j", "0.69127034015170996", "63" ], [ "#datascience", "0.67888717822606814", "4202" ], [ "#azure", "0.66226415367181413", "667" ], [ "@mapr", "0.66354464393456225", "165" ], [ "#deeplearning", "0.66175874534547685", "396" ], [ "#machinelearning", "0.6964340180591716", "2260" ], [ "#nosql", "0.75678772608504818", "877" ], [ "#sas", "0.70367785412709649", "145" ], [ "#mongodb", "0.6993281653000063", "225" ], [ "#hbase", "0.78010979167439309", "138" ], [ "#python", "0.69931247945181596", "2821" ], [ "#mapreduce", "0.72372695100578921", "62" ], [ "#apache", "0.75935793530857787", "244" ], [ "#cassandra", "0.76777460490727012", "128" ], [ "#hadoop", "0.82618702428574087", "1831" ], [ "#r", "0.76732526060916861", "277" ] ]
        
        visualizationHandler.timemapData =
            [ [  "20-Apr", "United States", "754" ], [ "20-Apr", "United Kingdom", "347" ], [ "21-Apr", "United States", "1687" ], ["21-Apr", "United Kingdom", "555"], [ "22-Apr", "United States", "2222" ], ["22-Apr", "United Kingdom", "155"], [ "23-Apr", "United States", "4343" ], ["23-Apr", "United Kingdom", "1214"], [ "24-Apr", "United States", "9999" ], ["24-Apr", "United Kingdom", "3333"], [ "25-Apr", "United States", "1687" ], ["25-Apr", "United Kingdom", "555"], [ "26-Apr", "United States", "1687" ], ["26-Apr", "United Kingdom", "555"] ]
        
        visualizationHandler.reloadAppropriateView(previousPage) //reload the current page
        // other pages will get loaded when they are swiped to
    }
}

