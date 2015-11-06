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
    @IBOutlet weak var searchHolderTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var searchHolderBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var appTitleTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var appImageTitle: UILabel!
    @IBOutlet weak var searchTextFieldHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var AppTitleView: UIView!
    @IBOutlet weak var appTitleLabel: UILabel!
    @IBOutlet weak var searchHolderView: UIView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var topImageView: UIImageView!
    @IBOutlet weak var searchButtonView: UIView!
    @IBOutlet weak var liveButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    
    private var recalculateConstrainstsForSearchView = true
    
    var imageTitleTopConstraintInitial: CGFloat!
    var imageSearchTopConstraintInitial: CGFloat!
    var searchHolderTopConstraintInitial: CGFloat!
    var searchHolderBottomConstraintInitial: CGFloat!
    var appTitleTopConstraintInitial: CGFloat!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (Config.searchViewAnimation) {
            YLGIFImage.setPrefetchNum(5)
            let path = NSBundle.mainBundle().URLForResource("searchwaiting2", withExtension: "gif")?.absoluteString as String!
            topImageView.image = YLGIFImage(contentsOfFile: path)
        }
        
        self.textField.delegate = self
        self.textField.keyboardType = UIKeyboardType.Twitter
        self.textField.returnKeyType = UIReturnKeyType.Search
        setInsetTextField()
        addGestureRecognizerSearchView()
        imageTitleTopConstraintInitial = self.imageTitleTopConstraint.constant
        imageSearchTopConstraintInitial = self.imageSearchTopConstraint.constant
        searchHolderTopConstraintInitial = self.searchHolderTopConstraint.constant
        searchHolderBottomConstraintInitial = self.searchHolderBottomConstraint.constant
        appTitleTopConstraintInitial = self.appTitleTopConstraint.constant
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        checkIfUserHasLoggedIn()
    }
    
    func checkIfUserHasLoggedIn(){
        //TODO COMPLAIN THAT USER HAS NOT LOGGED IN
        if let userName = NSUserDefaults.standardUserDefaults().objectForKey(Config.loginKeyForNSUserDefaults){
            Log("Found a username!! \(userName)")
        }
        else{
            Log("NO USERNAME!!! COMPLAIN!!!!!")
            showLoginAlert()
        }
    }
    
    func showLoginAlertWithCancelButton(){
        let alert = buildLoginAlert()
        alert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // TODO make an alert that forces the user to login
    // They can enter a valid email address
    // or.... they can force quit the app
    func showLoginAlert(){
        let alert = buildLoginAlert()
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func buildLoginAlert() -> UIAlertController{
        let alert = UIAlertController(title: Config.loginAlertTitle, message: Config.loginAlertMessage, preferredStyle: .Alert)
        
        alert.addTextFieldWithConfigurationHandler({ (textField) -> Void in
            textField.text = Config.loginDefaultText})
        
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            let textField = alert.textFields![0] as UITextField
            
            NSUserDefaults.standardUserDefaults().setValue(textField.text, forKey: Config.loginKeyForNSUserDefaults)
            
            self.setLoginText()
        }))
        
        return alert
    }
    
    override func viewWillAppear(animated: Bool) {
        self.resetViewController()
        if (Config.searchViewAnimation) {
            topImageView.startAnimating()
        }
        liveButton.setTitle("Live \(Config.liveSearches[Config.liveCurrentSearchIndex])", forState: UIControlState.Normal)
        
        setLoginText()
    }
    
    func setLoginText(){
        if let userName = NSUserDefaults.standardUserDefaults().stringForKey(Config.loginKeyForNSUserDefaults){
            let whitespaceSet = NSCharacterSet.whitespaceCharacterSet()
            if userName.stringByTrimmingCharactersInSet(whitespaceSet) != "" {
                
                var sanitizedUsername = ""
                var afterAtSign = false
                for i in userName.characters {
                    if(String(i).containsString("@")){
                        afterAtSign = true
                    }
                    
                    if(afterAtSign){
                        sanitizedUsername = sanitizedUsername+String(i)
                    }
                    else{
                        sanitizedUsername = sanitizedUsername+"*"
                    }
                }
                
                loginButton.setTitle(" \(sanitizedUsername) ", forState: UIControlState.Normal)
            }
            else{
                loginButton.setTitle(Config.loginPleaseLogin, forState: UIControlState.Normal)
            }
        }
        else{
            loginButton.setTitle(Config.loginPleaseLogin, forState: UIControlState.Normal)
        }
    }
    
    // MARK: - Reset UI
    
    func resetViewController() {
        // Use this function to reset the view controller's UI to a clean state
        Log("Resetting \(__FILE__)")
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
            if (Config.searchViewAnimation) {
                topImageView.stopAnimating()
            }
            recalculateConstraintsForAnimation()
            UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                self.view.layoutIfNeeded()
                }, completion: nil)
            self.textField.font = UIFont (name: "Helvetica Neue", size: 17)
            self.recalculateConstrainstsForSearchView = false
        }
    }

    @IBAction func endedEditing(sender: UITextField)
    {
        recalculateConstrainstForBakcAnimation()
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            self.view.layoutIfNeeded()
            }, completion: nil)
        if (Config.searchViewAnimation) {
            topImageView.startAnimating()
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
        self.searchHolderBottomConstraint.constant = self.searchHolderView.frame.height
    }
    
    func recalculateConstrainstForBakcAnimation()
    {
        self.recalculateConstrainstsForSearchView = true
        self.searchHolderBottomConstraint.constant = self.searchHolderBottomConstraintInitial
        self.searchHolderTopConstraint.constant = self.searchHolderTopConstraintInitial
        self.appTitleTopConstraint.constant = self.appTitleTopConstraintInitial
        self.imageSearchTopConstraint.constant = self.imageSearchTopConstraintInitial
        self.imageTitleTopConstraint.constant = self.imageTitleTopConstraintInitial
        self.AppTitleView.hidden = true
        self.appTitleLabel.hidden = true
        self.searchButtonView.alpha = 1.0
        UIView.animateWithDuration(0.7, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            self.view.layoutIfNeeded()
            }, completion: nil)

    }

    func searchClicked(gesture: UIGestureRecognizer?) {
        var searchText = self.textField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
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
            if searchText != "" && checkIncludeTerms(searchText)
            {
                Config.appState = .Historic
                delegate?.displayContainerViewController?(self, searchText: searchText)
            }
            else
            {
                self.searchButtonView.alpha = 1.0
                let animation = CABasicAnimation(keyPath: "position")
                animation.duration = 0.07
                animation.repeatCount = 2
                animation.autoreverses = true
                animation.fromValue = NSValue(CGPoint: CGPointMake(self.textField.center.x - 5, self.textField.center.y))
                animation.toValue = NSValue(CGPoint: CGPointMake(self.textField.center.x + 5, self.textField.center.y))
                self.textField.layer.addAnimation(animation, forKey: "position")
            }
        }
    
    }
    
    @IBAction func liveClicked(sender: UIButton) {
        Config.appState = .Live
        delegate?.displayContainerViewController?(self, searchText: Config.liveSearches[Config.liveCurrentSearchIndex])
    }
    
    @IBAction func loginClicked(sender: UIButton) {
        //Log("loginClicked");
        showLoginAlertWithCancelButton()
    }

    /* Find at least one include term*/
    func checkIncludeTerms(searchTerms: String) -> Bool
    {
        let terms = searchTerms.componentsSeparatedByString(",")
        for var i = 0; i < terms.count; i++
        {
            let term = terms[i]
            if term != ""
            {
                var aux = Array(term.characters)
                if aux[0] != "-"
                {
                    return true
                }
            }
        }
        
        return false
    }

}
