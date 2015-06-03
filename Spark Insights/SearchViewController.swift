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

class SearchViewController: UIViewController, UITextFieldDelegate {

    weak var delegate: SearchViewControllerDelegate?
    
    @IBOutlet weak var imageTitleTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageSearchTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var appImageTitle: UILabel!
    @IBOutlet weak var appTitleTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var AppTitleView: UIView!
    @IBOutlet weak var appTitleLabel: UILabel!
    @IBOutlet weak var searchHolderView: UIView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var topImageView: UIImageView!
    @IBOutlet weak var searchHolderTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var searchHolderBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var searchButtonView: UIView!
    
    private var recalculateConstrainstsForSearchView = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textField.delegate = self
        setInsetTextField()
        addGestureRecognizerSearchView()
    }
    
    func addGestureRecognizerSearchView()
    {
        let tapGesture = UILongPressGestureRecognizer(target: self, action: "searchClicked:")
        tapGesture.minimumPressDuration = 0.001
        self.searchButtonView.addGestureRecognizer(tapGesture)
        self.searchButtonView.userInteractionEnabled = true
    }
    
    // Text leading space
    func setInsetTextField()
    {
        self.textField.layer.sublayerTransform = CATransform3DMakeTranslation(20, 0, 0);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == self.textField
        {
            self.searchButtonView.alpha = 0.5
            self.searchClicked(nil)
            return true
        }
        
        return false
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
        if self.recalculateConstrainstsForSearchView
        {
            recalculateConstraintsForAnimation()
            UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                self.view.layoutIfNeeded()
                }, completion: nil)
            self.textField.font = UIFont (name: "Helvetica Neue", size: 17)
            self.recalculateConstrainstsForSearchView = false
        }
    }
    
    func recalculateConstraintsForAnimation()
    {
        self.imageSearchTopConstraint.constant = -self.topImageView.frame.height
        self.imageTitleTopConstraint.constant = -self.topImageView.frame.height
        self.AppTitleView.hidden = false
        self.appTitleLabel.hidden = false
        self.appTitleTopConstraint.constant = -UIApplication.sharedApplication().statusBarFrame.height
        self.searchHolderTopConstraint.constant = self.AppTitleView.frame.height
        self.searchHolderBottomConstraint.constant = self.searchHolderView.frame.height + (self.topImageView.frame.height - self.searchHolderView.frame.height) - self.AppTitleView.frame.height
    }
    
    func searchClicked(gesture: UIGestureRecognizer?) {
        let searchText = self.textField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        if searchText != ""
        {
            var state = UIGestureRecognizerState.Ended
            if gesture != nil
            {
                state = gesture!.state
            }
            if state == UIGestureRecognizerState.Began
            {
                self.searchButtonView.alpha = 0.5
            }
            else if state == UIGestureRecognizerState.Ended
            {
                let containerViewController = ContainerViewController()
                containerViewController.searchText = searchText
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
        else
        {
            self.displayAlert("#SparkInsights", message: "No search parameters defined.")
            self.searchButtonView.alpha = 1.0
        }
    }
    
    func displayAlert(title: String, message: String)
    {
        
        let alertController = UIAlertController(title: title, message:
            message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
}
