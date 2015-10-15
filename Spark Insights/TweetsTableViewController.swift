//
//  TweetsTableViewController.swift
//  Spark Insights
//
//  Created by Barbara Gomes on 5/28/15.
//  Copyright (c) 2015 IBM. All rights reserved.
//

import UIKit
import Social

class TweetsTableViewController: UITableViewController, TweetTableViewCellDelegate{

    var tweets:JSON = []
    var openedTweetCell = Array<TweetTableViewCell>()
    var emptySearchResult = false
    var errorMessage: String?
    var twitterHashTagSearchURL = "https://twitter.com/search?src=typd&q="
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerNib(UINib(nibName: "TweetCell", bundle: nil), forCellReuseIdentifier: "TweetTableCellView")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Tweet Cell delegate
    
    func twitterBirdButtonClicked(clickedCell: TweetTableViewCell) {
        self.shareOnTwitter(clickedCell)
    }
    
    func cellDidOpen(openedCell: TweetTableViewCell) {
        if self.openedTweetCell.count == 1
        {
            self.openedTweetCell.removeAtIndex(0)
        }
        self.openedTweetCell.append(openedCell)
    }
    
    func cellDidClose(closedCell: TweetTableViewCell) {
        if self.openedTweetCell.count == 1
        {
            self.openedTweetCell.removeAtIndex(0)
        }
    }
    
    func cellDidBeginOpening(openingCell: TweetTableViewCell)
    {
        if self.openedTweetCell.count == 1
        {
            self.openedTweetCell[0].resetConstraintContstantsToZero(true, notifyDelegateDidClose: false)
        }
    }
    
    func didTappedURLInsideTweetText(tappedURL: String) {
        if let displayViewController = self.storyboard?.instantiateViewControllerWithIdentifier("TweetDisplayURL") as? DisplayUrlViewController
        {
            displayViewController.loadUrl = tappedURL
            self.presentViewController(displayViewController, animated: true, completion: nil)
        }
    }
    
    func didTappedHashtagInsideTweetText(tappedHash: String) {
        if let displayViewController = self.storyboard?.instantiateViewControllerWithIdentifier("TweetDisplayURL") as? DisplayUrlViewController
        {
            displayViewController.loadUrl = twitterHashTagSearchURL + tappedHash.stringByReplacingOccurrencesOfString("#",withString: "%23")
            self.presentViewController(displayViewController, animated: true, completion: nil)
        }
    }
    
    func userHandleClicked(clickedCell: TweetTableViewCell) {
        if let displayViewController = self.storyboard?.instantiateViewControllerWithIdentifier("TweetDisplayURL") as? DisplayUrlViewController
        {
            displayViewController.loadUrl = clickedCell.userProfileURL
            self.presentViewController(displayViewController, animated: true, completion: nil)
        }
    }
    
    
    //MARK: Twitter integration
    func shareOnTwitter(tweetCell: TweetTableViewCell)
    {
        if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter)
        {
            let tweetSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
            tweetSheet.setInitialText(tweetCell.userScreenName.titleLabel!.text)
            //tweetSheet.addImage(self.screenShot())
            self.presentViewController(tweetSheet, animated: true, completion: {
                tweetCell.twitterDetailImg.alpha = 1.0
            })
        }
        else
        {
            let alertController = UIAlertController(title: "RedRock", message:
                "No Twitter account available", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    func screenShot() -> UIImage
    {
        let layer = UIApplication.sharedApplication().keyWindow!.layer
        let scale = UIScreen.mainScreen().scale
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale);
        
        layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        UIImageWriteToSavedPhotosAlbum(screenshot, nil, nil, nil)
        return screenshot;
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tweets.count == 0
        {
            return 1
        }
        return tweets.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if tweets.count == 0
        {
            if errorMessage != nil
            {
                let emptySearch = self.tableView.dequeueReusableCellWithIdentifier("NoDataCell", forIndexPath: indexPath) 
                emptySearch.backgroundColor = Config.tweetsTableBackgroundColor
                let label = emptySearch.viewWithTag(500) as! UILabel
                label.text = errorMessage
                return emptySearch
            }
            else if emptySearchResult
            {
                let emptySearch = self.tableView.dequeueReusableCellWithIdentifier("NoDataCell", forIndexPath: indexPath) 
                emptySearch.backgroundColor = Config.tweetsTableBackgroundColor
                return emptySearch
            }
            else
            {
                let loadingCell = self.tableView.dequeueReusableCellWithIdentifier("LoadingCell", forIndexPath: indexPath) 
                loadingCell.backgroundColor = Config.tweetsTableBackgroundColor
                return loadingCell
            }
        }
        else
        {
            let tweetCell = self.tableView.dequeueReusableCellWithIdentifier("TweetTableCellView", forIndexPath: indexPath) as! TweetTableViewCell
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                let tweet = self.getTweetObject(indexPath.row)
                let user_profile_image = (self.tweets[indexPath.row]["user"]["profile_image_url"].stringValue).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                let timeToDisplay = tweet.getDateTimeToDisplay("MMM dd")
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    tweetCell.configureWithTweetData(tweet.getUserName(),
                        userScreenName: tweet.getUserHandle(),
                        tweetText: tweet.getTweetText(),
                        /*countFavorite: String(tweet.getFavoritesCount()),
                        countRetweet: String(tweet.getRetweetsCount()),*/
                        dateTime: timeToDisplay,
                        userProfileURL: tweet.getProfileURL(),
                        countFollowers: tweet.getFollowersCountToDisplay())
                })
        
                if let urlImage = NSURL(string: user_profile_image)
                {
                    if let dataImage = NSData(contentsOfURL: urlImage){
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            tweetCell.userProfileImage.image = UIImage(data: dataImage)!
                        })
                    }
                }
            })
            
            tweetCell.delegate = self
            tweetCell.rowIndex = indexPath.row
            return tweetCell
        }
    }
    
    func getTweetObject(row: Int) -> TwitterTweet
    {
        let user_name = tweets[row]["user"]["name"].stringValue
        let user_screen_name = tweets[row]["user"]["screen_name"].stringValue
        // let user_profile_image = (tweets[row]["user"]["profile_image_url"].stringValue).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        let dateTime = tweets[row]["created_at"].stringValue
        //let retweet_count = tweets[row]["retweet_count"].stringValue
        //let favorite_count = tweets[row]["favorite_count"].stringValue
        let followers_count = tweets[row]["user"]["followers_count"].stringValue
        let text = tweets[row]["text"].stringValue
        let userID = tweets[row]["user"]["id"].stringValue
        
        let tweet = TwitterTweet()
        tweet.setUserName(user_name)
        tweet.setUserhandle(user_screen_name, addAt: true)
        if (followers_count == "")
        {
            tweet.setFollowers(0)
        }
        else
        {
            tweet.setFollowers(Int(followers_count)!)
        }

        /*if (favorite_count == "")
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
        }*/
        tweet.setTweetText(text)
        tweet.setDateTime(nil, stringFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z", stringDate: dateTime)
        tweet.setUserID(userID)
        
        return tweet
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat{
        /*if tweets.count == 0
        {
            return 80
        }
        return TweetTableViewCell.calculateHeightForCell(CGFloat(count(tweets[indexPath.row]["text"].stringValue)), tableWidth: self.tableView.frame.width)*/
        return 240
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? TweetTableViewCell
        {
            // Do not call selection event when user taps a url
            if cell.isURLTapped
            {
                return nil
            }
        }
        return indexPath
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? TweetTableViewCell
        {
            cell.displayView.backgroundColor = UIColor.whiteColor()
        }
    }
    
    //Avoid conflict with swipe gesture recognizer
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

}
