//
//  SearchViewController.swift
//  Spark Insights
//
//  Created by Jonathan Alter on 5/28/15.
//  Copyright (c) 2015 IBM. All rights reserved.
//

import UIKit

@objc
protocol SearchViewControllerDelegate {
    optional func changeRootViewController(newRoot: UIViewController)
}

class SearchViewController: UIViewController {

    weak var delegate: SearchViewControllerDelegate?
    
    @IBOutlet weak var searchHolderView: UIView!
    @IBOutlet weak var searchHolderTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var textField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: Actions

    @IBAction func startedEditing(sender: UITextField) {
        println("START")
        searchHolderTopConstraint.constant = 0
    }
    
    @IBAction func searchClicked(sender: UIButton) {
        
        let containerViewController = ContainerViewController()
        // TODO: need some validation here
        containerViewController.searchText = textField.text
        
        // Animate the transition to the new view controller
        var tr = CATransition()
        tr.duration = 0.2
        tr.type = kCATransitionFade
        self.view.window!.layer.addAnimation(tr, forKey: kCATransition)
        self.presentViewController(containerViewController, animated: false, completion: {
            self.delegate?.changeRootViewController?(containerViewController)
        })
    }
}
