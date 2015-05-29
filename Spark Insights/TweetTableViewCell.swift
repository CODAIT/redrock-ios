//
//  TweetTableViewCell.swift
//  TwiiterCellView
//
//  Created by Barbara Gomes on 5/26/15.
//  Copyright (c) 2015 Barbara Gomes. All rights reserved.
//

import UIKit

class TweetTableViewCell: UITableViewCell, UIGestureRecognizerDelegate, ContextLabelDelegate{

    // Tweet Cell outlets
    @IBOutlet weak var displayView: UIView!
    @IBOutlet weak var userProfileImage: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userScreenName: UILabel!
    @IBOutlet weak var tweeText: ContextLabel!
    @IBOutlet weak var countFavorite: UILabel!
    @IBOutlet weak var countRetweet: UILabel!
    @IBOutlet weak var tweetDateTime: UILabel!
    
    //Tweet cell swipeable
    @IBOutlet weak var twitterDetailImg: UIImageView!
    @IBOutlet weak var contentViewRightConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentViewLeftConstraint: NSLayoutConstraint!
    var panRecognizer = UIPanGestureRecognizer()
    var panStartPoint = CGPoint()
    var startingRightLayoutConstraintConstant = CGFloat()
    let kBounceValue = CGFloat(5.0)
    
    //Constants to calculate cell height
    static let profileImageWidth = CGFloat(36)
    static let profileImageHeight = CGFloat(36)
    static let characWidth = CGFloat(7)
    static let lineHeight = CGFloat(20)
    static let tweetToolbarHeight = CGFloat(18)
    static let blankSpaceHeight = CGFloat(40)
    
    //Keep track of the row index of the cell
    var rowIndex:Int = 0
    var displayTappedURL: ((selectedURL: String) -> ())!
    var isURLTapped = false
    var actionOnClickImageDetail: ((tweetCell: TweetTableViewCell) -> ())!
    
    //Colors
    let cellBackgroundColor = UIColor(red: 29/255, green: 54/255, blue: 73/255, alpha: 1)
    let detailsColor = UIColor(red: 226/255, green: 121/255, blue: 0, alpha: 1)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //Tweet text component colors
        tweeText.hashtagTextColor = self.detailsColor
        tweeText.userHandleTextColor = UIColor.whiteColor()
        tweeText.linkTextColor = self.detailsColor
        tweeText.textColor = UIColor.whiteColor()
        self.backgroundView?.backgroundColor = self.cellBackgroundColor
        self.displayView.backgroundColor = self.cellBackgroundColor
        //ContextLabel delegate
        tweeText.delegate = self
        //Profile Image layout
        changeImageLayout()
        // Swipe
        self.panRecognizer = UIPanGestureRecognizer(target: self, action: "panThisCell:")
        self.panRecognizer.delegate = self
        self.displayView.addGestureRecognizer(self.panRecognizer)
        // User interaction Swipe image
        let tapGesture = UITapGestureRecognizer(target: self, action: "twitterImageClicked:")
        twitterDetailImg.addGestureRecognizer(tapGesture)
        twitterDetailImg.userInteractionEnabled = true
    }
    
    // MARK - Profile Image style
    func changeImageLayout()
    {
        self.userProfileImage.layer.cornerRadius = 10.0;
        self.userProfileImage.layer.masksToBounds = true;
        self.userProfileImage.layer.borderColor = self.detailsColor.CGColor
        self.userProfileImage.layer.borderWidth = 2.0;
    }
    
    // MARK - Select style
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
        self.displayView.backgroundColor = self.cellBackgroundColor
    }
    
    
    // MARK - Configure Tweet
    func configureWithTweetData(profileImage: UIImage, userName: String, userScreenName: String, tweetText: String, countFavorite: String, countRetweet: String, dateTime: String)
    {
        self.userProfileImage.image = profileImage
        self.userName.text = userName
        self.userScreenName.text = userScreenName
        self.tweeText.text = tweetText
        self.countFavorite.text = countFavorite
        self.countRetweet.text = countRetweet
        self.tweetDateTime.text = dateTime
    }
    
    static func calculateHeightForCell(textLength: CGFloat, tableWidth: CGFloat) -> CGFloat
    {
        let tweetTextWidth = tableWidth - self.profileImageWidth
        let characByLine = tweetTextWidth/self.characWidth
        let lineCount = textLength/characByLine
        return (self.lineHeight*lineCount + self.profileImageHeight + self.tweetToolbarHeight + self.blankSpaceHeight)
    }
    
    // MARK - Context Label delegate
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
        println("movedTouchTo: \(text)" + "\nRange: \(linkRangeResult.linkRange)")
    }
    
    func contextLabel(contextLabel: ContextLabel, endedTouchOf text: String, with linkRangeResult: LinkRangeResult) {
        if  self.isURLTapped
        {
            self.displayTappedURL(selectedURL: text)
        }
    }
    
    func twitterImageClicked(gesture: UIGestureRecognizer)
    {
        self.actionOnClickImageDetail(tweetCell: self)
    }
    
    // MARK - Swipeable
    func panThisCell(gesture: UIPanGestureRecognizer)
    {
        switch (gesture.state) {
        case UIGestureRecognizerState.Began:
            self.panStartPoint = gesture.translationInView(self.displayView)
            self.startingRightLayoutConstraintConstant = self.contentViewRightConstraint.constant
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
            var halfOfButtonOne = CGRectGetWidth(self.twitterDetailImg.frame) / 2; //2
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
            var imageWidth = CGRectGetWidth(self.twitterDetailImg.frame); //4
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
        return CGRectGetWidth(self.twitterDetailImg.frame)
    }
    
    func resetConstraintContstantsToZero(animated: Bool, notifyDelegateDidClose: Bool)
    {
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
