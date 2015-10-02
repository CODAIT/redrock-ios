//
//  LeftViewController.swift
//  RedRock
//
//  Created by Jonathan Alter on 9/29/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import UIKit

@objc
protocol LeftViewControllerDelegate {
    optional func toggleLeftPanel()
}

class LeftViewController: UIViewController {

    weak var delegate: LeftViewControllerDelegate?
    
    var tweetsTableViewController: TweetsTableViewController!
    
    @IBOutlet weak var feedButton: UIButton!
    @IBOutlet weak var tweetTableHolder: UIView!
    
    @IBOutlet weak var foundUsersNumberLabel: UILabel!
    @IBOutlet weak var foundTweetsNumberLabel: UILabel!
    @IBOutlet weak var searchedTweetsNumberLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupTweetsTableView()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func feedButtonClicked(sender: UIButton) {
        delegate?.toggleLeftPanel!()
    }

    func setupTweetsTableView()
    {
        self.tweetsTableViewController = (self.storyboard?.instantiateViewControllerWithIdentifier("TweetsTableViewController") as?TweetsTableViewController)!

        addChildViewController(tweetsTableViewController)
        self.tweetsTableViewController.view.frame = CGRectMake(0, 0 , self.tweetTableHolder.frame.width, tweetTableHolder.frame.height);
        self.tweetTableHolder.addSubview(self.tweetsTableViewController.view)
        self.tweetsTableViewController.didMoveToParentViewController(self)
    }

    // MARK: - Animation callbacks
    func onAnimationStart() {
        self.feedButton.layer.opacity = 0;
    }
    
    func onAnimationComplete() {
        UIView.animateWithDuration(0.1, animations: {
            self.feedButton.layer.opacity = 1;
        })
    }
    
}
