//
//  TweetsTableViewController.swift
//  Spark Insights
//
//  Created by Barbara Gomes on 5/28/15.
//  Copyright (c) 2015 IBM. All rights reserved.
//

import UIKit
import Social

class TweetsTableViewController: UITableViewController{

    var tweets = ReadTweetsData.readJSON()!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerNib(UINib(nibName: "TweetCell", bundle: nil), forCellReuseIdentifier: "TweetTableCellView")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK - Tweet URL clicked
    func displayTweetTappedURL(tappedURL: String)
    {
        if let displayViewController = self.storyboard?.instantiateViewControllerWithIdentifier("TweetDisplayURL") as? DisplayUrlViewController
        {
            displayViewController.loadUrl = tappedURL
            self.presentViewController(displayViewController, animated: true, completion: nil)
        }
    }
    
    //MARK - Twitter integration
    func shareOnTwitter(tweetCell: TweetTableViewCell)
    {
        if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter)
        {
            var tweetSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
            tweetSheet.setInitialText(tweetCell.userScreenName.text)
            //tweetSheet.addImage(self.screenShot())
            self.presentViewController(tweetSheet, animated: true, completion: nil)
        }
    }
    
    func screenShot() -> UIImage
    {
        UIGraphicsBeginImageContextWithOptions(UIScreen.mainScreen().bounds.size, false, 0);
        self.view.drawViewHierarchyInRect(view.bounds, afterScreenUpdates: true)
        var screenShootImage:UIImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return screenShootImage;
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tweets.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var tweetCell = self.tableView.dequeueReusableCellWithIdentifier("TweetTableCellView", forIndexPath: indexPath) as! TweetTableViewCell
        
        tweetCell.configureWithTweetData(tweets[indexPath.row].getProfileImage(),
            userName: tweets[indexPath.row].getUserName(),
            userScreenName: tweets[indexPath.row].getUserHandle(),
            tweetText: tweets[indexPath.row].getTweetText(),
            countFavorite: String(tweets[indexPath.row].getFavoritesCount()),
            countRetweet: String(tweets[indexPath.row].getRetweetsCount()),
            dateTime: tweets[indexPath.row].getDateTimeToDisplay("MMM dd HH:mm:ss"))
        
        
        tweetCell.rowIndex = indexPath.row
        tweetCell.displayTappedURL = self.displayTweetTappedURL
        tweetCell.actionOnClickImageDetail = self.shareOnTwitter
        println(tweetCell.backgroundColor)
        return tweetCell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat{
        return TweetTableViewCell.calculateHeightForCell(CGFloat(count( tweets[indexPath.row].getTweetText())), tableWidth: self.tableView.frame.width)
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
