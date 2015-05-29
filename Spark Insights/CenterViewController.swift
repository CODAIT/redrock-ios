//
//  ViewController.swift
//  Spark Insights
//
//  Created by Jonathan Alter on 5/27/15.
//  Copyright (c) 2015 IBM. All rights reserved.
//

import UIKit

@objc
protocol CenterViewControllerDelegate {
    optional func toggleRightPanel()
    optional func collapseSidePanels()
}

class CenterViewController: UIViewController {

    var delegate: CenterViewControllerDelegate?
    
    @IBOutlet weak var dummyView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var leftView: UIView!
    @IBOutlet weak var headerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.setupTweetsTableView()
        self.setupScrollView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupTweetsTableView()
    {
        if let tweetsController = self.storyboard?.instantiateViewControllerWithIdentifier("TweetsTableViewController") as?TweetsTableViewController
        {
            addChildViewController(tweetsController)
            let height = self.view.frame.height - self.footerView.frame.height - self.headerView.frame.height
            tweetsController.view.frame = CGRectMake(0, headerView.frame.height , self.leftView.frame.width, height);
            self.leftView.addSubview(tweetsController.view)
            tweetsController.didMoveToParentViewController(self)
        }
    }

    func setupScrollView() {
        var colors = [UIColor.blueColor(), UIColor.darkGrayColor(), UIColor.grayColor()]
        var numberOfViews = 3
        
        for i in 0..<numberOfViews {
            var myOrigin = CGFloat(i) * self.dummyView.frame.size.width
            
            var myView = UIView(frame: CGRectMake(myOrigin, 0, self.dummyView.frame.size.width, self.dummyView.frame.size.height))
            myView.backgroundColor = colors[i % numberOfViews]
            
            self.scrollView.addSubview(myView)
        }
        
        self.scrollView.contentSize = CGSizeMake(self.dummyView.frame.size.width * CGFloat(numberOfViews), self.dummyView.frame.size.height)
    }
    
    
    @IBAction func searchClicked(sender: UIButton) {
        delegate?.toggleRightPanel?()
    }
    
}

