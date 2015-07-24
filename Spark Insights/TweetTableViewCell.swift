//
//  TweetTableViewCell.swift
//  TwiiterCellView
//
//  Created by Barbara Gomes on 5/26/15.
//  Copyright (c) 2015 Barbara Gomes. All rights reserved.
//

import UIKit

@objc
protocol TweetTableViewCellDelegate {
    func twitterBirdButtonClicked(clickedCell: TweetTableViewCell)
    func cellDidOpen(openedCell: TweetTableViewCell)
    func cellDidClose(closedCell: TweetTableViewCell)
    func cellDidBeginOpening(openingCell: TweetTableViewCell)
    func didTappedURLInsideTweetText(tappedURL: String)
    func userHandleClicked(clickedCell: TweetTableViewCell)
}

class TweetTableViewCell: UITableViewCell, UIGestureRecognizerDelegate, ContextLabelDelegate{

    // Delegate
    weak var delegate: TweetTableViewCellDelegate?
    
    @IBOutlet weak var userScreenName: UIButton!
    // Tweet Cell outlets
    @IBOutlet weak var displayView: UIView!
    @IBOutlet weak var userProfileImage: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var tweeText: ContextLabel!
    //@IBOutlet weak var countFavorite: UILabel!
    //@IBOutlet weak var countRetweet: UILabel!
    @IBOutlet weak var tweetDateTime: UILabel!
    @IBOutlet weak var followers_count: UILabel!
    
    @IBOutlet weak var twitterBirdView: UIView!
    @IBOutlet weak var contentViewRightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var contentViewLeftConstraint: NSLayoutConstraint!
    
    //Tweet cell swipeable
    @IBOutlet weak var twitterDetailImg: UIImageView!

    var panRecognizer = UIPanGestureRecognizer()
    var panStartPoint = CGPoint()
    var startingRightLayoutConstraintConstant = CGFloat()
    let kBounceValue = CGFloat(5.0)
    
    //Constants to calculate cell height
    static let profileImageWidth = CGFloat(50)
    static let profileImageHeight = CGFloat(50)
    static let characWidth = CGFloat(9)
    static let lineHeight = CGFloat(24)
    static let tweetToolbarHeight = CGFloat(19)
    static let blankSpaceHeight = CGFloat(70)
    static let maxCellHeight = CGFloat(245)
    
    //Keep track of the row index of the cell
    var rowIndex:Int = 0
    var isURLTapped = false
    
    //User profile url by link
    var userProfileURL = ""
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //Tweet text component colors
        tweeText.hashtagTextColor = Config.tweetsTableTextComponentsColor
        tweeText.userHandleTextColor = UIColor.whiteColor()
        tweeText.linkTextColor = Config.tweetsTableTextComponentsColor
        tweeText.textColor = UIColor.whiteColor()
        self.backgroundView?.backgroundColor = Config.tweetsTableBackgroundColor
        self.backgroundColor = Config.tweetsTableBackgroundColor
        //self.displayView.backgroundColor = Config.tweetsTableBackgroundColor
        //ContextLabel delegate
        tweeText.delegate = self
        //Profile Image layout
        changeImageLayout()
        // Swipe
        self.panRecognizer = UIPanGestureRecognizer(target: self, action: "panThisCell:")
        self.panRecognizer.delegate = self
        self.displayView.addGestureRecognizer(self.panRecognizer)
        // User interaction Swipe image
        let tapGesture = UILongPressGestureRecognizer(target: self, action: "twitterImageClicked:")
        tapGesture.minimumPressDuration = 0.001
        self.twitterBirdView.addGestureRecognizer(tapGesture)
        self.twitterBirdView.userInteractionEnabled = true
    }
    
    // MARK: Profile Image style
    func changeImageLayout()
    {
        self.userProfileImage.layer.cornerRadius = 25.0;
        self.userProfileImage.layer.masksToBounds = true;
        self.userProfileImage.layer.borderColor = Config.tweetsProfileImageBorderColor.CGColor
        self.userProfileImage.layer.borderWidth = 2.0;
    }
    
    // MARK: Select style
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if self.isURLTapped
        {
            self.isURLTapped = false
            self.selectionStyle = UITableViewCellSelectionStyle.None
        }
        else
        {
            self.displayView.backgroundColor = UIColor.grayColor()
        }
    }
    override func setHighlighted(highlighted: Bool, animated: Bool) {
        self.displayView.backgroundColor = Config.tweetsTableBackgroundColor
    }
    
    @IBAction func userHandleClicked(sender: UIButton) {
        self.delegate?.userHandleClicked(self)
    }
    
    // MARK: Configure Tweet
    func configureWithTweetData(userName: String, userScreenName: String, tweetText: String, /*countFavorite: String, countRetweet: String,*/ dateTime: String, userProfileURL: String, countFollowers: String)
    {
        self.userName.text = userName
        self.userScreenName.setTitle(userScreenName, forState: UIControlState.Normal)
        self.tweeText.text = tweetText
        //self.countFavorite.text = countFavorite
        //self.countRetweet.text = countRetweet
        self.tweetDateTime.text = dateTime
        self.userProfileURL = userProfileURL
        self.followers_count.text = countFollowers
    }
    
    static func calculateHeightForCell(textLength: CGFloat, tableWidth: CGFloat) -> CGFloat
    {
        let tweetTextWidth = tableWidth - self.profileImageWidth
        let characByLine = tweetTextWidth/self.characWidth
        let lineCount = textLength/characByLine
        let cellHeight = (self.lineHeight*lineCount + self.profileImageHeight + self.tweetToolbarHeight + self.blankSpaceHeight)
        if cellHeight > self.maxCellHeight
        {
            return self.maxCellHeight
        }
        else
        {
            return cellHeight
        }
    }
    
    // MARK: Context Label delegate
    func contextLabel(contextLabel: ContextLabel, beganTouchOf text: String, with linkRangeResult: LinkRangeResult) {
        //Avoid row be selected
        var firstCharac = Array(text)[0]
        if firstCharac != "@" && firstCharac != "#"
        {
            self.isURLTapped = true
        }
        else
        {
            self.isURLTapped = false
        }
    }
    
    func contextLabel(contextLabel: ContextLabel, movedTouchTo text: String, with linkRangeResult: LinkRangeResult) {
        Log("movedTouchTo: \(text)" + "\nRange: \(linkRangeResult.linkRange)")
    }
    
    func contextLabel(contextLabel: ContextLabel, endedTouchOf text: String, with linkRangeResult: LinkRangeResult) {
        if  self.isURLTapped
        {
            self.delegate?.didTappedURLInsideTweetText(text)
        }
    }
    
    func twitterImageClicked(gesture: UIGestureRecognizer)
    {
        if gesture.state == UIGestureRecognizerState.Began
        {
            self.twitterBirdView.alpha = 0.5
        }
        else if gesture.state == UIGestureRecognizerState.Ended
        {
            delegate?.twitterBirdButtonClicked(self)
            self.twitterBirdView.alpha = 1.0
        }
    }
    
    // MARK: Swipeable
    func panThisCell(gesture: UIPanGestureRecognizer)
    {
        switch (gesture.state) {
        case UIGestureRecognizerState.Began:
            self.panStartPoint = gesture.translationInView(self.displayView)
            self.startingRightLayoutConstraintConstant = self.contentViewRightConstraint.constant
            self.delegate?.cellDidBeginOpening(self)
            break
        case UIGestureRecognizerState.Changed:
            swipeableCellChanged(gesture)
            break
        case UIGestureRecognizerState.Ended:
            swipeableCellEnded(gesture)
            break
        case UIGestureRecognizerState.Cancelled:
            if (self.startingRightLayoutConstraintConstant == 0) {
                //Cell was closed - reset everything to 0
                self.resetConstraintContstantsToZero(true, notifyDelegateDidClose:true);
            } else {
                //Cell was open - reset to the open state
                self.setConstraintsToShowAllButtons(true, notifyDelegateDidOpen:true);
            }
            break
        default:
            break
        }
    }
    
    func swipeableCellChanged(gesture: UIPanGestureRecognizer)
    {
        var currentPoint = gesture.translationInView(self.displayView)
        var deltaX = currentPoint.x - self.panStartPoint.x
        var panningLeft = false
        if (currentPoint.x < self.panStartPoint.x) {  //1
            panningLeft = true
        }
        if (self.startingRightLayoutConstraintConstant == 0) { //2
            //The cell was closed and is now opening
            if (!panningLeft) {
                var constant = max(-deltaX, 0); //3
                if (constant == 0) { //4
                    self.resetConstraintContstantsToZero(true, notifyDelegateDidClose: false)
                } else { //5
                    self.contentViewRightConstraint.constant = constant
                }
            } else {
                var constant = min(-deltaX, self.twitterImageTotalWidth()) //6
                if (constant == self.twitterImageTotalWidth()) { //7
                    self.setConstraintsToShowAllButtons(true, notifyDelegateDidOpen: false)
                } else { //8
                    self.contentViewRightConstraint.constant = constant
                }
            }
        }
        else {
            //The cell was at least partially open.
            var adjustment = self.startingRightLayoutConstraintConstant - deltaX //1
            if (!panningLeft) {
                var constant = max(adjustment, 0) //2
                if (constant == 0) { //3
                    self.resetConstraintContstantsToZero(true, notifyDelegateDidClose: false)
                } else { //4
                    self.contentViewRightConstraint.constant = constant;
                }
            } else {
                var constant = min(adjustment, self.twitterImageTotalWidth()); //5
                if (constant == self.twitterImageTotalWidth()) { //6
                    self.setConstraintsToShowAllButtons(true, notifyDelegateDidOpen: false)
                } else { //7
                    self.contentViewRightConstraint.constant = constant;
                }
            }
        }
        self.contentViewLeftConstraint.constant = -self.contentViewRightConstraint.constant; //8
    }
    
    func swipeableCellEnded(gesture: UIPanGestureRecognizer)
    {
        if (self.startingRightLayoutConstraintConstant == 0)
        { //1
            //Cell was opening
            var halfOfButtonOne = CGRectGetWidth(self.twitterBirdView.frame) / 2; //2
            if (self.contentViewRightConstraint.constant >= halfOfButtonOne)
            { //3
                //Open all the way
                self.setConstraintsToShowAllButtons(true, notifyDelegateDidOpen:true);
            }
            else{
                //Re-close
                self.resetConstraintContstantsToZero(true, notifyDelegateDidClose:true);
            }
        }
        else {
            //Cell was closing
            var imageWidth = CGRectGetWidth(self.twitterBirdView.frame); //4
            if (self.contentViewRightConstraint.constant >= imageWidth)
            { //5
                //Re-open all the way
                self.setConstraintsToShowAllButtons(true, notifyDelegateDidOpen:true);
            }
            else {
                //Close
                self.resetConstraintContstantsToZero(true, notifyDelegateDidClose:true);
            }
        }

    }
    
    func twitterImageTotalWidth() -> CGFloat
    {
        return CGRectGetWidth(self.twitterBirdView.frame)
    }
    
    func resetConstraintContstantsToZero(animated: Bool, notifyDelegateDidClose: Bool)
    {
        if notifyDelegateDidClose
        {
            self.delegate?.cellDidClose(self)
        }
        
        if (self.startingRightLayoutConstraintConstant == 0 &&
            self.contentViewRightConstraint.constant == 0) {
                //Already all the way closed, no bounce necessary
                return;
        }
        
        self.contentViewRightConstraint.constant = -kBounceValue;
        self.contentViewLeftConstraint.constant = kBounceValue;
        
        self.updateConstraintsIfNeeded(animated, completion:{finished -> Void in
            self.contentViewRightConstraint.constant = 0;
            self.contentViewLeftConstraint.constant = 0;
            
            self.updateConstraintsIfNeeded(animated, completion:{finished -> Void in
                self.startingRightLayoutConstraintConstant = self.contentViewRightConstraint.constant;
            })
        })
    }
    
    func setConstraintsToShowAllButtons(animated: Bool, notifyDelegateDidOpen:Bool)
    {
        if notifyDelegateDidOpen
        {
            self.delegate?.cellDidOpen(self)
        }
        
        if (self.startingRightLayoutConstraintConstant == self.twitterImageTotalWidth() &&
            self.contentViewRightConstraint.constant == self.twitterImageTotalWidth()) {
                return;
        }
        //2
        self.contentViewLeftConstraint.constant = -self.twitterImageTotalWidth() - kBounceValue;
        self.contentViewRightConstraint.constant = self.twitterImageTotalWidth() + kBounceValue;
        
        self.updateConstraintsIfNeeded(animated, completion:{finished -> Void in
            //3
            self.contentViewLeftConstraint.constant = -self.twitterImageTotalWidth()
            self.contentViewRightConstraint.constant = self.twitterImageTotalWidth()
            
            self.updateConstraintsIfNeeded(animated, completion:{finished -> Void in
                //4
                self.startingRightLayoutConstraintConstant = self.contentViewRightConstraint.constant;
            })
        })
    }
    
    override func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true;
    }
    
    //Close the swipe
    override func prepareForReuse() {
        super.prepareForReuse()
        self.resetConstraintContstantsToZero(false, notifyDelegateDidClose: false)
    }
    
    func updateConstraintsIfNeeded(animated:Bool, completion:((Bool)->Void)){
        var duration = 0.0;
        if (animated) {
            duration = 0.1;
        }
    
        UIView.animateWithDuration(duration, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: {self.layoutIfNeeded()}, completion: completion)
    }
}
