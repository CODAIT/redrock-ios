//
//  Network.swift
//  Spark Insights
//
//  Created by Barbara Gomes on 6/5/15.
//  Copyright (c) 2015 IBM. All rights reserved.
//

import Foundation
import QuartzCore
import UIKit

protocol NetworkDelegate {
    func handleTweetsCallBack(json: JSON?, error: NSError?)
    func handleSentimentsCallBack(json: JSON?, error: NSError?)
    func handleLocationCallBack(json:JSON?, error: NSError?)
    func handleProfessionCallBack(json:JSON?, error: NSError?)
    func handleWordDistanceCallBack(json:JSON?, error: NSError?)
    func handleWordClusterCallBack(json:JSON?, error: NSError?)
    //func handleWordCloudCallBack(json:JSON?, error: NSError?)
    func handleTopMetrics(json:JSON?, error: NSError?)
    func displayRequestTime(time: String)
    func responseProcessed()
}

class Network
{
    static let sharedInstance = Network()
    
    var delegate: NetworkDelegate?
    static var waitingForResponse = false
    private var requestCount = 0
    private var requestTotal = 0
    private var error = false
    private var startTime = CACurrentMediaTime()
    // MARK: Call Requests
    
    func sentimentAnalysisRequest(searchText: String, sentiment: SentimentTypes, startDatetime: String, endDatetime: String, callBack: (json: JSON?, error: NSError?) -> ()) {

        if(Config.useDummyData){
            callCallbackAfterDelay("{\"name\": \" \",\"children\": [{\"name\": \"0\", \"children\": [{\"name\": \"Cats\", \"size\":236},{\"name\": \"RT\", \"size\":166},{\"name\": \"cats\", \"size\":134},{\"name\": \"amp;\", \"size\":105},{\"name\": \"CATS\", \"size\":57}]},{\"name\": \"1\", \"children\": [{\"name\": \"cats\", \"size\":224},{\"name\": \"like\", \"size\":177},{\"name\": \"pretty\", \"size\":147},{\"name\": \"its\", \"size\":136},{\"name\": \"hilarious.\", \"size\":120}]},{\"name\": \"2\", \"children\": [{\"name\": \"cats\", \"size\":678},{\"name\": \"RT\", \"size\":401},{\"name\": \"like\", \"size\":271},{\"name\": \"love\", \"size\":185},{\"name\": \"cat\", \"size\":90}]}]}", error: nil, callback: callBack)
            return
        }
        
        // http://bdavm155.svl.ibm.com:16666/ss/sentiment/analysis?user=barbara&termsInclude=love&termsExclude=&top=100&sentiment=1&startDatetime=2015-08-01T00:00:00Z&endDatetime=2015-11-10T23:59:59Z
        
        let encode = encodeIncludExcludeFromString(searchText)
        
        var sentimentString: String
        switch sentiment {
        case .Positive:
            sentimentString = "1"
        case .Negitive:
            sentimentString = "0"
        }
        
        var parameters = Dictionary<String,String>()
        parameters["user"] = "ssdemo"
        parameters["termsInclude"] = encode.include
        parameters["termsExclude"] = encode.exclude
        parameters["top"] = Config.tweetsTopParameter
        parameters["sentiment"] = sentimentString
        parameters["startDatetime"] = startDatetime
        parameters["endDatetime"] = endDatetime
        let req = self.createRequest(Config.serverSentimentAnalysis, paremeters: parameters)
        executeRequest(req, callBack: callBack)
    }
    
    func searchRequest(searchText: String)
    {
        let encode = encodeIncludExcludeFromString(searchText)

        if (Config.serverMakeSingleRequest) {
            self.executeFullRequest(encode.include, exclude: encode.exclude)
        }
        else {
            self.executeTweetRequest(encode.include, exclude: encode.exclude)
            self.executeSentimentRequest(encode.include, exclude: encode.exclude)
            self.executeLocationRequest(encode.include, exclude: encode.exclude)
            self.executeWordClusterRequest(encode.include, exclude: encode.exclude) //not imp yet
            self.executeProfessionRequest(encode.include, exclude: encode.exclude)
            self.executeWordDistanceRequest(encode.include, exclude: encode.exclude)
            //self.executeWordCloudRequest()
            //TODO: Find out if we have specific request for top metrics
        }
    }
    
    func encodeIncludExcludeFromString(searchText: String) -> (include: String, exclude: String) {
        let search = self.getIncludeAndExcludeSeparated(searchText)
        let encode = encodeIncludExclude(search.include, exclude: search.exclude)
        return encode
    }
    
    func encodeIncludExclude(include: String, exclude: String) -> (include: String, exclude: String) {
        let customAllowedSet =  NSCharacterSet(charactersInString:"=\"#%/<>?@\\^`{|}").invertedSet
        let encodeInclude = include.stringByAddingPercentEncodingWithAllowedCharacters(customAllowedSet)
        let encodeExclude = exclude.stringByAddingPercentEncodingWithAllowedCharacters(customAllowedSet)
        
        return (encodeInclude!, encodeExclude!)
    }
    
    //MARK: Data
    private func executeFullRequest(include: String, exclude: String)
    {
        var parameters = Dictionary<String,String>()
        parameters["user"] = "ssdemo"
        parameters["termsInclude"] = include
        parameters["termsExclude"] = exclude
        parameters["top"] = Config.tweetsTopParameter
        let req = self.createRequest(Config.serverSearch, paremeters: parameters)
        executeRequest(req, callBack: self.callFullResponseDelegate)
    }
    
    private func executeTweetRequest(include: String, exclude: String)
    {
        var parameters = Dictionary<String,String>()
        parameters["user"] = "ssdemo"
        parameters["termsInclude"] = include
        parameters["termsExclude"] = exclude
        parameters["top"] = Config.tweetsTopParameter
        let req = self.createRequest(Config.serverTweetsPath, paremeters: parameters)
        executeRequest(req, callBack: self.callTweetDelegate)
    }
    
    private func executeSentimentRequest(include: String, exclude: String)
    {
        var parameters = Dictionary<String,String>()
        parameters["user"] = "ssdemo"
        parameters["termsInclude"] = include
        parameters["termsExclude"] = exclude
        let req = self.createRequest(Config.serverSentimentPath, paremeters: parameters)
        executeRequest(req, callBack: self.callSentimentsDelegate)
    }
    
    private func executeLocationRequest(include: String, exclude: String)
    {
        var parameters = Dictionary<String,String>()
        parameters["user"] = "ssdemo"
        parameters["termsInclude"] = include
        parameters["termsExclude"] = exclude
        let req = self.createRequest(Config.serverLocationPath, paremeters: parameters)
        executeRequest(req, callBack: self.callLocationDelegate)
    }
    
    private func executeProfessionRequest(include: String, exclude: String)
    {
        var parameters = Dictionary<String,String>()
        parameters["user"] = "ssdemo"
        parameters["termsInclude"] = include
        parameters["termsExclude"] = exclude
        let req = self.createRequest(Config.serverProfessionPath, paremeters: parameters)
        executeRequest(req, callBack: self.callProfessionDelegate)
    }
    
    private func executeWordDistanceRequest(include: String, exclude: String)
    {
        var parameters = Dictionary<String,String>()
        parameters["user"] = "ssdemo"
        parameters["termsInclude"] = include
        parameters["termsExclude"] = exclude
        parameters["top"] = Config.wordDistanceTopParameter
        let req = self.createRequest(Config.serverWorddistancePath, paremeters: parameters)
        executeRequest(req, callBack: self.callWordDistanceDelegate)
    }
    
    private func executeWordClusterRequest(include: String, exclude: String)
    {
        var parameters = Dictionary<String,String>()
        parameters["user"] = "ssdemo"
        parameters["termsInclude"] = include
        parameters["termsExclude"] = exclude
        parameters["cluster"] = Config.wordClusterClusterParameter
        parameters["word"] = Config.wordClusterWordParameter
        let req = self.createRequest(Config.serverWordclusterPath, paremeters: parameters)
        executeRequest(req, callBack: self.callWordClusterDelegate)
    }
    
    /*
    private func executeWordCloudRequest()
    {
        var parameters = Dictionary<String,String>()
        parameters["user"] = "hao"
        let req = self.createRequest(Config.serverWordcloudPath, paremeters: parameters)
        executeRequest(req, callBack: self.callWordCloudDelegate)
    }
    */
    
    //MARK: Call Delegates
    private func callFullResponseDelegate(json: JSON?, error: NSError?)
    {
        self.delegate?.handleTweetsCallBack(json, error: error)
        self.delegate?.handleSentimentsCallBack(json, error: error)
        self.delegate?.handleLocationCallBack(json, error: error)
        self.delegate?.handleProfessionCallBack(json, error: error)
        self.delegate?.handleWordDistanceCallBack(json, error: error)
        self.delegate?.handleWordClusterCallBack(json, error: error)
        //self.delegate?.handleWordCloudCallBack(json, error: error)
        self.delegate?.handleTopMetrics(json, error: error)
        self.delegate?.responseProcessed()
    }
    
    private func callTweetDelegate(json: JSON?, error: NSError?)
    {
        self.delegate?.handleTweetsCallBack(json, error: error)
    }
    
    private func callSentimentsDelegate(json: JSON?, error: NSError?)
    {
        self.delegate?.handleSentimentsCallBack(json, error: error)
    }

    private func callLocationDelegate(json: JSON?, error: NSError?)
    {
        self.delegate?.handleLocationCallBack(json, error: error)
    }
    
    private func callProfessionDelegate(json: JSON?, error: NSError?)
    {
        self.delegate?.handleProfessionCallBack(json, error: error)
    }
    
    private func callWordDistanceDelegate(json: JSON?, error: NSError?)
    {
        self.delegate?.handleWordDistanceCallBack(json, error: error)
    }
    
    private func callWordClusterDelegate(json: JSON?, error: NSError?)
    {
        self.delegate?.handleWordClusterCallBack(json, error: error)
    }
    
    /*
    private func callWordCloudDelegate(json: JSON?, error: NSError?)
    {
        self.delegate?.handleWordCloudCallBack(json, error: error)
    }
    */

    //MARK: Server
    private func createRequest(serverPath: String, paremeters: Dictionary<String,String>) -> String{
        //Log("createRequest")
        self.requestTotal += 1
        var urlPath:String = "\(Config.serverAddress)/\(serverPath)"
        if paremeters.count > 0
        {
            urlPath += "?"
            let keys = paremeters.keys
            for key in keys
            {
                urlPath += key + "=" + paremeters[key]! + "&"
            }
            var aux = Array(urlPath.characters)
            aux.removeLast()
            urlPath = String(aux)
        }
        return urlPath
    }
    

    private func executeRequest(req: String, callBack: (json: JSON?, error: NSError?) -> ()) {
        //var escapedAddress = req.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        
        Log("Sending Request: " + req)
        Network.waitingForResponse = true
        self.startTime = CACurrentMediaTime()
        let url: NSURL = NSURL(string: req)!
        let session = NSURLSession.sharedSession()
        session.configuration.timeoutIntervalForRequest = 300
        
        let task = session.dataTaskWithURL(url, completionHandler: {data, response, error -> Void in
            self.requestCount++
            
            func callbackOnMainThread(json: JSON?, error: NSError?) {
                dispatch_async(dispatch_get_main_queue(), {
                    Network.waitingForResponse = false
                    callBack(json: json, error: error)
                })
            }
            
            if Config.displayRequestTimer
            {
                let elapsedTime = CACurrentMediaTime() - self.startTime
                dispatch_async(dispatch_get_main_queue(), {
                    self.delegate?.displayRequestTime("\(elapsedTime)")
                })
            }
            if error != nil {
                // There was an error in the network request
                Log("Error: \(error!.localizedDescription)")
                
                callbackOnMainThread(nil, error: error)
                return
            }
            
            var err: NSError?
            
            if let httpResponse = response as? NSHTTPURLResponse
            {
                if httpResponse.statusCode != 200
                {
                    Log(NSString(data: data!, encoding: NSUTF8StringEncoding)!)
                    
                    let errorDesc = "Server Error. Status Code: \(httpResponse.statusCode)"
                    err =  NSError(domain: "Network", code: 0, userInfo: [NSLocalizedDescriptionKey: errorDesc])
                    callbackOnMainThread(nil, error: err)
                    return
                }
            }
            
            var jsonResult: AnyObject?
            do {
                jsonResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers)
            } catch let error as NSError {
                err = error
                jsonResult = nil
            } catch {
                fatalError()
            }
            if err != nil {
                // There was an error parsing JSON
                Log("JSON Error: \(err!.localizedDescription)")
                
                callbackOnMainThread(nil, error: err)
                return
            }
            
            let json = JSON(jsonResult as! NSDictionary)
            let status = json["status"].intValue
            
            if( status == 1 ) {
                let msg = json["message"].stringValue
                let errorDesc = "Error: " + msg
                Log(errorDesc)
                
                err =  NSError(domain: "Network", code: 0, userInfo: [NSLocalizedDescriptionKey: msg])
                callbackOnMainThread(nil, error: err)
                return
            }
            
            // Success
            Log("Request completed: Status = OK")
            
            callbackOnMainThread(json, error: nil)
        })
        task.resume()
    }
    
    // MARK: - Utils
    func getIncludeAndExcludeSeparated(searchText: String) -> (include: String, exclude: String)
    {
        let terms = searchText.componentsSeparatedByString(",")
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
    
    func callCallbackAfterDelay(json: JSON?, error: NSError?, callback: (json: JSON?, error: NSError?) -> ()) {
        let delay = Config.dummyDataDelay * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            Network.waitingForResponse = false
            callback(json: json, error: error)
        }
    }
    
}