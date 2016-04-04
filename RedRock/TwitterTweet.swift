//
//  TwitterTweet.swift
//  RedRock
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

class TwitterTweet
{
    private var userName: String = ""
    private var userHandle: String = ""
    private var userProfileImage: UIImage = UIImage()
    private var favoriteCount: Int = 0
    private var retweetCount: Int = 0
    private var tweetText: String = ""
    private var dateTime: NSDate = NSDate()
    private let twitterUserProfileURLbyID = "https://twitter.com/intent/user?user_id="
    private let timeInterval = NSTimeInterval(NSTimeZone.localTimeZone().secondsFromGMT)
    private let seconsToDisplayDate = NSTimeInterval(82800)
    private let displayDateFormat = "MMM dd"
    private var userID:String = ""
    private var followersCount: Int = 0
    
    func setUserID(userID: String)
    {
        self.userID = userID
    }
    
    func setUserName(userName: String)
    {
        self.userName = userName
    }
    
    func setUserhandle(userHandle: String, addAt: Bool)
    {
        if addAt
        {
            self.userHandle = "@" + userHandle
        }
        else
        {
            self.userHandle = userHandle
        }
    }
    
    func setUserProfileImage(profileImage: UIImage)
    {
        self.userProfileImage = profileImage
    }
    
    func setFavorites(count: Int)
    {
        self.favoriteCount = count
    }
    
    func setRetweets(count: Int)
    {
        self.retweetCount = count
    }
    
    func setFollowers(count: Int)
    {
        self.followersCount = count
    }
    
    func setTweetText(tweetText:String)
    {
        self.tweetText = tweetText
    }
    
    func setDateTime(dateTime:NSDate?, stringFormat: String?, stringDate: String?)
    {
        if dateTime == nil
        {
            self.transformTweetDateTime(stringDate!, stringFormat: stringFormat!)
        }
        else
        {
            self.dateTime = dateTime!
        }
    }
    
    func transformTweetDateTime(dateTimeString: String, stringFormat: String)
    {
        let dateFormat = NSDateFormatter()
        dateFormat.dateFormat = stringFormat
        dateFormat.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        let dateTime = dateFormat.dateFromString(dateTimeString)
        let localDateTime = dateTime?.dateByAddingTimeInterval(self.timeInterval)
        
        if let myDateTime = localDateTime{ //check for nil
            self.dateTime = myDateTime
        }
        else{
            Log("ERROR: DATETIME WASN'T FORMATTED CORRECTLY in transformTweetDateTime... stringFormat: \(stringFormat)... dateTimeString: \(dateTimeString)")
            self.dateTime = NSDate(timeIntervalSince1970: NSTimeInterval())
        }
    }
    
    func getUserName() -> String
    {
        return self.userName
    }
    
    func getUserHandle() -> String
    {
        return self.userHandle
    }
    
    func getProfileImage() -> UIImage
    {
        return self.userProfileImage
    }
    
    func getRetweetsCount() -> Int
    {
        return self.retweetCount
    }
    
    func getFavoritesCount() -> Int
    {
        return self.favoriteCount
    }
    
    func getTweetText() -> String
    {
        return self.tweetText
    }
    
    func getDateTimeToDisplay(dateFormatString: String) -> String
    {
        let currentDate = NSDate()
        let localCurrentDate = currentDate.dateByAddingTimeInterval(self.timeInterval)
        let secondsFromNow = localCurrentDate.timeIntervalSinceDate(self.dateTime)
        let dateFormat = NSDateFormatter()
        if secondsFromNow > self.seconsToDisplayDate
        {
            dateFormat.dateFormat = dateFormatString//self.displayDateFormat
            return dateFormat.stringFromDate(self.dateTime)
        }
        else
        {
            let seconds = Int(secondsFromNow % 60)
            let minutes = Int((secondsFromNow / 60) % 60)
            let hours = Int((secondsFromNow / 3600))
            
            var stringTime = ""
            if hours > 0
            {
                stringTime = String(hours) + " hr"
            }
            else if minutes > 0
            {
                stringTime = String(minutes) + " min"
            }
            else
            {
                stringTime = String(seconds) + " sec"
            }
            
            return stringTime
        }
    }
    
    func getProfileURL() -> String
    {
        return (self.twitterUserProfileURLbyID + self.userID)
    }
    
    func getFollowersCountToDisplay() -> String
    {
        let billion = 999999999
        let million = 999999
        let thousand = 999
        var div = 0.0
        var letter = ""
        if self.followersCount > billion
        {
            div = Double(self.followersCount)/Double((billion+1))
            letter = "B"
        }
        else if self.followersCount > million
        {
            div = Double(self.followersCount)/Double((million+1))
            letter = "M"
        }
        else if self.followersCount > thousand
        {
            div = Double(self.followersCount)/Double((thousand+1))
            letter = "K"
        }
        else
        {
            return String(self.followersCount)
        }
        
        return String(format: "%.1f", div) + String(letter)
    }
}