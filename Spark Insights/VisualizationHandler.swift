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
    
    var treemapData : [[String]]       = [[String]]()
    var circlepackingData : [[String]]      = [[String]]()
    var worddistanceData : [[String]]      = [[String]]()
    var timemapData : [[String]] = [[String]]()
    var stackedbarData : [[String]] = [[String]]()
    var wordcloudData : [[String]] = [[String]]()
    
    func reloadAppropriateView(viewNumber: Int){
        //println("should reload \(viewNumber)")
        
        if(viewNumber >= 0 && viewNumber < Config.getNumberOfVisualizations()){
            webViews[viewNumber].scalesPageToFit = Config.scalePagesToFit[viewNumber]
            webViews[viewNumber].loadRequest(webViews[viewNumber].request!)
            self.webViews[viewNumber].hidden = false
            self.loadingViews[viewNumber].stopAnimating()
            self.loadingViews[viewNumber].hidden = true
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
        case "worddistance.html":
            transformDataForWorddistance(webView)
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
        //println(treemapData)
        
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

        //println(script9)
        
        //var treeScript = "var data7 = '{\"name\": \"all\",\"children\": [{\"name\": \"goblin\",\"children\": [{\"name\": \"goblin\", \"size\": 3938}]},{\"name\": \"demon\",\"children\": [{\"name\": \"demon\", \"size\": 6666}]},{\"name\": \"coffee\",\"children\": [{\"name\": \"coffee\", \"size\": 1777}]},{\"name\": \"cop\",\"children\": [{\"name\": \"cop\", \"size\": 743}]}]}'; renderChart(data7);"
        
        webView.stringByEvaluatingJavaScriptFromString(script9)
    }
    
    func reorderCirclepackingData(){
        circlepackingData.sort({$0[0] < $1[0]})
    }
    
    func transformDataForCirclepacking(webView: UIWebView){
        //println(circlepackingData)
        
        var script9 = "var data7 = '{\"name\": \" \",\"children\": ["
        
        var groupName : String = "uninitialized" // this isn't safe, there should be a better way
        
        for r in 0..<circlepackingData.count{
            if(groupName != circlepackingData[r][0]){
                // stop the group (unless it's the first one)
                if(groupName != "uninitialized"){
                    script9+="]},"
                }
                // new group
                groupName = circlepackingData[r][0]
                script9+="{\"name\": \""
                script9+=groupName
                script9+="\", \"children\": ["
            }
            else{
                //continue the group
                script9+=","
            }
            
            script9+="{\"name\": \""
            script9+=circlepackingData[r][1]
            script9+="\", \"size\":"
            script9+=circlepackingData[r][2]
            script9+="}"
        }
        script9+="]}]}'; renderChart(data7);"
        
        webView.stringByEvaluatingJavaScriptFromString(script9)
    }
    
    func transformDataForWorddistance(webView: UIWebView){
        //println(worddistanceData)
        
        var wordScript = "var myData = '{\"name\": \"cat\",\"children\": [{\"name\": \"feline\", \"distance\": 0.6, \"size\": 44},{\"name\": \"dog\", \"distance\": 0.4, \"size\": 22},{\"name\": \"bunny\", \"distance\": 0.0, \"size\": 10},{\"name\": \"gif\", \"distance\": 1.0, \"size\": 55},{\"name\": \"tail\", \"distance\": 0.2, \"size\": 88},{\"name\": \"fur\", \"distance\": 0.7, \"size\": 50}]}'; var w = \(webView.window!.frame.size.width); var h = \(webView.window!.frame.size.height); renderChart(myData,w,h);"
        
        webView.stringByEvaluatingJavaScriptFromString(wordScript)
    }

    func transformDataForTimemap(webView: UIWebView){
        
        //println(timemapData)
        
        var script9 = "var myData = [{\"key\": \"Tweet Count\", \"values\": ["
        
        for r in 0..<timemapData.count{
            script9+="{\"z\": \""
            script9+=timemapData[r][0]
            script9+="\", \"x\":\""
            script9+=timemapData[r][1]
            script9+="\", \"y\":"
            script9+=timemapData[r][2]
            script9+="}"
            if(r != (timemapData.count-1)){
                script9+=","
            }
        }
        script9+="]}]; renderChart(myData);"
        
        //println(script9)

        webView.stringByEvaluatingJavaScriptFromString(script9)
    }
    
    func transformDataForStackedbar(webView: UIWebView){
        
        //[["11/17","43","33"],["11/18","22", "22"],["11/19","22", "22"],["11/20","22", "22"],["11/21","22", "22"],["11/22","22", "22"],["11/23","22", "22"]]
        
        //println(stackedbarData)
        
        var script9 = "var myData = [{\"key\": \"Tweet Count\", \"values\": ["
        
        for r in 0..<stackedbarData.count{
            script9+="{\"x\": \""
            script9+=stackedbarData[r][0]
            script9+="\", \"y\":"
            script9+=stackedbarData[r][1]
            script9+=", \"z\":"
            script9+=stackedbarData[r][2]
            script9+="}"
            if(r != (stackedbarData.count-1)){
                script9+=","
            }
        }
        script9+="]}]; renderChart(myData);"
        
        //println(script9)

        //var script = "var myData = [{\"key\": \"Tweet Count\", \"values\": [  {\"x\":\"11/17\",\"y\":43, \"z\": 33},   {\"x\":\"11/18\",\"y\":22, \"z\": 22},   {\"x\":\"11/19\",\"y\":22, \"z\": 22},   {\"x\":\"11/20\",\"y\":33, \"z\": 11},    {\"x\":\"11/21\",\"y\":333, \"z\": 15},  {\"x\":\"11/22\",\"y\":44, \"z\": 23}, {\"x\":\"11/23\",\"y\":55, \"z\": 44} ] } ]; renderChart(myData);"
        
        webView.stringByEvaluatingJavaScriptFromString(script9)
    }
    
    func transformDataForWordcloud(webView: UIWebView){
        println("transformDataForWordcloud (not yet imp)")
    }

    

    //MARK: Clean WebViews
    func cleanWebViews()
    {
        for var i = 0; i < self.webViews.count; i++
        {
            //self.webViews[i].loadHTMLString("<HTML></HTML>", baseURL: nil)
            self.webViews[i].hidden = true
            self.loadingViews[i].startAnimating()
            self.loadingViews[i].hidden = false
        }
    }
    
}