//
//  VisualizationHandler.swift
//  Spark Insights
//
//  Holds functions related to particular visualizations
//
//  Created by Rosstin Murphy on 5/29/15.
//  Copyright (c) 2015 IBM. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import MapKit

class VisualizationHandler{
    var visualizationViews : [UIView] = [UIView]()
    
    var loadingViews = [UIActivityIndicatorView]()
    var resultsLabels = [UILabel]()
    var isloadingVisualization = [Bool]()
    var errorDescription = [String]()
    var searchText : String = ""
    
    var scrollViewHeight : CGFloat = 0.0 //set in CenterViewController
    var scrollViewWidth : CGFloat = 0.0 //set in CenterViewController
    
    var treemapData : String = ""
    var circlepackingData : [[String]] = [[String]]()
    var worddistanceData : [[String]]  = [[String]]()
    var forcegraphData : [[String]]    = [[String]]()
    var timemapData : [[String]]       = [[String]]()
    var stackedbarData : [[String]]    = [[String]]()
    var wordcloudData : [[String]]     = [[String]]()
    
    var firstLoad = false
    
    var rangeSliderBarChart:RangeSliderUIControl = RangeSliderUIControl()
    var rangeLabels:Array<UILabel> = Array<UILabel>()
    var dateRange: Array<String> = Array<String>()
    
    func reloadAppropriateView(viewNumber: Int){
        
        if let myMapView = visualizationViews[viewNumber] as? MKMapView {
            println("TODO: reload a mapView")
            // TODO: implement
        }
        else if let myWebView = visualizationViews[viewNumber] as? WKWebView {
            if var url = myWebView.URL{
                //Log("if var request = webViews[viewNumber].request! is \(request)")
                
                if(viewNumber >= 0 && viewNumber < Config.getNumberOfVisualizations()){

                    self.loadingState(viewNumber)
                    //webViews[viewNumber].scalesPageToFit = Config.scalePagesToFit[viewNumber]
                    let filePath = Config.visualisationFolderPath.stringByAppendingPathComponent(Config.visualizationNames[viewNumber].stringByAppendingPathExtension("html")!)
                    let request = NSURLRequest(URL: NSURL.fileURLWithPath(filePath)!)
                    myWebView.loadRequest(request)
                }
            }
            else{
                //Log("NOT if var request = webViews[viewNumber].request!")
            }
        }
    }
    
    func transformData(webView: WKWebView){
        // uses the path to determine which function to use
        let delay = 0.2 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
        
            switch webView.URL!.lastPathComponent!{
            case "treemap.html":
                self.transformDataForTreemapping(webView)
                break;
            case "circlepacking.html":
                self.transformDataForCirclepacking(webView)
                break;
            case "forcegraph.html":
                self.transformDataForForcegraph(webView)
                break;
            case "timemap.html":
                self.transformDataForTimemap(webView)
                break;
            case "stackedbar.html":
                self.transformDataForStackedbar(webView)
                break;
            case "wordcloud.html":
                self.transformDataForWordcloud(webView)
            default:
                break;
            }
        
        }
    }
    
    func transformDataForTreemapping(webView: WKWebView){
        self.loadingState(Config.visualizationsIndex.treemap.rawValue)
        
        var treemapDataTrimmed : String
        
        if let rangeOfStart = self.treemapData.rangeOfString("\"profession\" : ["){
            treemapDataTrimmed = "{\"name\": \"Profession\",\"children\": ["+self.treemapData.substringFromIndex(rangeOfStart.endIndex)
            
            treemapDataTrimmed = treemapDataTrimmed.stringByReplacingOccurrencesOfString("\n", withString: "")
            
            var script9 = "var data7 = '\(treemapDataTrimmed)'; var w = \(self.scrollViewWidth); var h = \(self.scrollViewHeight); renderChart(data7);";
            
            webView.evaluateJavaScript(script9, completionHandler: nil)

            self.successState(Config.visualizationsIndex.treemap.rawValue)

        }
        else{
            //Log("Error processing professions")
            self.errorState(Config.visualizationsIndex.treemap.rawValue, error: self.errorDescription[Config.visualizationsIndex.treemap.rawValue])
        }
        
        if self.errorDescription[Config.visualizationsIndex.treemap.rawValue] != ""
        {
            self.errorState(Config.visualizationsIndex.treemap.rawValue, error: self.errorDescription[Config.visualizationsIndex.treemap.rawValue])
        }

        
    }
    
    func reorderCirclepackingData(){
        circlepackingData.sort({$0[2] < $1[2]})
    }
    
    func transformDataForCirclepacking(webView: WKWebView){
        //Log(circlepackingData)
        self.loadingState(Config.visualizationsIndex.circlepacking.rawValue)
        if self.circlepackingData.count > 0
        {
            reorderCirclepackingData()
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                var script9 = "var data7 = '{\"name\": \" \",\"children\": ["
                
                var groupName : String = "uninitialized" // this isn't safe, there should be a better way
                
                for r in 0..<self.circlepackingData.count{
                    if(groupName != self.circlepackingData[r][2]){
                        // stop the group (unless it's the first one)
                        if(groupName != "uninitialized"){
                            script9+="]},"
                        }
                        // new group
                        groupName = self.circlepackingData[r][2]
                        script9+="{\"name\": \""
                        script9+=groupName
                        script9+="\", \"children\": ["
                    }
                    else{
                        //continue the group
                        script9+=","
                    }
                    
                    script9+="{\"name\": \""
                    script9+=self.circlepackingData[r][0]
                    script9+="\", \"size\":"
                    script9+=self.circlepackingData[r][3]
                    script9+="}"
                }
                script9+="]}]}';var w = \(self.scrollViewWidth); var h = \(self.scrollViewHeight);  renderChart(data7, w, h);"

                //Log(script9)
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    webView.evaluateJavaScript(script9, completionHandler: nil)
                    
                    self.successState(Config.visualizationsIndex.circlepacking.rawValue)
                })
            })
            
        }
        else
        {
            self.noDataState(Config.visualizationsIndex.circlepacking.rawValue)
        }
        
        if self.errorDescription[Config.visualizationsIndex.circlepacking.rawValue] != ""
        {
            self.errorState(Config.visualizationsIndex.circlepacking.rawValue, error: self.errorDescription[Config.visualizationsIndex.circlepacking.rawValue])
        }

    }
    
    func stopForcegraph(){
        
        if let myWebView = visualizationViews[Config.visualizationsIndex.forcegraph.rawValue] as? WKWebView {
            myWebView.evaluateJavaScript("stopAnimation();", completionHandler: nil)
        }

    }
    
    func startForcegraph(){
        if let myWebView = visualizationViews[Config.visualizationsIndex.forcegraph.rawValue] as? WKWebView {
            myWebView.evaluateJavaScript("startAnimation();", completionHandler: nil)
        }
    }
    
    func transformDataForForcegraph(webView: WKWebView){
        //Log("transformDataForForcegraph... scrollViewWidth: \(scrollViewWidth)... scrollViewHeight: \(scrollViewHeight)")
        
        self.loadingState(Config.visualizationsIndex.forcegraph.rawValue)
        if self.forcegraphData.count > 0
        {
            //TODO: should have searchterm should be from actual searchterm
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                
                var script9 = "var myData = '{\"nodes\": [ {\"name\":\"\(self.searchText)\",\"value\":\(self.forcegraphData[0][2]),\"group\":1}, " //the search text just arbitrarily takes the value of the first data point as its value
                for r in 0..<self.self.forcegraphData.count{
                    script9+="{\"name\": \""
                    script9+=self.forcegraphData[r][0]
                    script9+="\", \"value\": "
                    script9+=self.forcegraphData[r][2]
                    script9+=", \"group\": 2"
                    script9+="}"
                    if(r != (self.forcegraphData.count-1)){
                        script9+=","
                    }
                }
                script9+="], \"links\": ["
                for r in 0..<self.forcegraphData.count{
                    script9+="{\"source\": 0"
                    script9+=", \"target\": "
                    script9+="\(r+1)"
                    script9+=", \"distance\": "
                    var myInteger = Int((self.forcegraphData[r][1] as NSString).floatValue*10000)
                    script9+="\(myInteger)"
                    script9+="}"
                    if(r != (self.forcegraphData.count-1)){
                        script9+=","
                    }
                }
                script9+="]}'; var w = \(self.scrollViewWidth); var h = \(self.scrollViewHeight); renderChart(myData,w,h);"
                
                //Log("DISTANCE SCRIPT9..... \(script9)")
                
                //var testscript = "var myData='{\"nodes\":[    {\"name\":\"Myriel\",\"value\":52,\"group\":1},    {\"name\":\"Labarre\",\"value\":5,\"group\":2},    {\"name\":\"Valjean\",\"value\":17,\"group\":2},    {\"name\":\"Mme.deR\",\"value\":55,\"group\":2},    {\"name\":\"Mme.deR\",\"value\":17,\"group\":2},    {\"name\":\"Isabeau\",\"value\":44,\"group\":2},    {\"name\":\"Mme.deR\",\"value\":17,\"group\":2},    {\"name\":\"Isabeau\",\"value\":22,\"group\":2},    {\"name\":\"Isabeau\",\"value\":17,\"group\":2},    {\"name\":\"Gervais\",\"value\":33,\"group\":2}  ],  \"links\":[    {\"source\":0,\"target\":1,\"distance\":33},    {\"source\":0,\"target\":2,\"distance\":22},    {\"source\":0,\"target\":3,\"distance\":22},    {\"source\":0,\"target\":4,\"distance\":11},    {\"source\":0,\"target\":5,\"distance\":22},    {\"source\":0,\"target\":6,\"distance\":22},    {\"source\":0,\"target\":7,\"distance\":43},    {\"source\":0,\"target\":8,\"distance\":22},    {\"source\":0,\"target\":9,\"distance\":22}  ]}'; var w = \(scrollViewWidth); var h = \(scrollViewHeight); renderChart(myData,w,h);";
                
                //println("TESTSCRIPT..... \(testscript)")
                
                // println(wordScript)
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    webView.evaluateJavaScript(script9, completionHandler: nil)
                    self.successState(Config.visualizationsIndex.forcegraph.rawValue)
                })
            })

        }
        else
        {
            //Log("NO DATA FOR DISTANCE?")
            self.noDataState(Config.visualizationsIndex.forcegraph.rawValue)
        }

        if self.errorDescription[Config.visualizationsIndex.forcegraph.rawValue] != ""
        {
            self.errorState(Config.visualizationsIndex.forcegraph.rawValue, error: self.errorDescription[Config.visualizationsIndex.forcegraph.rawValue])
        }

    }
    
    func stopTimemap(){
        if let myWebView = visualizationViews[Config.visualizationsIndex.timemap.rawValue] as? WKWebView {
            myWebView.evaluateJavaScript("stopAnimation();", completionHandler: nil)
        }
        
    }
    
    func startTimemap(){
        if let myWebView = visualizationViews[Config.visualizationsIndex.timemap.rawValue] as? WKWebView {
            myWebView.evaluateJavaScript("startAnimation();", completionHandler: nil)
        }
    }

    func transformDataForTimemapIOS(mapView: MKMapView){
        // this is probably unnecessary
        displayTimemapIOS(mapView)
    }
    
    func displayTimemapIOS(mapView: MKMapView){
        
    }
    
    func transformDataForTimemap(webView: WKWebView){
        
        //Log(timemapData)
        
        self.loadingState(Config.visualizationsIndex.timemap.rawValue)
        if self.timemapData.count > 0
        {
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                
                var biggestValue = 0
                
                var script9 = "var myData = [{\"key\": \"Tweet Count\", \"values\": ["
                
                for r in 0..<self.timemapData.count{
                    script9+="{\"z\": \""
                    script9+=self.timemapData[r][0]
                    script9+="\", \"x\":\""
                    script9+=self.timemapData[r][1]
                    script9+="\", \"y\":"
                    
                    var value = self.timemapData[r][2]
                    if(value.toInt() > biggestValue){
                        biggestValue = value.toInt()!
                        //Log("biggestValue is \(biggestValue)")
                    }
                    
                    script9+=value
                    script9+="}"
                    if(r != (self.timemapData.count-1)){
                        script9+=","
                    }
                }
                script9+="]}]; renderChart(myData, \(biggestValue).);"
                
                //Log(script9)
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    webView.evaluateJavaScript(script9, completionHandler: nil)
                    self.successState(Config.visualizationsIndex.timemap.rawValue)
                })
            })
        }
        else
        {
            self.noDataState(Config.visualizationsIndex.timemap.rawValue)
        }
        
        if self.errorDescription[Config.visualizationsIndex.timemap.rawValue] != ""
        {
            self.errorState(Config.visualizationsIndex.timemap.rawValue, error: self.errorDescription[Config.visualizationsIndex.timemap.rawValue])
        }
    }
    
    func makeScriptForStackedBar(firstIndex: Int, upperIndex: Int?=nil) -> String {
        var script9 = "var myData = [{\"key\": \"Tweet Count\", \"values\": ["
        
        for r in firstIndex..<self.stackedbarData.count{
            if (find(self.dateRange, self.stackedbarData[r][0]) == nil)
            {
                self.dateRange.append(self.stackedbarData[r][0])
            }
            
            
            script9+="{\"x\": \""
            script9+=self.stackedbarData[r][0]
            script9+="\", \"y\":"
            script9+=self.stackedbarData[r][1]
            script9+=", \"z\":"
            script9+=self.stackedbarData[r][2]
            script9+="}"
            
            
            if let unwrappedUpperIndex = upperIndex {
                if(self.stackedbarData[r][0] == dateRange[unwrappedUpperIndex]){
                    //it's the end of the range //get out of here
                    break
                }
            }
            
            // there's another data point so we need the comma
            if(r != (self.stackedbarData.count-1)){
                script9+=","
            }
        }
        script9+="]}]; renderChart(myData);"
        
        return script9
    }
    
    func redrawStackedBarWithNewRange(lowerIndex: Int, upperIndex: Int){
        var firstIndex = 0
        while firstIndex < self.stackedbarData.count && dateRange[lowerIndex] != self.stackedbarData[firstIndex][0] {
            firstIndex++
        }
        
        var script9 = self.makeScriptForStackedBar(firstIndex, upperIndex: upperIndex)
        
        if let myWebView = visualizationViews[Config.visualizationsIndex.stackedbar.rawValue] as? WKWebView {
            myWebView.evaluateJavaScript(script9, completionHandler: nil)
        }
        
    }
    
    func transformDataForStackedbar(webView: WKWebView){
        
        //[["11/17","43","33"],["11/18","22", "22"],["11/19","22", "22"],["11/20","22", "22"],["11/21","22", "22"],["11/22","22", "22"],["11/23","22", "22"]]
        
        //Log(stackedbarData)
        
        self.loadingState(Config.visualizationsIndex.stackedbar.rawValue)
        if self.stackedbarData.count > 0
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                
                var script9 = self.makeScriptForStackedBar(0)
                
                //Log(script9)
                
                //var script = "var myData = [{\"key\": \"Tweet Count\", \"values\": [  {\"x\":\"11/17\",\"y\":43, \"z\": 33},   {\"x\":\"11/18\",\"y\":22, \"z\": 22},   {\"x\":\"11/19\",\"y\":22, \"z\": 22},   {\"x\":\"11/20\",\"y\":33, \"z\": 11},    {\"x\":\"11/21\",\"y\":333, \"z\": 15},  {\"x\":\"11/22\",\"y\":44, \"z\": 23}, {\"x\":\"11/23\",\"y\":55, \"z\": 44} ] } ]; renderChart(myData);"
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    webView.evaluateJavaScript(script9, completionHandler: nil)
                    self.updateRangeSliderBarChart()
                    self.successState(Config.visualizationsIndex.stackedbar.rawValue)
                    
                })
            })
        }
        else
        {
            self.noDataState(Config.visualizationsIndex.stackedbar.rawValue)
        }
        
        if self.errorDescription[Config.visualizationsIndex.stackedbar.rawValue] != ""
        {
            self.errorState(Config.visualizationsIndex.stackedbar.rawValue, error: self.errorDescription[Config.visualizationsIndex.stackedbar.rawValue])
        }

    }
    
    
    // needs to be normalized
    func transformDataForWordcloud(webView: WKWebView){
        //Log("transformDataForWordcloud (not yet imp)")
        self.loadingState(Config.visualizationsIndex.wordcloud.rawValue)
        if self.wordcloudData.count > 0
        {
            //Log("transformDataForWordcloud")
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                
                var script9 = "var data2 = [[ "
                
                var currentTopicNumber = self.wordcloudData[0][0]
                
                var maxSize = 0; var minSize = 100000;
                
                for r in 0..<self.wordcloudData.count{
                    var thisTopicNumber = self.wordcloudData[r][0]
                    if( thisTopicNumber != currentTopicNumber){
                        //switch topics
                        script9+="], ["
                    }
                    else{
                        if(r != 0 && r != (self.wordcloudData.count)){
                            script9+=","
                        }
                    }
                    currentTopicNumber = thisTopicNumber
                    
                    script9+="{\"text\": \""
                    script9+=self.wordcloudData[r][1]
                    script9+="\", \"size\": \""
                    var number = Int(((self.wordcloudData[r][2] as NSString).doubleValue*100000))
                    if number > maxSize{
                        maxSize = number
                    }
                    if number < minSize{
                        minSize = number
                    }
                    script9+=String(number)
                    script9+="\", \"topic\": \""
                    script9+=thisTopicNumber
                    script9+="\"}"
                }
                script9+="]]; var maxSize = \(maxSize); var minSize = \(minSize); renderChart(data2, maxSize, minSize);"
                
                Log("maxSize: \(maxSize).... and script9")
                Log(script9)
                
                //var script8 = "var data2 = [[  {\"text\": \"access\", \"size\": \"1238\", \"topic\": \"0\"},  {\"text\": \"streets\", \"size\": \"1020\", \"topic\": \"0\"},  {\"text\": \"transportation\", \"size\": \"982\", \"topic\": \"0\"},  {\"text\": \"system\", \"size\": \"824\", \"topic\": \"0\"},  {\"text\": \"pedestrian\", \"size\": \"767\", \"topic\": \"0\"},  {\"text\": \"provide\", \"size\": \"763\", \"topic\": \"0\"},  {\"text\": \"bicycle\", \"size\": \"719\", \"topic\": \"0\"},  {\"text\": \"major\", \"size\": \"696\", \"topic\": \"0\"},  {\"text\": \"coordinate\", \"size\": \"72\", \"topic\": \"0\"},  {\"text\": \"separated\", \"size\": \"68\", \"topic\": \"0\"}],         [  {\"text\": \"buildings\", \"size\": \"460\", \"topic\": \"1\"},  {\"text\": \"plan\", \"size\": \"451\", \"topic\": \"1\"},  {\"text\": \"policy\", \"size\": \"442\", \"topic\": \"1\"},  {\"text\": \"neighborhoods\", \"size\": \"327\", \"topic\": \"1\"},  {\"text\": \"civic\", \"size\": \"301\", \"topic\": \"1\"},  {\"text\": \"community\", \"size\": \"249\", \"topic\": \"1\"},  {\"text\": \"strategies\", \"size\": \"235\", \"topic\": \"1\"},  {\"text\": \"existing\", \"size\": \"222\", \"topic\": \"1\"},  {\"text\": \"lots\", \"size\": \"221\", \"topic\": \"1\"},  {\"text\": \"walkable\", \"size\": \"217\", \"topic\": \"1\"},  {\"text\": \"upper\", \"size\": \"46\", \"topic\": \"1\"},  {\"text\": \"added\", \"size\": \"46\", \"topic\": \"1\"},  {\"text\": \"long\", \"size\": \"43\", \"topic\": \"1\"}], [  {\"text\": \"development\", \"size\": \"818\", \"topic\": \"2\"},  {\"text\": \"transit\", \"size\": \"746\", \"topic\": \"2\"},  {\"text\": \"centers\", \"size\": \"647\", \"topic\": \"2\"},  {\"text\": \"mixed\", \"size\": \"640\", \"topic\": \"2\"},  {\"text\": \"urban\", \"size\": \"443\", \"topic\": \"2\"}  ], [  {\"text\": \"snorlax\", \"size\": \"3333\", \"topic\": \"3\"},  {\"text\": \"pikachu\", \"size\": \"222\", \"topic\": \"3\"}  ]];"
                
                //script8+=" renderChart(data2);"
                
                //println("WORDCLOUD STUFF")
                //println(script9)
                
                //println("SCRIPT8")
                //println(script8)
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    webView.evaluateJavaScript(script9, completionHandler: nil); //TODO: have completion handler?
                    
                    //TODO: Implement display world cloud
                    self.successState(Config.visualizationsIndex.wordcloud.rawValue)
                })
            })
        }
        else
        {
            self.noDataState(Config.visualizationsIndex.wordcloud.rawValue)
        }
        
        if self.errorDescription[Config.visualizationsIndex.wordcloud.rawValue] != ""
        {
            self.errorState(Config.visualizationsIndex.wordcloud.rawValue, error: self.errorDescription[Config.visualizationsIndex.wordcloud.rawValue])
        }

    }

    

    // MARK: Display states
    func loadingState(index: Int)
    {
        self.visualizationViews[index].hidden = true
        self.loadingViews[index].startAnimating()
        self.loadingViews[index].hidden = false
        self.resultsLabels[index].hidden = true
    }
    
    func successState(index: Int)
    {
        self.visualizationViews[index].hidden = false
        self.loadingViews[index].stopAnimating()
        self.loadingViews[index].hidden = true
        self.resultsLabels[index].hidden = true
    }
    
    func noDataState(index: Int)
    {
        if !self.isloadingVisualization[index]
        {
            self.visualizationViews[index].hidden = true
            self.loadingViews[index].stopAnimating()
            self.loadingViews[index].hidden = true
            self.resultsLabels[index].hidden = false
        }
    }
    
    func errorState(index: Int, error: String)
    {
        self.visualizationViews[index].hidden = true
        self.loadingViews[index].stopAnimating()
        self.loadingViews[index].hidden = true
        self.resultsLabels[index].text = error
        self.resultsLabels[index].hidden = false
    }
    
    //MARK: Clean WebViews
    func cleanWebViews()
    {
        for var i = 0; i < self.visualizationViews.count; i++
        {
            self.loadingState(i)
            self.isloadingVisualization[i] = true
            self.errorDescription[i] = ""
        }
        
        //Clear charts data
        self.treemapData.removeAll(keepCapacity: false)
        self.circlepackingData.removeAll(keepCapacity: false)
        self.worddistanceData.removeAll(keepCapacity: false)
        self.forcegraphData.removeAll(keepCapacity: false)
        self.timemapData.removeAll(keepCapacity: false)
        self.stackedbarData.removeAll(keepCapacity: false)
        self.wordcloudData.removeAll(keepCapacity: false)
        self.rangeSliderBarChart.hidden = true
        if(self.rangeLabels.count > 0)
        {
            self.rangeLabels[0].hidden = true
            self.rangeLabels[1].hidden = true
        }
        
    }
    
    func updateRangeSliderBarChart()
    {
        self.rangeSliderBarChart.lowerValue = 0.0
        self.rangeSliderBarChart.upperValue = 1.0
        
        self.rangeLabels[0].text = self.dateRange[0].substringToIndex(advance(dateRange[0].endIndex, -3))
        self.rangeLabels[1].text = self.dateRange[self.dateRange.count-1].substringToIndex(advance(dateRange[self.dateRange.count-1].endIndex, -3))
        
        self.rangeSliderBarChart.hidden = false
        self.rangeLabels[0].hidden = false
        self.rangeLabels[1].hidden = false
    }
    
    /*
    func populateCharts(json : JSON){ //used for dummy data
        if(Config.useDummyData){
            self.circlepackingData = [["1","spark","222"],["1","sparksummit","344"],["2","#ibm","111"],["3","bigdata","577"],["3","analytics","99"],["4","@mapr","233"],["4","hadoop","333"],["4","hdfs","288"],["4","hortonworks","555"],["1","#sparkinsight","444"],["3","datamining","55"]]
            //self.reorderCirclepackingData()
            
            self.treemapData = [["data scientist","222"],["programmer","344"],["designer","111"],["roboticist","577"],["marketer","99"],["barista","233"],["ceo","333"],["founder","288"],["fortune500","555"],["analyst","444"],["gamedev","55"]]
            
            self.stackedbarData = [["11/17","43","33"],["11/18","22", "22"],["11/19","22", "22"],["11/20","22", "22"],["11/21","22", "22"],["11/22","22", "22"],["11/23","22", "22"]]
            
            self.worddistanceData = [ [ "#datamining", "0.66010167854665769", "457" ], [ "#analytics", "0.66111733184244015", "3333" ], [ "#rstats", "0.69084306092036141", "361" ], [ "@hortonworks", "0.66914077012093209", "166" ], [ "#neo4j", "0.69127034015170996", "63" ], [ "#datascience", "0.67888717822606814", "4202" ], [ "#azure", "0.66226415367181413", "667" ], [ "@mapr", "0.66354464393456225", "165" ], [ "#deeplearning", "0.66175874534547685", "396" ], [ "#machinelearning", "0.6964340180591716", "2260" ], [ "#nosql", "0.75678772608504818", "877" ], [ "#sas", "0.70367785412709649", "145" ], [ "#mongodb", "0.6993281653000063", "225" ], [ "#hbase", "0.78010979167439309", "138" ], [ "#python", "0.69931247945181596", "2821" ], [ "#mapreduce", "0.72372695100578921", "62" ], [ "#apache", "0.75935793530857787", "244" ], [ "#cassandra", "0.76777460490727012", "128" ], [ "#hadoop", "0.82618702428574087", "1831" ], [ "#r", "0.76732526060916861", "277" ] ]
            
            self.wordcloudData = [["0", "link", "0.2"], ["0", "Very", "0.3"], ["0", "worry", "0.3"], ["0", "hold", "0.00001"], ["0", "City", "0.0002"], ["0", "Ackles", "0.01"], ["0", "places", "0.1"], ["0", "Followers", "0.001"], ["0", "donxe2x80x99t", "0.002"], ["0", "seems", "0.01"], ["1", "power", "0.1"], ["1", "keep", "0.22"], ["1", "Scherzinger", "0.3"], ["1", "@justinbieber:", "0.12"], ["1", "SUPER", "0.16"], ["1", "#ChoiceTVBreakOutStar", "0.09"], ["1", "#ChoiceMaleHottie", "0.35"], ["1", "call", "0.05"], ["1", "years", "0.2"], ["1", "change", "0.3"], ["2", "pretty", "0.15"], ["2", "needed", "0.12"], ["2", "like", "0.16"], ["2", "song", "0.002"], ["2", "SEHUN", "0.0000002"], ["2", "team", "0.01"], ["2", "Because", "0.012"], ["2", "needs", "0.004"], ["2", "forever", "0.12"], ["2", "stop", "0.17"], ["3", "fucking", "0.07"], ["3", "Followers", "0.16"], ["3", "#TheOriginals", "0.14"], ["3", "move", "0.02"], ["3", "close", "0.004"], ["3", "dream", "0.002"], ["3", "Update", "0.001"], ["3", "picture", "0.1"], ["3", "President", "0.015"], ["3", "play", "0.12"]]
            
            self.forcegraphData = [ [ "#datamining", "0.66010167854665769", "457" ], [ "#analytics", "0.66111733184244015", "3333" ], [ "#rstats", "0.69084306092036141", "361" ], [ "@hortonworks", "0.66914077012093209", "166" ], [ "#neo4j", "0.69127034015170996", "63" ], [ "#datascience", "0.67888717822606814", "4202" ], [ "#azure", "0.66226415367181413", "667" ], [ "@mapr", "0.66354464393456225", "165" ], [ "#deeplearning", "0.66175874534547685", "396" ], [ "#machinelearning", "0.6964340180591716", "2260" ], [ "#nosql", "0.75678772608504818", "877" ], [ "#sas", "0.70367785412709649", "145" ], [ "#mongodb", "0.6993281653000063", "225" ], [ "#hbase", "0.78010979167439309", "138" ], [ "#python", "0.69931247945181596", "2821" ], [ "#mapreduce", "0.72372695100578921", "62" ], [ "#apache", "0.75935793530857787", "244" ], [ "#cassandra", "0.76777460490727012", "128" ], [ "#hadoop", "0.82618702428574087", "1831" ], [ "#r", "0.76732526060916861", "277" ] ]
            
            self.timemapData =
                [ [  "20-Apr", "United States", "754" ], [ "20-Apr", "United Kingdom", "347" ], [ "21-Apr", "United States", "1687" ], ["21-Apr", "United Kingdom", "555"], [ "22-Apr", "United States", "2222" ], ["22-Apr", "United Kingdom", "155"], [ "23-Apr", "United States", "4343" ], ["23-Apr", "United Kingdom", "1214"], [ "24-Apr", "United States", "9999" ], ["24-Apr", "United Kingdom", "3333"], [ "25-Apr", "United States", "1687" ], ["25-Apr", "United Kingdom", "555"], [ "26-Apr", "United States", "1687" ], ["26-Apr", "United Kingdom", "555"] ]
        }
        self.reloadAppropriateView(previousPage) //reload the current page
        // other pages will get loaded when they are swiped to
    }
    */

    
}