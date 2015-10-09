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
    
    var countryCircleViews = [String: CircleView]()
    var timemapTimer : NSTimer!
    var indexOfLastDate = 0
    let maxCircleSize = 300.0
    var circleResizeConstant = 1.0 //this will change
    
    func reloadAppropriateView(viewNumber: Int){
        if let myNativeView = visualizationViews[viewNumber] as? NativeVisualizationView {
            //print("TODO: reload a NativeVisualizationView")
            
            if(viewNumber == Config.visualizationsIndex.timemap.rawValue){
                transformData(myNativeView)
            }
            
            // TODO: implement
        }
        else if let myWebView = visualizationViews[viewNumber] as? WKWebView {
            if var url = myWebView.URL{
                //Log("if var request = webViews[viewNumber].request! is \(request)")
                
                if(viewNumber >= 0 && viewNumber < Config.getNumberOfVisualizations()){

                    self.loadingState(viewNumber)
                    //webViews[viewNumber].scalesPageToFit = Config.scalePagesToFit[viewNumber]
                    let filePath = NSURL(fileURLWithPath: Config.visualisationFolderPath).URLByAppendingPathComponent(NSURL(fileURLWithPath: Config.visualizationNames[viewNumber]).URLByAppendingPathExtension("html").path!)
                    let request = NSURLRequest(URL: filePath)
                    myWebView.loadRequest(request)
                    
                }
                
                if(viewNumber == Config.visualizationsIndex.timemap.rawValue){
                    
                }
                
            }
            else{
                //Log("NOT if var request = webViews[viewNumber].request!")
            }
        }
    }
    
    func reloadAllViews() {
        self.reloadAppropriateView(Config.visualizationsIndex.circlepacking.rawValue)
        self.reloadAppropriateView(Config.visualizationsIndex.stackedbar.rawValue)
        self.reloadAppropriateView(Config.visualizationsIndex.treemap.rawValue)
        self.reloadAppropriateView(Config.visualizationsIndex.timemap.rawValue)
        self.reloadAppropriateView(Config.visualizationsIndex.forcegraph.rawValue)
        self.makeVisibleRangeSliderBarChartAndLabels()
        
    }
    
    func transformData(myView: UIView){
        // uses the path to determine which function to use
        
        if let myTimeMapView = myView as? TimeMapView {
            self.transformDataForTimemapIOS(myTimeMapView)
        }
        else if let webView = myView as? WKWebView {
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
    }
    
    func transformDataForTreemapping(webView: WKWebView){
        self.loadingState(Config.visualizationsIndex.treemap.rawValue)
        
        var treemapDataTrimmed : String
        
        if let rangeOfStart = self.treemapData.rangeOfString("\"profession\" : ["){
            treemapDataTrimmed = "{\"name\": \"Profession\",\"children\": ["+self.treemapData.substringFromIndex(rangeOfStart.endIndex)
            
            treemapDataTrimmed = treemapDataTrimmed.stringByReplacingOccurrencesOfString("\n", withString: "")
            
            let script9 = "var data7 = '\(treemapDataTrimmed)'; var w = \(self.scrollViewWidth); var h = \(self.scrollViewHeight); renderChart(data7, w, h);";
            
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
        circlepackingData.sortInPlace({$0[2] < $1[2]})
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
                    let myInteger = Int((self.forcegraphData[r][1] as NSString).floatValue*10000)
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
    
    //TODO update for native
    func stopTimemap(){
        //Log("stopTimemap")
        zeroTimemapCircles()
        
        timemapTimer.invalidate()
        timemapTimer = nil;
    }
    
    //TODO update for native
    func startTimemap(){
        //Log("startTimemap")
        self.timemapTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("tickTimemap"), userInfo: nil, repeats: true)
    }
    
    // todo perhaps make the circles invisible too
    func zeroTimemapCircles(){
        let countriesFilePath = NSBundle.mainBundle().pathForResource("VisualizationsNativeData/timemap/CountryList", ofType: "plist")
        let countries = NSDictionary(contentsOfFile: countriesFilePath!)
        
        let countriesArray : Array = countries?.objectForKey("CountryList") as! Array<String>
        if !countryCircleViews.isEmpty{
            for myCountryString in countriesArray{
                countryCircleViews[myCountryString]?.changeRadiusTo(0.0)
            }
        }
    }

    func xFromCountryDictionary(myCountry: NSDictionary) -> Double{
        let longitude   = Double(myCountry["longitude"]! as! NSNumber)
        
        return xFromLongitude(longitude)
    }
    
    func yFromCountryDictionary(myCountry: NSDictionary) -> Double{
        let latitude    = Double(myCountry["latitude"]! as! NSNumber)
        
        return yFromLatitude(latitude)
    }

    func xFromLongitude(longitude: Double) -> Double{
        let mapWidth    = Double(scrollViewWidth) // make it the map width?
        
        // get x value
        let x = (longitude+180.0)*(mapWidth/360.0)
        
        //Log("xFromLongitude... longitude: \(longitude) becomes x: \(x)")
        
        return x
    }
    
    func yFromLatitude(latitude: Double) -> Double{
        let mapWidth    = Double(scrollViewWidth) // make it the map width?
        let mapHeight   = Double(scrollViewHeight) // make it the map height?
        
        // ORIGINAL ASPECT RATIO //2058 × 1746
        // new aspect ratio // 1024 x 624
        let originalHeightAspect = 1746.0/2058.0 //badly hardcoded
        let newHeightAspect = Double(scrollViewHeight/scrollViewWidth)
        let resizeHeight = newHeightAspect/originalHeightAspect
        let resizedLatitude = resizeHeight*latitude

        
        // convert from degrees to radians
        let latRad = resizedLatitude*M_PI/180.0;
        
        // get y value
        let mercN = log(tan((M_PI/4.0)+(latRad/2.0)));
        let y     = (mapHeight/2.0)-(mapWidth*mercN/(2.0*M_PI));
        
        
        //Log("yFromLatitude... latitude: \(latitude) becomes y: \(y)")
        
        return y
    }
    
    func transformDataForTimemapIOS(myView: TimeMapView){
        
        if(CenterViewController.leftViewOpen){ //small
            myView.frame.origin.y = CGFloat(Config.smallscreenMapTopPadding)
        }
        else{ //big
            myView.frame.origin.y = CGFloat(Config.fullscreenMapTopPadding)
        }
        
        myView.baseMapView!.frame = CGRectMake(0, 0, self.scrollViewWidth, self.scrollViewHeight)

        //TODO only do this once
        var biggestValue = 0.0
        if self.timemapData.count > 0
        {
            biggestValue = 0
            for r in 0..<self.timemapData.count{
                
                let value = self.timemapData[r][2]
                if(Double(value) > biggestValue){
                    biggestValue = Double(value)!
                }
            }
        }
        
        circleResizeConstant = maxCircleSize / biggestValue //size of the biggest possible circle
    
        //Log("map size in transformDataForTimemapIOS... scrollViewWidth.. \(scrollViewWidth),  scrollViewHeight.. \(scrollViewHeight)");
        let filePath = NSBundle.mainBundle().pathForResource("VisualizationsNativeData/timemap/CountryData", ofType: "plist")
        let properties = NSDictionary(contentsOfFile: filePath!)
        
        let countriesFilePath = NSBundle.mainBundle().pathForResource("VisualizationsNativeData/timemap/CountryList", ofType: "plist")
        let countries = NSDictionary(contentsOfFile: countriesFilePath!)
        
        let countriesArray : Array = countries?.objectForKey("CountryList") as! Array<String>
        
        zeroTimemapCircles()
        countryCircleViews.removeAll()
        if(countryCircleViews.isEmpty){ //initialize it if you havent //this isnt being redone! redo it
            for myCountryString in countriesArray{
                
                let myCountry : NSDictionary = properties![myCountryString]! as! NSDictionary
                
                let x = xFromCountryDictionary(myCountry)
                let y = yFromCountryDictionary(myCountry)
                
                var circleView : CircleView                
                circleView = CircleView(frame: CGRectMake( CGFloat(x), CGFloat(y), 0, 0))
                
                countryCircleViews[myCountryString] = circleView
                
                myView.addSubview(circleView)
            }
        }
    }
    
    @objc func tickTimemap()
    {
        //Log("tickTimemap().... indexOfLastDate is \(indexOfLastDate)")
        let countriesFilePath = NSBundle.mainBundle().pathForResource("VisualizationsNativeData/timemap/CountryList", ofType: "plist")
        let countries = NSDictionary(contentsOfFile: countriesFilePath!)
        let countriesArray : Array = countries?.objectForKey("CountryList") as! Array<String>
        
        for countryName in countriesArray
        {
            if let myCircleView = countryCircleViews[countryName] {
                myCircleView.changeRadiusTo(0.0)
            }
        }
        
        // set the radii
        var lastDate :String = "";
        var currentDate :String = "";
        var i = indexOfLastDate;
        
        while( currentDate == lastDate){ // and you're not at the end

            var radius : CGFloat = 0.0
            
            if let n = NSNumberFormatter().numberFromString(timemapData[i][2]) {
                radius = CGFloat(n) * CGFloat(circleResizeConstant)
            }
            
            //change the radius associated with the string
            countryCircleViews[timemapData[i][1]]?.changeRadiusTo(radius)
            
            lastDate = timemapData[i][0]
            i++
            if( i >= timemapData.count ){
                //Log("Reached the end of timemap data.... it's time to loop.")
                i = 0
            }
            currentDate = timemapData[i][0]
        }
        
        indexOfLastDate = i
        visualizationViews[Config.visualizationsIndex.timemap.rawValue].setNeedsDisplay()
    }
    
    func makeScriptForStackedBar(firstIndex: Int, upperIndex: Int?=nil) -> String {
        var script9 = "var myData = [{\"key\": \"Tweet Count\", \"values\": ["
        
        for r in firstIndex..<self.stackedbarData.count{
            if (self.dateRange.indexOf(self.stackedbarData[r][0]) == nil)
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
        
        let script9 = self.makeScriptForStackedBar(firstIndex, upperIndex: upperIndex)
        
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
                
                let script9 = self.makeScriptForStackedBar(0)
                
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
                    let thisTopicNumber = self.wordcloudData[r][0]
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
                    let number = Int(((self.wordcloudData[r][2] as NSString).doubleValue*100000))
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
                
                //Log("maxSize: \(maxSize).... and script9")
                Log(script9)
                
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
        if self.visualizationViews.count > index {
            self.visualizationViews[index].hidden = true
            self.loadingViews[index].stopAnimating()
            self.loadingViews[index].hidden = true
            self.resultsLabels[index].text = error
            self.resultsLabels[index].hidden = false
        }
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
        
        self.rangeLabels[0].text = self.dateRange[0].substringToIndex(dateRange[0].endIndex.advancedBy(-3))
        self.rangeLabels[1].text = self.dateRange[self.dateRange.count-1].substringToIndex(dateRange[self.dateRange.count-1].endIndex.advancedBy(-3))
        
        self.rangeSliderBarChart.hidden = false
        self.rangeLabels[0].hidden = false
        self.rangeLabels[1].hidden = false
    }
    
    func hideRangeSliderBarChartAndLabels(){
        self.rangeSliderBarChart.hidden = true
        self.rangeLabels[0].hidden = true
        self.rangeLabels[1].hidden = true
    }
    
    func makeVisibleRangeSliderBarChartAndLabels(){
        self.rangeSliderBarChart.hidden = false
        self.rangeLabels[0].hidden = false
        self.rangeLabels[1].hidden = false
        
    }

    
}