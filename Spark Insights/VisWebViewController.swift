//
//  VisWebView.swift
//  RedRock
//
//  Created by Jonathan Alter on 10/12/15.
//  Copyright © 2015 IBM. All rights reserved.
//

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
        default:
            return "none"
        }
    }
    
    var dateRange: Array<String> = Array<String>()
    
    var webView: WKWebView! = nil
    
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if(message.name == "callbackHandler") {
            print("JavaScript is sending a message \(message.body)")
        }
        //userContentController(userContentController: WKUserContentController, didReceiveScriptMessage: <#T##WKScriptMessage#>)
        
        displayVisOverSentiment()
    }
    
    func displayVisOverSentiment() {
        let visHolder = UIStoryboard.visHolderViewController()!
        self.addVisHolderController(visHolder)
        
        let vis = VisFactory.visualisationControllerForType(.CirclePacking)!
        visHolder.addVisualisationController(vis)
        vis.onLoadingState()
        
        // TODO:
        // wire up network call below
        // populate vis when response returns
        
        Network.sharedInstance.sentimentAnalysisRequest(self.searchText, sentiment: .Positive, startDatetime: "2015-08-01T00:00:00Z", endDatetime: "2015-11-10T23:59:59Z") { (json, error) -> () in
            if error != nil {
                vis.errorDescription = error?.localizedDescription
                return
            }
            vis.json = json
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
        let tempVisPath = NSURL(fileURLWithPath: Config.visualisationFolderPath).URLByAppendingPathComponent(NSURL(fileURLWithPath: self.mainFile).path!)
        let request = NSURLRequest(URL: tempVisPath)
        webView.loadRequest(request)
        
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
    
    // MARK: - WKNavigationDelegate
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        transformData()
    }
    
    func transformData() {
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
                default:
                    return
                }
        }
    }
    
    func transformDataForTreemapping(){
        onLoadingState()
        
        
        
        let treemapData = json!["profession"].description
        var treemapDataTrimmed : String
        
        if let rangeOfStart = treemapData.rangeOfString("\"profession\" : ["){
            treemapDataTrimmed = "{\"name\": \"Profession\",\"children\": ["+treemapData.substringFromIndex(rangeOfStart.endIndex)
            
            treemapDataTrimmed = treemapDataTrimmed.stringByReplacingOccurrencesOfString("\n", withString: "")
            
            let script9 = "var data7 = '\(treemapDataTrimmed)'; var w = \(self.view.bounds.width); var h = \(self.view.bounds.height); renderChart(data7, w, h);";
            
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
        script9+="]}]; renderChart(myData);"
        
        
        
        return script9
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
