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
    
    func powertrackWordcountRequest(searchText: String, callBack: (json: JSON?, error: NSError?) -> ()) {
        
//        if(Config.useDummyData){
//            var dummyResponses = [
//                "{\"tweets\":[{\"created_at\":\"2015-09-01T02:28:37.000Z\",\"text\":\"RT @IBMbigdata: Why IBM is making a strategic bet on #Spark? #SparkInsight http://t.co/mOsyVw0CxP http://t.co/72OoNeBXUz\",\"user\":{\"name\":\"Teresa Rojas\",\"screen_name\":\"etrojasc\",\"followers_count\":276,\"id\":\"id:twitter.com:128277489\",\"profile_image_url\":\"https://pbs.twimg.com/profile_images/633973942370217984/8vd23SQR_normal.jpg\"}},{\"created_at\":\"2015-09-01T01:08:59.000Z\",\"text\":\"Florentino se gasta todo el dinero en los fichajes, por eso en el Madrid aún tienen computadores IBM con Windows 98. 😂\",\"user\":{\"name\":\"⭐️Pedro⭐️\",\"screen_name\":\"Pedritho_FCB\",\"followers_count\":2170,\"id\":\"id:twitter.com:2760376963\",\"profile_image_url\":\"https://pbs.twimg.com/profile_images/618125567162994688/q-UfYQOI_normal.jpg\"}},{\"created_at\":\"2015-09-01T02:22:42.000Z\",\"text\":\"IBM SELECTRIC II CORRECTING ELECTRIC TYPEWRITER WHITE TAN 70s VINTAGE TYPES LITE http://t.co/9pPwS33wZb http://t.co/q6ZYokaPFa\",\"user\":{\"name\":\"Lowell Eastwood\",\"screen_name\":\"LowellEastwoodk\",\"followers_count\":4,\"id\":\"id:twitter.com:3303728401\",\"profile_image_url\":\"https://pbs.twimg.com/profile_images/627601159096700928/qMghGjBr_normal.jpg\"}},{\"created_at\":\"2015-09-01T02:23:02.000Z\",\"text\":\"$IBM: Bullish analyst action by Argus Research on IBM: http://t.co/kriPNV1p8i http://t.co/jI67sX2Ubf\",\"user\":{\"name\":\"Analyst Actions\",\"screen_name\":\"AnalystActions\",\"followers_count\":111,\"id\":\"id:twitter.com:2341530906\",\"profile_image_url\":\"https://pbs.twimg.com/profile_images/601131382060945410/KYX9mWKS_normal.jpg\"}},{\"created_at\":\"2015-09-01T01:09:42.000Z\",\"text\":\"IBM secures five-year AU$450 million partnership with ANZ http://t.co/R6JrVjcXod\",\"user\":{\"name\":\"gadgeTTechs\",\"screen_name\":\"gadgeTTechs\",\"followers_count\":1100,\"id\":\"id:twitter.com:447706221\",\"profile_image_url\":\"https://pbs.twimg.com/profile_images/2961824515/8e9071696c6156065e3a76e60c723c3b_normal.jpeg\"}},{\"created_at\":\"2015-09-01T01:07:05.000Z\",\"text\":\"Ibm 000-015 audition: leOJhmfnV\",\"user\":{\"name\":\"NevillLayla\",\"screen_name\":\"NevillLayla\",\"followers_count\":110,\"id\":\"id:twitter.com:1220269800\",\"profile_image_url\":\"https://pbs.twimg.com/profile_images/3344437024/3e01a8bcec43b16cdd5af14f47c2d9cf_normal.jpeg\"}},{\"created_at\":\"2015-09-01T01:06:31.000Z\",\"text\":\"Business Development Representative (Inside Software Sales): IBM Canada Ltd. (Markham ON.. #twitter #jobs #eluta http://t.co/3b9HT6OCOy\",\"user\":{\"name\":\"Jobs for Tweeters\",\"screen_name\":\"Tweet__Jobs\",\"followers_count\":586,\"id\":\"id:twitter.com:253315737\",\"profile_image_url\":\"https://pbs.twimg.com/profile_images/1246633057/eluta_no_text_normal.png\"}},{\"created_at\":\"2015-09-05T04:56:47.000Z\",\"text\":\"RT @AnjneyaParashar: Gain actionable insights from your big data in the cloud using VoltDB and IBM Softlayer http://t.co/mlhalpG7RV http://…\",\"user\":{\"name\":\"CodeBreaker\",\"screen_name\":\"CodeBreaker004\",\"followers_count\":5,\"id\":\"id:twitter.com:3313424060\",\"profile_image_url\":\"https://abs.twimg.com/sticky/default_profile_images/default_profile_2_normal.png\"}},{\"created_at\":\"2015-09-05T04:57:03.000Z\",\"text\":\"RT @JoanneGariepy: Why the IBM and Box partnership is important for you and your industry, in 6 quotes: http://t.co/o1c92QxK1o  #IBMandBox …\",\"user\":{\"name\":\"Roni Romano\",\"screen_name\":\"RoniRomanoCRM\",\"followers_count\":163,\"id\":\"id:twitter.com:3015367605\",\"profile_image_url\":\"https://pbs.twimg.com/profile_images/562724917154557952/JfI18mTJ_normal.jpeg\"}},{\"created_at\":\"2015-09-01T02:25:29.000Z\",\"text\":\"RT @IBMbigdata: Why IBM is making a strategic bet on #Spark? #SparkInsight http://t.co/mOsyVw0CxP http://t.co/72OoNeBXUz\",\"user\":{\"name\":\"Ana Lucia Vargas\",\"screen_name\":\"Analuvargas10\",\"followers_count\":141,\"id\":\"id:twitter.com:2397976027\",\"profile_image_url\":\"https://pbs.twimg.com/profile_images/637253710591184897/JI2FKRVt_normal.jpg\"}}],\"wordCount\":[{\"word\":\"ibm\",\"count\":19},{\"word\":\":\",\"count\":11},{\"word\":\".\",\"count\":3},{\"word\":\"?\",\"count\":3},{\"word\":\"!\",\"count\":2}]}",
//                "{\"tweets\":[{\"created_at\":\"2015-09-01T00:59:59.000Z\",\"text\":\"Hurry, while they last! Get your free 45-day #IBM Spectrum Accelerate trial at  #VMworld, Booth 1645 #IBMVMworld  http://t.co/wzRjZX9CEQ\",\"user\":{\"name\":\"IBM Storage\",\"screen_name\":\"IBMStorage\",\"followers_count\":23402,\"id\":\"id:twitter.com:15999249\",\"profile_image_url\":\"https://pbs.twimg.com/profile_images/3779718046/249b1462ae77273fdfe0e141596f6f07_normal.jpeg\"}},{\"created_at\":\"2015-09-01T01:00:42.000Z\",\"text\":\"#ibm Rapidly develop Internet of Things apps with Docker Containers http://t.co/V0YDzWrpao via @developerWorks\",\"user\":{\"name\":\"Enrique de Nicolás ㋡\",\"screen_name\":\"enriquednicolas\",\"followers_count\":4666,\"id\":\"id:twitter.com:2207606742\",\"profile_image_url\":\"https://pbs.twimg.com/profile_images/529754503822581761/MQDjqCPL_normal.jpeg\"}}],\"wordCount\":[{\"word\":\"#ibm\",\"count\":2},{\"word\":\"!\",\"count\":1},{\"word\":\"#ibmvmworld\",\"count\":1},{\"word\":\"#vmworld\",\"count\":1},{\"word\":\",\",\"count\":1}]}"
//            ]
//            
//            let dummyResponse = dummyResponses[Int(arc4random_uniform(UInt32(dummyResponses.count)))]
//            callCallbackAfterDelay(dummyResponse, error: nil, callback: callBack)
//            return
//        }
        
        // http://bdavm155.svl.ibm.com:16666/ss/powertrack/wordcount?user=barbara&batchSize=100000&topTweets=10&topWords=5&termsInclude=%23ibm&termsExclude=
        /*
        user = iPad user
        batchSize = timeline in minutes to be consider at the search (startDate = date now - batchSize, endDate = date now)
        topTweets = amount of tweets to be returned
        topWords = amount of counted words to be returned
        termsInclude = terms to include in the search separated by comma
        termsExclude = terms to exclude in the search separated by comma
        */
        
        let encode = encodeIncludExcludeFromString(searchText)
        
        var parameters = Dictionary<String,String>()
        parameters["user"] = "ssdemo"
        parameters["termsInclude"] = encode.include
        parameters["termsExclude"] = encode.exclude
        parameters["batchSize"] = Config.liveBatchSize
        parameters["topTweets"] = Config.liveTopTweets
        parameters["topWords"] = Config.liveTopWords
        let req = self.createRequest(Config.serverPowertrackWordcount, paremeters: parameters)
        executeRequest(req, callBack: callBack)
    }
    
    func sentimentAnalysisRequest(searchText: String, sentiment: SentimentTypes, startDatetime: String, endDatetime: String, callBack: (json: JSON?, error: NSError?) -> ()) {

        
        
        if(Config.useDummyData){
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                
                let filePath = NSBundle.mainBundle().pathForResource("response_drilldown", ofType:"json")
                
                var readError:NSError?
                do {
                    let fileData = try NSData(contentsOfFile:filePath!,
                        options: NSDataReadingOptions.DataReadingUncached)
                    // Read success
                    var parseError: NSError?
                    do {
                        let JSONObject: AnyObject? = try NSJSONSerialization.JSONObjectWithData(fileData, options: NSJSONReadingOptions.AllowFragments)
                        // Parse success
                        let json = JSON(JSONObject!)
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.callCallbackAfterDelay(json, error: nil, callback: callBack)
                        })
                    } catch let error as NSError {
                        parseError = error
                        // Parse error
                        // TODO: handle error
                        Log("Error Parsing drilldown demo data: \(parseError?.localizedDescription)")
                    }
                } catch let error as NSError {
                    readError = error
                    // Read error
                    // TODO: handle error
                    Log("Error Reading drilldown demo data: \(readError?.localizedDescription)")
                } catch {
                    fatalError()
                }
                
            })

            return
        }
        
        
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