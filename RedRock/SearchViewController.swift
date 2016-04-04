//
//  SearchViewController.swift
//  RedRock
//
//  Created by Jonathan Alter on 5/28/15.
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
protocol SearchViewControllerDelegate {
    optional func displayContainerViewController(currentViewController: UIViewController, searchText: String)
}

class SearchViewController: UIViewController, UITextFieldDelegate {

    weak var delegate: SearchViewControllerDelegate?
    
    @IBOutlet weak var appTitleView: UIView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var topImageView: UIImageView!
    @IBOutlet weak var searchButtonView: UIView!
    @IBOutlet weak var liveButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var topImageHolderView: UIView!
    @IBOutlet weak var contentHolderView: UIView!
    @IBOutlet weak var searchTopToBottomRatioConstraint: NSLayoutConstraint!
    
    private var loadingView: LoadingView!
    private var alert: UIAlertController!
    
    private var recalculateConstrainstsForSearchView = true
    private var tempUserName: String!
    
    var titleViewTopConstraints: [NSLayoutConstraint]!
    var contentHolderViewTopConstraints: [NSLayoutConstraint]!
    
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
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        checkIfUserHasLoggedIn()
    }
    
    func checkIfUserHasLoggedIn(){ //is this obsolete?
        //TODO COMPLAIN THAT USER HAS NOT LOGGED IN
        if let userName = Config.userName {
            Log("Found a username!! \(userName)")
            tempUserName = Config.userName
        }
        else{
            Log("NO USERNAME!!! COMPLAIN!!!!!")
            showLoginAlert()
        }
    }
    
    func showLoginAlertWithCancelButton(){
        alert = buildLoginAlert()
        alert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: { (action) -> Void in
            self.alert = nil
            self.hideLoadingView()
        }))
        
        self.showLoadingView()
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func showLoginAlert(){
        alert = buildLoginAlert()
        
        self.showLoadingView()
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func buildLoginAlert() -> UIAlertController{
        let alert = UIAlertController(title: Config.loginAlertTitle, message: Config.loginAlertMessage, preferredStyle: .Alert)
        
        alert.addTextFieldWithConfigurationHandler({ (textField) -> Void in
            if self.tempUserName != nil {
                textField.text = self.tempUserName
            }
        })
        
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            let textField = alert.textFields![0] as UITextField
            
            self.tempUserName = textField.text
            self.sendLoginRequest()
        }))
        
        return alert
    }
    
    func sendLoginRequest() {
        // Short circuit login
        if (tempUserName == Config.redrockPassword) {
            Config.userName = self.tempUserName
            self.setLoginText()
            self.hideLoadingView()
            return
        }
        
        Network.sharedInstance.loginRequest(tempUserName, callback: { (json, error) -> () in
            if (error != nil || json!["success"].boolValue == false) {
                if (json != nil && json!["message"] != nil) {
                    self.alert.message = json!["message"].stringValue
                } else {
                    self.alert.message = error?.localizedDescription
                }
                self.presentViewController(self.alert, animated: true, completion: nil)
                return
            }
            
            Config.userName = self.tempUserName
            self.setLoginText()
            self.hideLoadingView()
        })

    }
    
    func showLoadingView() {
        if loadingView == nil {
            loadingView = LoadingView(frame: self.view.bounds)
            loadingView.holderView.alpha = 0
            loadingView.activityIndicator.alpha = 0
            self.view.addSubview(loadingView)
        }
        loadingView.hidden = false
    }
    
    func hideLoadingView() {
        if loadingView != nil {
            loadingView.hidden = true
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        self.resetViewController()
        
        liveButton.setTitle("Live \(Config.liveSearches[Config.liveCurrentSearchIndex])", forState: UIControlState.Normal)
        
        setLoginText()
    }
    
    func setLoginText(){
        if let userName = Config.userName {
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
    
    // MARK: Actions

    @IBAction func startedEditing(sender: UITextField) {
        addTopContraints()
            
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            self.view.layoutIfNeeded()
            }, completion: nil)
        
        if (Config.searchViewAnimation) {
            topImageView.stopAnimating()
        }
    }

    @IBAction func endedEditing(sender: UITextField)
    {
        resetSearchViewWithAnimation()
    }
    
    func addTopContraints() {
        appTitleView.hidden = false
        
        if titleViewTopConstraints == nil {
            let views = ["appTitleView": appTitleView]
            let metrics = Dictionary(dictionaryLiteral: ("priority",1000))
            titleViewTopConstraints =  NSLayoutConstraint.constraintsWithVisualFormat("V:|[appTitleView]", options: NSLayoutFormatOptions.AlignAllCenterX, metrics: metrics, views: views)
        }
        
        view.addConstraints(titleViewTopConstraints)
        view.addConstraint(searchTopToBottomRatioConstraint)
    }
    
    func resetSearchView() {
        guard titleViewTopConstraints != nil || contentHolderViewTopConstraints != nil else {
            return
        }
        
        view.removeConstraints(titleViewTopConstraints)
        view.removeConstraint(searchTopToBottomRatioConstraint)
        appTitleView.hidden = true
        searchButtonView.alpha = 1.0
        
        if (Config.searchViewAnimation) {
            topImageView.startAnimating()
        }
    }
    
    func resetSearchViewWithAnimation() {
        resetSearchView()
        
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
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
