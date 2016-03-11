//
//  ReadTweetsData.swift
//  Spark Insights
//
//  Created by Barbara Gomes on 5/28/15.
//

/**
* (C) Copyright IBM Corp. 2015, 2015
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*
*/

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
            do {
                let data = try NSData(contentsOfFile:filePath,
                    options: NSDataReadingOptions.DataReadingUncached)
                return data
            } catch let error as NSError {
                readError = error
            }
            
        }
        return nil
    }
    
    class func readJSON() -> JSON?
    {
        if let fileData = ReadTweetsData.getJSONSwift()
        {
            var parseError: NSError?
            do {
                let JSONObject: AnyObject? = try NSJSONSerialization.JSONObjectWithData(fileData, options: NSJSONReadingOptions.AllowFragments)
                let jsonTweets = JSON(JSONObject!)
                return jsonTweets["tweets"]
            } catch let error as NSError {
                parseError = error
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
            let dateTime = tweets[i]["created_at"].stringValue //todo check what this looks like
            let retweet_count = tweets[i]["retweet_count"].stringValue
            let favorite_count = tweets[i]["favorite_count"].stringValue
            let text = tweets[i]["text"].stringValue
            
            let tweet = TwitterTweet()
            tweet.setUserName(user_name)
            tweet.setUserhandle(user_screen_name, addAt: true)
            if (favorite_count == "")
            {
                tweet.setFavorites(0)
            }
            else
            {
                tweet.setFavorites(Int(favorite_count)!)
            }
            if (retweet_count == "")
            {
                tweet.setRetweets(0)
            }
            else
            {
                tweet.setRetweets(Int(retweet_count)!)
            }
            tweet.setTweetText(text)
            tweet.setDateTime(nil, stringFormat: Config.dateFormat, stringDate: dateTime)
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