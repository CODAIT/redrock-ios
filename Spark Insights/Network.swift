//
//  Network.swift
//  Spark Insights
//
//  Created by Barbara Gomes on 6/5/15.
//  Copyright (c) 2015 IBM. All rights reserved.
//

import Foundation

protocol NetworkDelegate {
    func handleTweetsCallBack(json: JSON?, error: NSError?)
    func handleSentimentsCallBack(json: JSON?, error: NSError?)
    func handleLocationCallBack(json:JSON?, error: NSError?)
    func handleProfessionCallBack(json:JSON?, error: NSError?)
    func handleWordDistanceCallBack(json:JSON?, error: NSError?)
    func handleWordClusterCallBack(json:JSON?, error: NSError?)
    func handleWorldCloudCallBack(json:JSON?, error: NSError?)
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
        self.executeWorldCloudRequest()
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
    
    private func executeWorldCloudRequest()
    {
        var parameters = Dictionary<String,String>()
        parameters["user"] = "hao"
        let req = self.createRequest(Config.serverWorldcloudPath, paremeters: parameters)
        executeRequest(req, callBack: self.callWorldCloudDelegate)
    }
    
    //MARK: Call Delegates
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
    
    private func callWorldCloudDelegate(json: JSON?, error: NSError?)
    {
        self.delegate?.handleWorldCloudCallBack(json, error: error)
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
    

    private func executeRequest(req: String, callBack: (json: JSON?, error: NSError?) -> ()) {
        //var escapedAddress = req.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        
        Log("Sending Request: " + req)
        let url: NSURL = NSURL(string: req)!
        let session = NSURLSession.sharedSession()
        session.configuration.timeoutIntervalForRequest = 300
        
        let task = session.dataTaskWithURL(url, completionHandler: {data, response, error -> Void in
            self.requestCount++
            
            func callbackOnMainThread(json: JSON?, error: NSError?) {
                dispatch_async(dispatch_get_main_queue(), {
                    callBack(json: json, error: error)
                })
            }
            
            if error != nil {
                // There was an error in the network request
                Log("Error: \(error.localizedDescription)")
                
                callbackOnMainThread(nil, error)
                return
            }
            
            var err: NSError?
            
            if let httpResponse = response as? NSHTTPURLResponse
            {
                if httpResponse.statusCode != 200
                {
                    Log(NSString(data: data, encoding: NSUTF8StringEncoding)!)
                    
                    var errorDesc = "Server Error. Status Code: \(httpResponse.statusCode)"
                    err =  NSError(domain: "Network", code: 0, userInfo: [NSLocalizedDescriptionKey: errorDesc])
                    callbackOnMainThread(nil, err)
                    return
                }
            }
            
            var jsonResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err) as! NSDictionary
            if err != nil {
                // There was an error parsing JSON
                Log("JSON Error: \(err!.localizedDescription)")
                
                callbackOnMainThread(nil, err)
                return
            }
            
            let json = JSON(jsonResult)
            let status = json["status"].intValue
            
            if( status == 1 ) {
                let msg = json["message"].stringValue
                let errorDesc = "Error: " + msg
                Log(errorDesc)
                
                err =  NSError(domain: "Network", code: 0, userInfo: [NSLocalizedDescriptionKey: msg])
                callbackOnMainThread(nil, err)
                return
            }
            
            // Success
            Log("Request completed: Status = OK")
            
            callbackOnMainThread(json, nil)
        })
        task.resume()
    }
}