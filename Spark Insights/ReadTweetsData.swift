//
//  ReadTweetsData.swift
//  Spark Insights
//
//  Created by Barbara Gomes on 5/28/15.
//  Copyright (c) 2015 IBM. All rights reserved.
//

import Foundation
import UIKit

class ReadTweetsData
{
    private class func getJSONFilePath() -> String?
    {
        let filePath = NSBundle.mainBundle().pathForResource("Tweets", ofType:"json")
        return filePath
    }
    
    // Read JSON file and get its content as NSDictionary if it is possible
    private class func getJSONSwift() -> NSData?
    {
        if let filePath = getJSONFilePath()
        {
            var readError:NSError?
            if let data = NSData(contentsOfFile:filePath,
                options: NSDataReadingOptions.DataReadingUncached,
                error:&readError)
            {
                return data
            }
            
        }
        return nil
    }
    
    class func readJSON() -> JSON?
    {
        if let fileData = ReadTweetsData.getJSONSwift()
        {
            var parseError: NSError?
            if let JSONObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(fileData, options: NSJSONReadingOptions.AllowFragments, error: &parseError)
            {
                let jsonTweets = JSON(JSONObject!)
                return jsonTweets["tweets"]
            }
        }
        
        return nil
    }
    
    private class func getTweetsObjects(tweets: JSON) ->  Array<TwitterTweet>?
    {
        var tweetsObj = Array<TwitterTweet>()
        for (var i = 0; i < tweets.array?.count; i++)
        {
            let user_name = tweets[i]["user"]["name"].stringValue
            let user_screen_name = tweets[i]["user"]["screen_name"].stringValue
            let user_profile_image = (tweets[i]["user"]["profile_image_url"].stringValue).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            let dateTime = tweets[i]["created_at"].stringValue
            let retweet_count = tweets[i]["retweet_count"].stringValue
            let favorite_count = tweets[i]["favorite_count"].stringValue
            let text = tweets[i]["text"].stringValue
            
            var tweet = TwitterTweet()
            tweet.setUserName(user_name)
            tweet.setUserhandle(user_screen_name, addAt: true)
            if (favorite_count == "")
            {
                tweet.setFavorites(0)
            }
            else
            {
                tweet.setFavorites(favorite_count.toInt()!)
            }
            if (retweet_count == "")
            {
                tweet.setRetweets(0)
            }
            else
            {
                tweet.setRetweets(retweet_count.toInt()!)
            }
            tweet.setTweetText(text)
            tweet.setDateTime(nil, stringFormat: "eee MMM dd HH:mm:ss ZZZZ yyyy", stringDate: dateTime)
            if let urlImage = NSURL(string: user_profile_image)
            {
                if let dataImage = NSData(contentsOfURL: urlImage){
                    tweet.setUserProfileImage(UIImage(data: dataImage)!)
                    
                }
            }
            tweetsObj.append(tweet)
        }
        return tweetsObj
    }

}