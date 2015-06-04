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
    optional func displayContainerViewController(currentViewController: UIViewController, searchText: String)
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
    
    @IBOutlet weak var searchTextFieldHeightConstraint: NSLayoutConstraint!
    
    private var recalculateConstrainstsForSearchView = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textField.delegate = self
        setInsetTextField()
        addGestureRecognizerSearchView()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.resetViewController()
    }
    
    // MARK: - Reset UI
    
    func resetViewController() {
        // Use this function to reset the view controller's UI to a clean state
        println("Resetting \(__FILE__)")
        self.textField.text = ""
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
        var searchText = self.textField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        searchText = searchText.stringByReplacingOccurrencesOfString(" ", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        
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
            if searchText != ""
            {
                delegate?.displayContainerViewController?(self, searchText: searchText)
            }
            else
            {
                self.searchButtonView.alpha = 1.0
                let animation = CABasicAnimation(keyPath: "position")
                animation.duration = 0.07
                animation.repeatCount = 2
                animation.autoreverses = true
                animation.fromValue = NSValue(CGPoint: CGPointMake(self.textField.center.x - 10, self.textField.center.y))
                animation.toValue = NSValue(CGPoint: CGPointMake(self.textField.center.x + 10, self.textField.center.y))
                self.textField.layer.addAnimation(animation, forKey: "position")
            }
        }
    
    }

}
