//
//  Network.swift
//  Spark Insights
//
//  Created by Barbara Gomes on 6/5/15.
//  Copyright (c) 2015 IBM. All rights reserved.
//

import Foundation

protocol NetworkDelegate {
    func handleTweetsCallBack(json: JSON)
    func handleSentimentsCallBack(json: JSON)
    func handleLocationCallBack(json:JSON)
    func handleProfessionCallBack(json:JSON)
    func handleWordDistanceCallBack(json:JSON)
    func handleWordClusterCallBack(json:JSON)
    func handleRequestError(message: String)
    func requestsEnded(error: Bool)
}

class Network
{
    var delegate: NetworkDelegate?
    private var requestCount = 0
    private var requestTotal = 0
    private var error = false
    
    // MARK: Call Requests
    
    func getDataFromServer(include: String, exclude:String)
    {
        var customAllowedSet =  NSCharacterSet(charactersInString:"=\"#%/<>?@\\^`{|}").invertedSet
        var encodeInclude = include.stringByAddingPercentEncodingWithAllowedCharacters(customAllowedSet)
        var encodeExclude = exclude.stringByAddingPercentEncodingWithAllowedCharacters(customAllowedSet)

        self.executeTweetRequest(encodeInclude!, exclude: encodeExclude!)
        self.executeSentimentRequest(encodeInclude!, exclude: encodeExclude!)
        self.executeLocationRequest(encodeInclude!, exclude: encodeExclude!)
        //self.executeWordClusterRequest(encodeInclude!, exclude: encodeExclude!) //not imp yet
        self.executeProfessionRequest(encodeInclude!, exclude: encodeExclude!)
        self.executeWordDistanceRequest(encodeInclude!, exclude: encodeExclude!)
    }
    
    //MARK: Data
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
        Log("executeWordDistanceRequest")
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
    
    //MARK: Call Delegates
    private func callTweetDelegate(json: JSON)
    {
        self.delegate?.handleTweetsCallBack(json)
    }
    
    private func callSentimentsDelegate(json: JSON)
    {
        self.delegate?.handleSentimentsCallBack(json)
    }

    private func callLocationDelegate(json: JSON)
    {
        self.delegate?.handleLocationCallBack(json)
    }
    
    private func callProfessionDelegate(json: JSON)
    {
        self.delegate?.handleProfessionCallBack(json)
    }
    
    private func callWordDistanceDelegate(json: JSON)
    {
        println("callWordDistanceDelegate")
        self.delegate?.handleWordDistanceCallBack(json)
    }
    
    private func callWordClusterDelegate(json: JSON)
    {
        self.delegate?.handleWordClusterCallBack(json)
    }


    //MARK: Server
    private func createRequest(serverPath: String, paremeters: Dictionary<String,String>) -> String{
        Log("createRequest")
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
            var aux = Array(urlPath)
            aux.removeLast()
            urlPath = String(aux)
        }
        return urlPath
    }
    

    private func executeRequest(req: String, callBack: (json: JSON) -> ()) {
        //var escapedAddress = req.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        
        Log("Sending Request: " + req)
        let url: NSURL = NSURL(string: req)!
        let session = NSURLSession.sharedSession()
        session.configuration.timeoutIntervalForRequest = 300
        
        let task = session.dataTaskWithURL(url, completionHandler: {data, response, error -> Void in
            self.requestCount++
            
            if let httpResponse = response as? NSHTTPURLResponse
            {
                if httpResponse.statusCode != 200
                {
                    Log(NSString(data: data, encoding: NSUTF8StringEncoding)!)
                    self.requestError("Server Error. Code \(httpResponse.statusCode)")
                    return
                }
            }
            
            if error != nil {
                // If there is an error in the web request, print it to the console
                Log(error.localizedDescription)
                self.requestError(error.localizedDescription)
                return
            }
            
            var err: NSError?
            var jsonResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err) as! NSDictionary
            if err != nil {
                // If there is an error parsing JSON, print it to the console
                self.requestError("JSON Error \(err!.localizedDescription)")
                Log("JSON Error \(err!.localizedDescription)")
                return
            }
            
            let json = JSON(jsonResult)
            let status = json["status"].intValue
            
            if( status == 1 ) {
                let msg = json["message"].stringValue
                self.requestError("Error: " + msg)
                Log("Error: " + msg)
                return
            }
            
            // Success
            Log("Request completed: Status = OK")
            
            dispatch_async(dispatch_get_main_queue(), {
                if self.requestCount == self.requestTotal
                {
                    self.delegate?.requestsEnded(self.error)
                }
                // Success on main thread
                callBack(json: json)
            }) 
        })
        task.resume()
    }
    
    private func requestError(message: String)
    {
        self.error = true
        dispatch_async(dispatch_get_main_queue(), {
            self.delegate?.handleRequestError(message)
            if self.requestCount == self.requestTotal
            {
                self.delegate?.requestsEnded(self.error)
            }
        })
    }

}