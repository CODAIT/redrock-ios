//
//  TwitterTweet.swift
//  Spark Insights
//
//  Created by Barbara Gomes on 5/28/15.
//  Copyright (c) 2015 IBM. All rights reserved.
//

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
        var dateFormat = NSDateFormatter()
        dateFormat.dateFormat = stringFormat
        dateFormat.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        var dateTime = dateFormat.dateFromString(dateTimeString)
        var localDateTime = dateTime?.dateByAddingTimeInterval(self.timeInterval)
        self.dateTime = localDateTime!
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
        var secondsFromNow = localCurrentDate.timeIntervalSinceDate(self.dateTime)
        var dateFormat = NSDateFormatter()
        if secondsFromNow > self.seconsToDisplayDate
        {
            dateFormat.dateFormat = self.displayDateFormat
            return dateFormat.stringFromDate(self.dateTime)
        }
        else
        {
            var seconds = Int(secondsFromNow % 60)
            var minutes = Int((secondsFromNow / 60) % 60)
            var hours = Int((secondsFromNow / 3600))
            
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
}