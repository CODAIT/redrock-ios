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

class VisualizationHandler{
    var webViews : [UIWebView] = [UIWebView]()
    var loadingViews = [UIActivityIndicatorView]()
    var resultsLabels = [UILabel]()
    var isloadingVisualization = [Bool]()
    var errorDescription = [String]()
    var searchText : String = ""
    
    var scrollViewHeight : CGFloat = 0.0 //set in CenterViewController
    var scrollViewWidth : CGFloat = 0.0 //set in CenterViewController
    
    var treemapData : [[String]]       = [[String]]()
    var circlepackingData : [[String]]      = [[String]]()
    var worddistanceData : [[String]]      = [[String]]()
    var forcegraphData : [[String]]      = [[String]]()
    var timemapData : [[String]] = [[String]]()
    var stackedbarData : [[String]] = [[String]]()
    var wordcloudData : [[String]] = [[String]]()
    
    var firstLoad = false
    
    func reloadAppropriateView(viewNumber: Int){
        if var request = webViews[viewNumber].request{
            //Log("if var request = webViews[viewNumber].request! is \(request)")
            
            if(viewNumber >= 0 && viewNumber < Config.getNumberOfVisualizations()){

                self.loadingState(viewNumber)
                webViews[viewNumber].scalesPageToFit = Config.scalePagesToFit[viewNumber]
                let filePath = NSBundle.mainBundle().URLForResource("Visualizations/"+Config.visualizationNames[viewNumber], withExtension: "html")
                let request = NSURLRequest(URL: filePath!)
                webViews[viewNumber].loadRequest(request)
            }
        }
        else{
            //Log("NOT if var request = webViews[viewNumber].request!")
        }
    }
    
    func transformData(webView: UIWebView){
        // uses the path to determine which function to use
        switch webView.request!.URL!.lastPathComponent!{
        case "treemap.html":
            transformDataForTreemapping(webView)
            break;
        case "circlepacking.html":
            transformDataForCirclepacking(webView)
            break;
        case "forcegraph.html":
            transformDataForForcegraph(webView)
            break;
        case "timemap.html":
            transformDataForTimemap(webView)
            break;
        case "stackedbar.html":
            transformDataForStackedbar(webView)
            break;
        case "wordcloud.html":
            transformDataForWordcloud(webView)
        default:
            break;
        }
    }
    
    func transformDataForTreemapping(webView: UIWebView){
        //Log(treemapData)
        self.loadingState(Config.visualizationsIndex.treemap.rawValue)
        if self.treemapData.count > 0
        {
            var script9="var data7 = '{\"name\": \"all\",\"children\": ["
            
            for r in 0..<treemapData.count{
                script9+="{\"name\": \""
                script9+=treemapData[r][0]
                script9+="\",\"children\": [{\"name\": \""
                script9+=treemapData[r][0]
                script9+="\", \"size\": "
                script9+=treemapData[r][1]
                script9+="}]}"
                if(r != (treemapData.count-1)){
                    script9+=","
                }
            }
            script9+="]}'; renderChart(data7);"
            
            //Log(script9)
            
            //var treeScript = "var data7 = '{\"name\": \"all\",\"children\": [{\"name\": \"goblin\",\"children\": [{\"name\": \"goblin\", \"size\": 3938}]},{\"name\": \"demon\",\"children\": [{\"name\": \"demon\", \"size\": 6666}]},{\"name\": \"coffee\",\"children\": [{\"name\": \"coffee\", \"size\": 1777}]},{\"name\": \"cop\",\"children\": [{\"name\": \"cop\", \"size\": 743}]}]}'; renderChart(data7);"
            
            webView.stringByEvaluatingJavaScriptFromString(script9)
            self.successState(Config.visualizationsIndex.treemap.rawValue)
        }
        else
        {
            self.noDataState(Config.visualizationsIndex.treemap.rawValue)
        }
        
        if self.errorDescription[Config.visualizationsIndex.treemap.rawValue] != ""
        {
            self.errorState(Config.visualizationsIndex.treemap.rawValue, error: self.errorDescription[Config.visualizationsIndex.treemap.rawValue])
        }
    }
    
    func reorderCirclepackingData(){
        circlepackingData.sort({$0[2] < $1[2]})
    }
    
    func transformDataForCirclepacking(webView: UIWebView){
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
                script9+="]}]}'; renderChart(data7);"
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    webView.stringByEvaluatingJavaScriptFromString(script9)
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
    
    func transformDataForForcegraph(webView: UIWebView){
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
                    webView.stringByEvaluatingJavaScriptFromString(script9)
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

    
    func transformDataForTimemap(webView: UIWebView){
        
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
                    webView.stringByEvaluatingJavaScriptFromString(script9)
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
    
    func transformDataForStackedbar(webView: UIWebView){
        
        //[["11/17","43","33"],["11/18","22", "22"],["11/19","22", "22"],["11/20","22", "22"],["11/21","22", "22"],["11/22","22", "22"],["11/23","22", "22"]]
        
        //Log(stackedbarData)
        
        self.loadingState(Config.visualizationsIndex.stackedbar.rawValue)
        if self.stackedbarData.count > 0
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                
                var script9 = "var myData = [{\"key\": \"Tweet Count\", \"values\": ["
                
                for r in 0..<self.stackedbarData.count{
                    script9+="{\"x\": \""
                    script9+=self.stackedbarData[r][0]
                    script9+="\", \"y\":"
                    script9+=self.stackedbarData[r][1]
                    script9+=", \"z\":"
                    script9+=self.stackedbarData[r][2]
                    script9+="}"
                    if(r != (self.stackedbarData.count-1)){
                        script9+=","
                    }
                }
                script9+="]}]; renderChart(myData);"
                
                //Log(script9)
                
                //var script = "var myData = [{\"key\": \"Tweet Count\", \"values\": [  {\"x\":\"11/17\",\"y\":43, \"z\": 33},   {\"x\":\"11/18\",\"y\":22, \"z\": 22},   {\"x\":\"11/19\",\"y\":22, \"z\": 22},   {\"x\":\"11/20\",\"y\":33, \"z\": 11},    {\"x\":\"11/21\",\"y\":333, \"z\": 15},  {\"x\":\"11/22\",\"y\":44, \"z\": 23}, {\"x\":\"11/23\",\"y\":55, \"z\": 44} ] } ]; renderChart(myData);"
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    webView.stringByEvaluatingJavaScriptFromString(script9)
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
    
    func transformDataForWordcloud(webView: UIWebView){
        //Log("transformDataForWordcloud (not yet imp)")
        self.loadingState(Config.visualizationsIndex.wordcloud.rawValue)
        if self.wordcloudData.count > 0
        {
            //Log("transformDataForWordcloud")
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                
                var script9 = "var data2 = [[ "
                
                var currentTopicNumber = self.wordcloudData[0][0]
                
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
                    var number = String(Int(((self.wordcloudData[r][2] as NSString).doubleValue*100000)))
                    script9+=number
                    script9+="\", \"topic\": \""
                    script9+=thisTopicNumber
                    script9+="\"}"
                }
                script9+="]]; renderChart(data2);"
                
                //var script8 = "var data2 = [[  {\"text\": \"access\", \"size\": \"1238\", \"topic\": \"0\"},  {\"text\": \"streets\", \"size\": \"1020\", \"topic\": \"0\"},  {\"text\": \"transportation\", \"size\": \"982\", \"topic\": \"0\"},  {\"text\": \"system\", \"size\": \"824\", \"topic\": \"0\"},  {\"text\": \"pedestrian\", \"size\": \"767\", \"topic\": \"0\"},  {\"text\": \"provide\", \"size\": \"763\", \"topic\": \"0\"},  {\"text\": \"bicycle\", \"size\": \"719\", \"topic\": \"0\"},  {\"text\": \"major\", \"size\": \"696\", \"topic\": \"0\"},  {\"text\": \"coordinate\", \"size\": \"72\", \"topic\": \"0\"},  {\"text\": \"separated\", \"size\": \"68\", \"topic\": \"0\"}],         [  {\"text\": \"buildings\", \"size\": \"460\", \"topic\": \"1\"},  {\"text\": \"plan\", \"size\": \"451\", \"topic\": \"1\"},  {\"text\": \"policy\", \"size\": \"442\", \"topic\": \"1\"},  {\"text\": \"neighborhoods\", \"size\": \"327\", \"topic\": \"1\"},  {\"text\": \"civic\", \"size\": \"301\", \"topic\": \"1\"},  {\"text\": \"community\", \"size\": \"249\", \"topic\": \"1\"},  {\"text\": \"strategies\", \"size\": \"235\", \"topic\": \"1\"},  {\"text\": \"existing\", \"size\": \"222\", \"topic\": \"1\"},  {\"text\": \"lots\", \"size\": \"221\", \"topic\": \"1\"},  {\"text\": \"walkable\", \"size\": \"217\", \"topic\": \"1\"},  {\"text\": \"upper\", \"size\": \"46\", \"topic\": \"1\"},  {\"text\": \"added\", \"size\": \"46\", \"topic\": \"1\"},  {\"text\": \"long\", \"size\": \"43\", \"topic\": \"1\"}], [  {\"text\": \"development\", \"size\": \"818\", \"topic\": \"2\"},  {\"text\": \"transit\", \"size\": \"746\", \"topic\": \"2\"},  {\"text\": \"centers\", \"size\": \"647\", \"topic\": \"2\"},  {\"text\": \"mixed\", \"size\": \"640\", \"topic\": \"2\"},  {\"text\": \"urban\", \"size\": \"443\", \"topic\": \"2\"}  ], [  {\"text\": \"snorlax\", \"size\": \"3333\", \"topic\": \"3\"},  {\"text\": \"pikachu\", \"size\": \"222\", \"topic\": \"3\"}  ]];"
                
                //script8+=" renderChart(data2);"
                
                //println("WORDCLOUD STUFF")
                //println(script9)
                
                //println("SCRIPT8")
                //println(script8)
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    webView.stringByEvaluatingJavaScriptFromString(script9)
                    
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
        self.webViews[index].hidden = true
        self.loadingViews[index].startAnimating()
        self.loadingViews[index].hidden = false
        self.resultsLabels[index].hidden = true
    }
    
    func successState(index: Int)
    {
        self.webViews[index].hidden = false
        self.loadingViews[index].stopAnimating()
        self.loadingViews[index].hidden = true
        self.resultsLabels[index].hidden = true
    }
    
    func noDataState(index: Int)
    {
        if !self.isloadingVisualization[index]
        {
            self.webViews[index].hidden = true
            self.loadingViews[index].stopAnimating()
            self.loadingViews[index].hidden = true
            self.resultsLabels[index].hidden = false
        }
    }
    
    func errorState(index: Int, error: String)
    {
        self.webViews[index].hidden = true
        self.loadingViews[index].stopAnimating()
        self.loadingViews[index].hidden = true
        self.resultsLabels[index].text = error
        self.resultsLabels[index].hidden = false
    }
    
    //MARK: Clean WebViews
    func cleanWebViews()
    {
        for var i = 0; i < self.webViews.count; i++
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
    }
    
}