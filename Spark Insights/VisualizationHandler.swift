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
    
    var visualizationNames: [String] = [String]()
    var webViews : [UIWebView] = [UIWebView]()
    
    func getNumberOfVisualizations()->Int{
        return visualizationNames.count;
    }
    
    func reloadAppropriateView(viewNumber: Int){
        println("should reload \(viewNumber)")
        webViews[viewNumber].loadRequest(webViews[viewNumber].request!)

    }
    
    func transformDataForTreemapping(webView: UIWebView){
        println("transformDataForTreemapping: "+webView.request!.URL!.lastPathComponent!)
        
        var treeScript = "var data7 = '{\"name\": \"all\",\"children\": [{\"name\": \"zebra\",\"children\": [{\"name\": \"zebra\", \"size\": 3938}]},{\"name\": \"cop\",\"children\": [{\"name\": \"cop\", \"size\": 743}]}]}'; renderChart(data7);"
        
        webView.stringByEvaluatingJavaScriptFromString(treeScript)
    }
    
    func transformDataForCirclepacking(webView: UIWebView){
        println("transformDataForCirclepacking: "+webView.request!.URL!.lastPathComponent!)

        var treeScript = "var data7 = '{\"name\": \"all\",\"children\": [{\"name\": \"accountant\",\"children\": [{\"name\": \"accountant\", \"size\": 3938}]},{\"name\": \"cop\",\"children\": [{\"name\": \"cop\", \"size\": 743}]}]}'; renderChart(data7);"
        
        webView.stringByEvaluatingJavaScriptFromString(treeScript)
    }
    
    func transformDataForWorddistance(webView: UIWebView){
        println("transformDataForWorddistance: "+webView.request!.URL!.lastPathComponent!)
        
        //var script2 = "renderChart(\"blah\");"
        
        var wordScript = "var myData = '{\"name\": \"cat\",\"children\": [{\"name\": \"feline\", \"distance\": 0.6, \"size\": 44},{\"name\": \"dog\", \"distance\": 0.4, \"size\": 22},{\"name\": \"bunny\", \"distance\": 0.0, \"size\": 10},{\"name\": \"gif\", \"distance\": 1.0, \"size\": 55},{\"name\": \"tail\", \"distance\": 0.2, \"size\": 88},{\"name\": \"fur\", \"distance\": 0.7, \"size\": 50}]}'; renderChart(myData);"
        
        webView.stringByEvaluatingJavaScriptFromString(wordScript)
    }
    
    
    
}