//
//  VisWebView.swift
//  RedRock
//
//  Created by Jonathan Alter on 10/12/15.
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
import WebKit

// make VisWebViewController handle callbacks
class VisWebViewController: VisMasterViewController, VisLifeCycleProtocol, WKNavigationDelegate, WKScriptMessageHandler {
    
    var mainFile: String {
        switch type! {
        case .TreeMap:
            return "treemap.html"
        case .CirclePacking:
            return "circlepacking.html"
        case .StackedBar:
            return "stackedbar.html"
        case .ForceGraph:
            return "forcegraph.html"
        case .StackedBarDrilldownCirclePacking:
            return "StackedBarDrilldownCirclepacking.html"
        case .SidewaysBar:
            return "sidewaysbar.html"
        default:
            return "none"
        }
    }
    
    var dateRange: Array<String> = Array<String>()
    var startDate: NSDate = NSDate()
    var endDate: NSDate = NSDate()
    var highestValue : Double = 0.0
    
    var webView: WKWebView! = nil
    
    var myDrilldown: VisMasterViewController! = nil
    
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if(message.name == "callbackHandler") {
            Log("JavaScript is sending a message \(message.body)")
            
            let rawData = (message.body as! String)
            
            displayVisOverSentiment(transformDataForDisplayVisOverSentiment(rawData), sentimentIsPositiveMa: isSentimentPositive(rawData));
        } else if (message.name == "console") {
            // Use the following method to print console logs from the WKWebView
            // window.webkit.messageHandlers.console.postMessage({body: "TEST"});
            print("WKWebView Log: \(message.body)")
        }
    }
    
    func isSentimentPositive(rawData: String) -> Bool{
        
        if rawData.containsString("Positive"){
            Log("positive sentiment detected")
            return true
        }
        else if rawData.containsString("Negative"){
            Log("Negative sentiment detected")
            return false
        }
        else{
            Log("ERROR: unsure what kind of sentiment this is in transformDataForDisplayVisOverSentiment in VisWebViewController.swift")
            return false
        }
    }
    
    // TODO THIS IS USING MAX DATE RANGES INSTEAD OF CURRENT DATE RANGES
    func transformDataForDisplayVisOverSentiment(rawData: String) -> NSDate{
        
        
        //TODO if Steve wants the "inaccurate click with flowy chart" back then we need to revert back into the code approximated the datetime based on the click coordinate
        
        //var coordinates = '<h3>' + key + '</h3>' +'<p>' + y + '</p>' ;
        
        Log("transformDataForDisplayVisOverSentiment")
        Log(rawData)
        
        //rawData.substringFromIndex(advance(rawData.rangeofString("<p>")))
        
        //remove <h3>Positive Sentiment</h3><p>
        // then remove </p>
        
        let nsstringDate :NSString = rawData
        
        var dateFromChart = nsstringDate.substringFromIndex(30) //isolate the date
        dateFromChart = String(dateFromChart.characters.dropLast(4)) //isolate the date
        
        //Log("dateFromChart \(dateFromChart)")
        
        let dateFormat = NSDateFormatter()
        dateFormat.dateFormat = Config.dateFormat
        dateFormat.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        
        let myDate = dateFormat.dateFromString(dateFromChart)!
        
        //Log("myDate: \(myDate)")
        
        return myDate
        
    }
    
    func displayVisOverSentiment(selectedDate: NSDate, sentimentIsPositiveMa: Bool) {
        let visHolder = UIStoryboard.visHolderViewController()!
        self.addVisHolderController(visHolder)
        
        myDrilldown = VisFactory.visualizationControllerForType(.StackedBarDrilldownCirclePacking)!
        visHolder.addVisualisationController(myDrilldown)
        myDrilldown.onLoadingState()
        
        let dateFormat = NSDateFormatter()
        
        dateFormat.dateFormat = "yyyy-MM-dd'T'HH"
        
        dateFormat.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        
        let selectedDateAsString = dateFormat.stringFromDate(selectedDate)
        
        let selectedDateAsStringWithZero = "\(selectedDateAsString):00:00.000Z"
        
        //TODO this is hardcoded to be one hour!! we should change it to be modular
        let timeInterval = NSTimeInterval((Config.dateRangeIntervalForStackedbarDrilldownInSeconds))
        
        let endDateAsString = dateFormat.stringFromDate(selectedDate.dateByAddingTimeInterval(timeInterval))
        
        let endDateAsStringWithZero = "\(endDateAsString):00:00.000Z"
        
        if(sentimentIsPositiveMa){
            Network.sharedInstance.sentimentAnalysisRequest(self.searchText, sentiment: .Positive, startDatetime: selectedDateAsStringWithZero, endDatetime: endDateAsStringWithZero) { (json, error) -> () in
                if error != nil {
                    return
                }
                self.myDrilldown.json = json
            }
        }
        else{
            Network.sharedInstance.sentimentAnalysisRequest(self.searchText, sentiment: .Negative, startDatetime: selectedDateAsStringWithZero, endDatetime: endDateAsStringWithZero) { (json, error) -> () in
                if error != nil {
                    return
                }
                self.myDrilldown.json = json
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView = createWKWebViewWithConfigurationForCallback()
        visHolderView.addSubview(webView)
    }
    
    func createWKWebViewWithConfigurationForCallback() -> WKWebView{
        let contentController = WKUserContentController();
        
        // THIS IS ANOTHER WAY TO PASS IN JAVASCRIPT
        //let userScript = WKUserScript(
        //    source: "redHeader()", //the name of our function
        //    injectionTime: WKUserScriptInjectionTime.AtDocumentEnd,
        //    forMainFrameOnly: true
        //)
        //contentController.addUserScript(userScript)
        
        contentController.addScriptMessageHandler(self, name: "callbackHandler") //THIS IS THE WAY WE WILL GET MESSAGES BACK FOR OURSELVES
        contentController.addScriptMessageHandler(self, name: "console")
        
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        
        let myWebView = WKWebView(frame: self.view.bounds, configuration: config)
        
        //WKWebView()
        myWebView.frame = self.view.bounds
        myWebView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        //myWebView.scalesPageToFit = Config.scalePagesToFit[i] //TODO: stackoverflow this, there is a long solution
        myWebView.navigationDelegate = self
        
        // don't let webviews scroll
        myWebView.scrollView.scrollEnabled = false;
        myWebView.scrollView.bounces = false;
        
        return myWebView
    }
    
    override func onDataSet() {
        Log("onDataSet... mainFile... \(mainFile)")
        let tempVisPath = NSURL(fileURLWithPath: Config.visualizationFolderPath).URLByAppendingPathComponent(NSURL(fileURLWithPath: self.mainFile).path!)
        let request = NSURLRequest(URL: tempVisPath)
        webView.loadRequest(request)
        
        switch type! {
        case .StackedBar :
            if let drilldown = myDrilldown{  //TODO reload my child
                drilldown.onDataSet()
            }
        default:
            break
        }
        
    }
    
    override func onFocus() {
        switch type! {
        case .ForceGraph :
            webView.evaluateJavaScript("stopAnimation();", completionHandler: nil)
        default:
            break
        }
    }
    
    override func onBlur() {
        let webViewScrollView = webView.scrollView
        webViewScrollView.zoomScale = webViewScrollView.minimumZoomScale
        
        switch type! {
        case .ForceGraph :
            webView.evaluateJavaScript("startAnimation();", completionHandler: nil)
        default:
            break
        }
    }
    
    override func onSuccessState() {
        let webViewScrollView = webView.scrollView
        webViewScrollView.zoomScale = webViewScrollView.minimumZoomScale
        
        super.onSuccessState()
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        transformData()
    }
    
    override func transformData() {
        let delay = 0.2 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            
            guard self.json != nil else {
                self.errorDescription = (self.errorDescription != nil) ? self.errorDescription : Config.serverErrorMessage
                return
            }
            
            switch self.type! {
            case .TreeMap:
                self.transformDataForTreemapping()
            case .CirclePacking:
                self.transformDataForCirclepacking()
            case .ForceGraph:
                self.transformDataForForcegraph()
            case .StackedBar:
                self.transformDataForStackedbar()
            case .SidewaysBar:
                self.transformDataForSidewaysbar()
            case .StackedBarDrilldownCirclePacking:
                self.transformDataForStackedBarDrilldownCirclepackingInTheVisualizationPanelOfTheRedRockAppThatWeAreMakingForSteve()
            default:
                return
            }
        }
    }
    
    func transformDataForTreemapping(){
        onLoadingState()
        
        let viewSize = self.view.bounds.size
        
        let treemapData = json!["profession"].description
        var treemapDataTrimmed : String
        
        if let rangeOfStart = treemapData.rangeOfString("\"profession\" : ["){
            treemapDataTrimmed = "{\"name\": \"Profession\",\"children\": ["+treemapData.substringFromIndex(rangeOfStart.endIndex)
            
            treemapDataTrimmed = treemapDataTrimmed.stringByReplacingOccurrencesOfString("\n", withString: "")
            
            let script9 = "var data7 = '\(treemapDataTrimmed)'; var w = \(viewSize.width); var h = \(viewSize.height); renderChart(data7, w, h);";
            
            webView.evaluateJavaScript(script9, completionHandler: nil)
            
            onSuccessState()
        } else {
            errorDescription = Config.noDataMessage
        }
    }
    
    func transformDataForCirclepacking(){
        //Log(circlepackingData)
        onLoadingState()
        
        func loadData() {
            if self.chartData.count > 0
            {
                // Reorder Circle Packing Data
                self.chartData.sortInPlace({$0[2] < $1[2]})
                
                let viewSize = self.view.bounds.size
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    var script9 = "var data7 = '{\"name\": \" \",\"children\": ["
                    
                    var groupName : String = "uninitialized" // this isn't safe, there should be a better way
                    
                    for r in 0..<self.chartData.count{
                        if(groupName != self.chartData[r][2]){
                            // stop the group (unless it's the first one)
                            if(groupName != "uninitialized"){
                                script9+="]},"
                            }
                            // new group
                            groupName = self.chartData[r][2]
                            script9+="{\"name\": \""
                            script9+=groupName
                            script9+="\", \"children\": ["
                        }
                        else{
                            //continue the group
                            script9+=","
                        }
                        
                        script9+="{\"name\": \""
                        script9+=self.chartData[r][0]
                        script9+="\", \"size\":"
                        script9+=self.chartData[r][3]
                        script9+="}"
                    }
                    script9+="]}]}';var w = \(viewSize.width); var h = \(viewSize.height);  renderChart(data7, w, h);"
                    
                    //Log(script9)
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.webView.evaluateJavaScript(script9, completionHandler: nil)
                        
                        self.onSuccessState()
                    })
                })
                
            }
            else {
                onNoDataState()
            }
        }
        
        let numberOfColumns = 4        // number of columns
        let containerName = "cluster" // name of container for data
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let data = self.returnArrayOfData(numberOfColumns, containerName: containerName, json: self.json!)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if(data != nil){
                    self.chartData = data!
                    loadData()
                }
                else{
                    self.errorDescription = Config.serverErrorMessage
                }
            })
        })
        
    }
    
    func makeScriptForSidewaysBar(firstIndex: Int, upperIndex: Int?=nil) -> String {
        //Log("makeScriptForSidewaysBar")
        var script9 = "var myData = [{\"key\": \"Tweet Count\", \"values\": ["
        
        //Log("self.chartData")
        //print(self.chartData)
        
        for r in firstIndex..<self.chartData.count{
            
            script9+="{\"x\": \""
            script9+=self.chartData[r][0]
            script9+="\", \"y\":"
            script9+=self.chartData[r][1]
            script9+="}"
            
            // there's another data point so we need the comma
            if(r != (self.chartData.count-1)){
                script9+=","
            }
        }
        script9+="]}]; renderChart(myData);"
        
        return script9
    }
    
    func transformDataForSidewaysbar(){
        
        //[["11/17","43","33"],["11/18","22", "22"],["11/19","22", "22"],["11/20","22", "22"],["11/21","22", "22"],["11/22","22", "22"],["11/23","22", "22"]]
        //Log(stackedbarData)
        
        //Log("transformDataForSidewaysbar")
        
        func loadData() {
            //Log("loadData")
            //onLoadingState()
            
            if self.chartData.count > 0
            {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    
                    let script9 = self.makeScriptForSidewaysBar(0)
                    
                    //Log("...SCRIPT9....")
                    //Log(script9)
                    //Log("....SCRIPT9...")
                    
                    //var script = "var myData = [{\"key\": \"Tweet Count\", \"values\": [  {\"x\":\"11/17\",\"y\":43, \"z\": 33},   {\"x\":\"11/18\",\"y\":22, \"z\": 22},   {\"x\":\"11/19\",\"y\":22, \"z\": 22},   {\"x\":\"11/20\",\"y\":33, \"z\": 11},    {\"x\":\"11/21\",\"y\":333, \"z\": 15},  {\"x\":\"11/22\",\"y\":44, \"z\": 23}, {\"x\":\"11/23\",\"y\":55, \"z\": 44} ] } ]; renderChart(myData);"
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        //Log("dispatch_async(dispatch_get_main_queue(), { () -> Void in")
                        self.webView.evaluateJavaScript(script9, completionHandler: nil)
                        self.onSuccessState()
                        
                    })
                })
            }
            else
            {
                Log("onNoDataState()")
                onNoDataState()
            }
        }
        
        let numberOfColumns = 2        // number of columns
        let containerName = "wordCount" // name of container for data //TODO: unknown
        
        var contentJson = json
        if contentJson != nil
        {
            contentJson = json![containerName]
            
            //print(contentJson)
            
            if contentJson != nil
            {
                //Log("contentJson != nil")
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    //Log("dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)")
                    let data = self.returnArrayOfLiveData(numberOfColumns, containerName: containerName, json: contentJson!)
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        if(data != nil){
                            //Log("data != nil")
                            self.chartData = data!
                            loadData()
                        }
                        else{
                            //Log("data == nil")
                            self.errorDescription = Config.serverErrorMessage
                        }
                    })
                })
            }
            else
            {
                //Log("contentJson == nil?!?!?!???")
                errorDescription = Config.serverErrorMessage
            }
        }
        else
        {
            //Log("else")
            errorDescription = Config.serverErrorMessage
        }
    }
    
    
    
    func transformDataForStackedBarDrilldownCirclepackingInTheVisualizationPanelOfTheRedRockAppThatWeAreMakingForSteve(){
        
        //Log("transformDataForStackedBarDrilldownCirclepackingInTheVisualizationPanelOfTheRedRockAppThatWeAreMakingForSteve")
        
        onLoadingState()
        
        func loadData() {
            if self.chartData.count > 0
            {
                // Reorder Circle Packing Data
                self.chartData.sortInPlace({$0[1] < $1[1]})
                
                let viewSize = self.view.bounds.size
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    var script9 = "var data7 = '{\"name\": \" \",\"children\": ["
                    
                    var groupName : String = "uninitialized" // this isn't safe, there should be a better way
                    
                    for r in 0..<self.chartData.count{
                        if(groupName != self.chartData[r][1]){
                            // stop the group (unless it's the first one)
                            if(groupName != "uninitialized"){
                                script9+="]},"
                            }
                            // new group
                            groupName = self.chartData[r][1]
                            script9+="{\"name\": \""
                            script9+=groupName
                            script9+="\", \"children\": ["
                        }
                        else{
                            //continue the group
                            script9+=","
                        }
                        
                        script9+="{\"name\": \""
                        script9+=self.chartData[r][0]
                        script9+="\", \"size\":"
                        let aString : String = "\(Int(Float(self.chartData[r][2])!*(10000)))"
                        script9+=aString
                        script9+="}"
                    }
                    script9+="]}]}';var w = \(viewSize.width); var h = \(viewSize.height);  renderChart(data7, w, h);"
                    //script9 = "heyRenderThisDataBro();"
                    //Log(script9)
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.webView.evaluateJavaScript(script9, completionHandler: nil)
                        
                        self.onSuccessState()
                    })
                })
                
            }
            else {
                onNoDataState()
            }
        }
        
        let numberOfColumns = 3        // number of columns
        let containerName = "topics" // name of container for data
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let data = self.returnArrayOfData(numberOfColumns, containerName: containerName, json: self.json!)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if(data != nil){
                    self.chartData = data!
                    loadData()
                }
                else{
                    self.errorDescription = Config.serverErrorMessage
                }
            })
        })
        //}
        
    }
    
    func transformDataForStackedbar(){
        
        //[["11/17","43","33"],["11/18","22", "22"],["11/19","22", "22"],["11/20","22", "22"],["11/21","22", "22"],["11/22","22", "22"],["11/23","22", "22"]]
        //Log(stackedbarData)
        
        func loadData() {
            onLoadingState()
            
            if self.chartData.count > 0
            {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    
                    let script9 = self.makeScriptForStackedBar(0)
                    
                    //Log(script9)
                    
                    //var script = "var myData = [{\"key\": \"Tweet Count\", \"values\": [  {\"x\":\"11/17\",\"y\":43, \"z\": 33},   {\"x\":\"11/18\",\"y\":22, \"z\": 22},   {\"x\":\"11/19\",\"y\":22, \"z\": 22},   {\"x\":\"11/20\",\"y\":33, \"z\": 11},    {\"x\":\"11/21\",\"y\":333, \"z\": 15},  {\"x\":\"11/22\",\"y\":44, \"z\": 23}, {\"x\":\"11/23\",\"y\":55, \"z\": 44} ] } ]; renderChart(myData);"
                    
                    //;var w = \(viewSize.width); var h = \(viewSize.height);  renderChart(data7, w, h);
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.webView.evaluateJavaScript(script9, completionHandler: nil)
                        self.onSuccessState()
                        
                    })
                })
            }
            else
            {
                onNoDataState()
            }
        }
        
        let numberOfColumns = 4        // number of columns
        let containerName = "sentiment" // name of container for data //TODO: unknown
        
        var contentJson = json
        if contentJson != nil
        {
            
            contentJson = json![containerName]
            
            if contentJson != nil
            {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    let data = self.returnArrayOfData(numberOfColumns, containerName: containerName, json: contentJson!)
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        if(data != nil){
                            self.chartData = data!
                            loadData()
                        }
                        else{
                            self.errorDescription = Config.serverErrorMessage
                        }
                    })
                })
            }
            else
            {
                errorDescription = Config.serverErrorMessage
            }
        }
        else
        {
            errorDescription = Config.serverErrorMessage
        }
    }
    
    func makeScriptForStackedBar(firstIndex: Int, upperIndex: Int?=nil) -> String {
        var script9 = "var myData = [{\"key\": \"Tweet Count\", \"values\": ["
        let viewSize = self.view.bounds.size
        
        for r in firstIndex..<self.chartData.count{
            if (self.dateRange.indexOf(self.chartData[r][0]) == nil)
            {
                self.dateRange.append(self.chartData[r][0])
            }
            
            
            script9+="{\"x\": \""
            script9+=self.chartData[r][0]
            script9+="\", \"y\":"
            script9+=self.chartData[r][1]
            script9+=", \"z\":"
            script9+=self.chartData[r][2]
            script9+="}"
            
            
            if let unwrappedUpperIndex = upperIndex {
                if(self.chartData[r][0] == dateRange[unwrappedUpperIndex]){
                    
                    //it's the end of the range //get out of here
                    break
                }
            }
            
            // there's another data point so we need the comma
            if(r != (self.chartData.count-1)){
                script9+=","
            }
        }
        
        //;var w = \(viewSize.width); var h = \(viewSize.height);  renderChart(data7, w, h);
        
        script9+="]}]; renderChart(myData, \(viewSize.width), \(viewSize.height));"
        
        return script9
    }
    
    func getPositiveAndNegativeSentimentValuesForGivenDate(givenDate: NSDate) -> (Double, Double) {
        //change it into format for chart.... MM/dd hh
        
        var foundBiggerDate = false
        
        let dateFormat = NSDateFormatter()
        dateFormat.dateFormat = "YYYY MM/dd HH"
        dateFormat.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        
        var posValue = 0.0
        var negValue = 0.0
        
        let dateWeAreLookingFor = dateFormat.stringFromDate(givenDate)
        
        Log("dateWeAreLookingFor \(dateWeAreLookingFor)")
        
        //Log("self.chartData")
        //print(self.chartData)
        
        for r in 0..<self.chartData.count{
            var currentDate = NSDate()
            if(!foundBiggerDate){
                Log("self.chartData[r][0] \(self.chartData[r][0])")
                
                currentDate = dateFormat.dateFromString("2015 \(self.chartData[r][0])")!
            }
            if( !foundBiggerDate && currentDate.compare(givenDate) == .OrderedDescending){ //currentDate is later than givenDate
                // found a greater date, break out
                foundBiggerDate = true
                Log("pos sentiment: \(chartData[r][1])")
                Log("neg sentiment: \(chartData[r][2])")
                posValue = (chartData[r][1] as NSString).doubleValue
                negValue = (chartData[r][2] as NSString).doubleValue
            }
            else if(!foundBiggerDate && currentDate.compare(givenDate) == .OrderedAscending){ //currentDate is earlier than givenDate
                
            }
            else if(!foundBiggerDate){ //dates are the same
                foundBiggerDate = true
                Log("pos sentiment: \(chartData[r][1])")
                Log("neg sentiment: \(chartData[r][2])")
                posValue = (chartData[r][1] as NSString).doubleValue
                negValue = (chartData[r][2] as NSString).doubleValue
            }
        }
        
        return (posValue, negValue)
        
    }
    
    func redrawStackedBarWithNewRange(lowerIndex: Int, upperIndex: Int){
        var firstIndex = 0
        while firstIndex < self.chartData.count && dateRange[lowerIndex] != self.chartData[firstIndex][0] {
            firstIndex++
        }
        
        let script9 = self.makeScriptForStackedBar(firstIndex, upperIndex: upperIndex)
        
        if type == VisTypes.StackedBar {
            webView.evaluateJavaScript(script9, completionHandler: nil)
        }
        
    }
    
    func transformDataForForcegraph(){
        //Log("transformDataForForcegraph... scrollViewWidth: \(scrollViewWidth)... scrollViewHeight: \(scrollViewHeight)")
        
        func loadData() {
            onLoadingState()
            if self.chartData.count > 0
            {
                let viewSize = self.view.bounds.size
                //TODO: should have searchterm should be from actual searchterm
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    
                    
                    
                    var script9 = "var myData = '{\"nodes\": [ {\"name\":\"\(self.searchText)\",\"value\":\(self.chartData[0][2]),\"group\":1}, " //the search text just arbitrarily takes the value of the first data point as its value
                    for r in 0..<self.self.chartData.count{
                        script9+="{\"name\": \""
                        script9+=self.chartData[r][0]
                        script9+="\", \"value\": "
                        script9+=self.chartData[r][2]
                        script9+=", \"group\": 2"
                        script9+="}"
                        if(r != (self.chartData.count-1)){
                            script9+=","
                        }
                    }
                    script9+="], \"links\": ["
                    for r in 0..<self.chartData.count{
                        script9+="{\"source\": 0"
                        script9+=", \"target\": "
                        script9+="\(r+1)"
                        script9+=", \"distance\": "
                        let myInteger = Int((self.chartData[r][1] as NSString).floatValue*10000)
                        script9+="\(myInteger)"
                        script9+="}"
                        if(r != (self.chartData.count-1)){
                            script9+=","
                        }
                    }
                    script9+="]}'; var w = \(viewSize.width); var h = \(viewSize.height); renderChart(myData,w,h);"
                    
                    //Log("DISTANCE SCRIPT9..... \(script9)")
                    
                    //var testscript = "var myData='{\"nodes\":[    {\"name\":\"Myriel\",\"value\":52,\"group\":1},    {\"name\":\"Labarre\",\"value\":5,\"group\":2},    {\"name\":\"Valjean\",\"value\":17,\"group\":2},    {\"name\":\"Mme.deR\",\"value\":55,\"group\":2},    {\"name\":\"Mme.deR\",\"value\":17,\"group\":2},    {\"name\":\"Isabeau\",\"value\":44,\"group\":2},    {\"name\":\"Mme.deR\",\"value\":17,\"group\":2},    {\"name\":\"Isabeau\",\"value\":22,\"group\":2},    {\"name\":\"Isabeau\",\"value\":17,\"group\":2},    {\"name\":\"Gervais\",\"value\":33,\"group\":2}  ],  \"links\":[    {\"source\":0,\"target\":1,\"distance\":33},    {\"source\":0,\"target\":2,\"distance\":22},    {\"source\":0,\"target\":3,\"distance\":22},    {\"source\":0,\"target\":4,\"distance\":11},    {\"source\":0,\"target\":5,\"distance\":22},    {\"source\":0,\"target\":6,\"distance\":22},    {\"source\":0,\"target\":7,\"distance\":43},    {\"source\":0,\"target\":8,\"distance\":22},    {\"source\":0,\"target\":9,\"distance\":22}  ]}'; var w = \(scrollViewWidth); var h = \(scrollViewHeight); renderChart(myData,w,h);";
                    
                    //println("TESTSCRIPT..... \(testscript)")
                    
                    // println(wordScript)
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.webView.evaluateJavaScript(script9, completionHandler: nil)
                        self.onSuccessState()
                    })
                })
                
            }
            else {
                onNoDataState()
            }
            
        }
        
        let numberOfColumns = 3        // number of columns
        let containerName = "distance" // name of container for data
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let data = self.returnArrayOfData(numberOfColumns, containerName: containerName, json: self.json!)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if(data != nil){
                    //Log("forcegraph data wasn't nil")
                    self.chartData = data!
                    loadData()
                }
                else{
                    self.errorDescription = Config.serverErrorMessage
                }
            })
        })
    }
    
}
