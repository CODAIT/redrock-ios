//
//  LeftViewController.swift
//  RedRock
//
//  Created by Jonathan Alter on 9/29/15.
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
    
    @IBOutlet weak var foundTweetsTitleLabel: UILabel!
    @IBOutlet weak var foundUsersNumberLabel: UILabel!
    @IBOutlet weak var foundTweetsNumberLabel: UILabel!
    @IBOutlet weak var searchedTweetsNumberLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupTweetsTableView()
        // Do any additional setup after loading the view.
        
        switch Config.appState {
        case .Historic:
            foundTweetsTitleLabel.text = "Found Tweets"
        case .Live:
            foundTweetsTitleLabel.text = "Retweets"
        }
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
