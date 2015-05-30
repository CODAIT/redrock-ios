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
    @IBOutlet weak var searchImageView: UIImageView!
    
    private var recalculateConstrainstsForSearchView = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setInsetTextField()
        addGestureRecognizerSearchView()
    }
    
    func addGestureRecognizerSearchView()
    {
        let tapGesture = UITapGestureRecognizer(target: self, action: "searchClicked:")
        self.searchImageView.addGestureRecognizer(tapGesture)
        self.searchImageView.userInteractionEnabled = true
        self.searchButtonView.addGestureRecognizer(tapGesture)
        self.searchButtonView.userInteractionEnabled = true
    }
    
    func setInsetTextField()
    {
        self.textField.layer.sublayerTransform = CATransform3DMakeTranslation(20, 0, 0);
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
        self.topImageView.hidden = true
        self.AppTitleView.hidden = false
        self.appImageTitle.hidden = true
        self.appTitleLabel.hidden = false
        self.appTitleTopConstraint.constant = 0
        self.searchHolderTopConstraint.constant = self.AppTitleView.frame.height
        self.searchHolderBottomConstraint.constant = self.searchHolderView.frame.height + (self.topImageView.frame.height - self.searchHolderView.frame.height) - self.AppTitleView.frame.height
    }
    
    @IBAction func searchClicked(sender: UIButton) {
        
        let containerViewController = ContainerViewController()
        // TODO: need some validation here
        containerViewController.searchText = textField.text
        //self.searchButtonView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
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
