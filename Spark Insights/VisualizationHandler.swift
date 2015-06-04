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
    
    var treemapData : JSON       = nil
    var circlepackingData : JSON = nil
    var worddistanceData : JSON  = nil
    var timemapData : JSON       = nil
    var stackedbarData : JSON    = nil
            
    func reloadAppropriateView(viewNumber: Int){
        println("should reload \(viewNumber)")
        
        if(viewNumber >= 0 && viewNumber < Config.getNumberOfVisualizations()){
            webViews[viewNumber].scalesPageToFit = Config.scalePagesToFit[viewNumber]
            webViews[viewNumber].loadRequest(webViews[viewNumber].request!)
        }
        
    }
    func transformData(webView: UIWebView){
        // uses the path to determine which function to use
        switch webView.request!.URL!.lastPathComponent!{
        case "treemap.html":
            transformDataForTreemapping(webView)
        case "circlepacking.html":
            transformDataForCirclepacking(webView)
        case "worddistance.html":
            transformDataForWorddistance(webView)
        case "timemap.html":
            transformDataForTimemap(webView)
        case "stackedbar.html":
            transformDataForStackedbar(webView)
        default:
            break
        }
        
    }
    
    func transformDataForTreemapping(webView: UIWebView){
        println(treemapData)
        
        var treeScript = "var data7 = '{\"name\": \"all\",\"children\": [{\"name\": \"goblin\",\"children\": [{\"name\": \"goblin\", \"size\": 3938}]},{\"name\": \"demon\",\"children\": [{\"name\": \"demon\", \"size\": 6666}]},{\"name\": \"coffee\",\"children\": [{\"name\": \"coffee\", \"size\": 1777}]},{\"name\": \"cop\",\"children\": [{\"name\": \"cop\", \"size\": 743}]}]}'; renderChart(data7);"
        
        webView.stringByEvaluatingJavaScriptFromString(treeScript)
    }
    
    func transformDataForCirclepacking(webView: UIWebView){
        println(circlepackingData)

        //var script = "var data7 = '{\"name\": \"all\",\"children\": [{\"name\": \"accountant\",\"children\": [{\"name\": \"accountant\", \"size\": 3938}]},{\"name\": \"cop\",\"children\": [{\"name\": \"cop\", \"size\": 743}]}]}'; renderChart(data7);"

        JSON("")
        
        struct NameSize{
            var name = ""
            var size = 0
        }
        
        var dataStructure = [[NameSize]]()
        
        
        
        var script = "var data7 = '{\"name\": \" \",\"children\": [{\"name\": \"1\",\"children\": [{\"name\": \":)\", \"size\": 3938},{\"name\": \"happy\", \"size\": 3812},{\"name\": \"caturday\", \"size\": 40999},{\"name\": \"good\", \"size\": 6714},{\"name\": \"cheers\", \"size\": 3812},{\"name\": \"congrats!\", \"size\": 6714},{\"name\": \"sweet!\", \"size\": 2143}]},{\"name\": \"2\",\"children\": [{\"name\": \"love\", \"size\": 3534},{\"name\": \"iloveyou\", \"size\": 5731},{\"name\": \"justin\", \"size\": 7840},{\"name\": \"smiling\", \"size\": 5914},{\"name\": \"joy!\", \"size\": 3416}]},{\"name\": \"3\",\"children\": [{\"name\": \":(\", \"size\": 3938},{\"name\": \"sad\", \"size\": 3812},{\"name\": \"sorry\", \"size\": 6714},{\"name\": \"miss\", \"size\": 6714},{\"name\": \"bad\", \"size\": 3812},{\"name\": \"heartbroken\", \"size\": 6714},{\"name\": \"pain\", \"size\": 2243},{\"name\": \"sick\", \"size\": 2443}]}]}'; renderChart(data7);"

        
        
        
        
        //var script2 = "var data7 = "{\"name\": \" \",\"children\": [{\"name\"

        
        
        //var script = "renderChart(\"blah\");"
    
        webView.stringByEvaluatingJavaScriptFromString(script)
    }
    
    func transformDataForWorddistance(webView: UIWebView){
        println(worddistanceData)

        //var script2 = "renderChart(\"blah\");"
        
        var wordScript = "var myData = '{\"name\": \"cat\",\"children\": [{\"name\": \"feline\", \"distance\": 0.6, \"size\": 44},{\"name\": \"dog\", \"distance\": 0.4, \"size\": 22},{\"name\": \"bunny\", \"distance\": 0.0, \"size\": 10},{\"name\": \"gif\", \"distance\": 1.0, \"size\": 55},{\"name\": \"tail\", \"distance\": 0.2, \"size\": 88},{\"name\": \"fur\", \"distance\": 0.7, \"size\": 50}]}'; var w = \(webView.window!.frame.size.width); var h = \(webView.window!.frame.size.height); renderChart(myData,w,h);"
        
        webView.stringByEvaluatingJavaScriptFromString(wordScript)
    }

    func transformDataForTimemap(webView: UIWebView){
        
        println(timemapData)
        
        var timemapScript = "var myData = '{\"name\": \"cat\",\"children\": [{\"name\": \"feline\", \"distance\": 0.6, \"size\": 44},{\"name\": \"dog\", \"distance\": 0.4, \"size\": 22},{\"name\": \"bunny\", \"distance\": 0.0, \"size\": 10},{\"name\": \"gif\", \"distance\": 1.0, \"size\": 55},{\"name\": \"tail\", \"distance\": 0.2, \"size\": 88},{\"name\": \"fur\", \"distance\": 0.7, \"size\": 50}]}'; var w = \(webView.window!.frame.size.width); var h = \(webView.window!.frame.size.height); renderChart(myData);"
        
        webView.stringByEvaluatingJavaScriptFromString(timemapScript)
    }
    
    func transformDataForStackedbar(webView: UIWebView){
                
        println(stackedbarData)
        
        //var script = "var myData = '{\"name\": \"cat\",\"children\": [{\"name\": \"feline\", \"distance\": 0.6, \"size\": 44},{\"name\": \"dog\", \"distance\": 0.4, \"size\": 22},{\"name\": \"bunny\", \"distance\": 0.0, \"size\": 10},{\"name\": \"gif\", \"distance\": 1.0, \"size\": 55},{\"name\": \"tail\", \"distance\": 0.2, \"size\": 88},{\"name\": \"fur\", \"distance\": 0.7, \"size\": 50}]}'; var w = \(webView.window!.frame.size.width); var h = \(webView.window!.frame.size.height); renderChart(myData);"
        
        var script = "var myData = [{\"key\": \"Tweet Count\", \"values\": [  {\"x\":\"11/17\",\"y\":43, \"z\": 33},   {\"x\":\"11/18\",\"y\":22, \"z\": 22},   {\"x\":\"11/19\",\"y\":22, \"z\": 22},   {\"x\":\"11/20\",\"y\":33, \"z\": 11},    {\"x\":\"11/21\",\"y\":333, \"z\": 15},  {\"x\":\"11/22\",\"y\":44, \"z\": 23}, {\"x\":\"11/23\",\"y\":55, \"z\": 44} ] } ]; renderChart(myData);"
        
        //var script = "renderChart(myData);"

        
        webView.stringByEvaluatingJavaScriptFromString(script)
    }
    

    
    
}