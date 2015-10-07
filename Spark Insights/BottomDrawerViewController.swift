//
//  BottomDrawerView.swift
//  RedRock
//
//  Created by Jonathan Alter on 10/6/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import UIKit

@objc
enum BottomDrawerState : Int {
    case ClosedFully = -30
    case ClosedPartial = -10
    case Open = 60
}

/*
USAGE:
1. Create instance
2. Add to superview
3. "edgeConstraint" must be set with the constraint that will be changed to make the drawer slide
4. "state" should be set with the BottomDrawerState that you wish to start with
*/
class BottomDrawerViewController: UIViewController {

    weak var edgeConstraint: NSLayoutConstraint?
    
    @IBOutlet weak var downButton: UIButton!
    @IBOutlet weak var upButton: UIButton!
    
    var state: BottomDrawerState = BottomDrawerState.Open {
        didSet {
            self.animateToState(state)
        }
    }
    
    override func viewDidLoad() {
        // Initialize views to match properties
        upButton.hidden = true
        edgeConstraint?.constant = CGFloat(state.rawValue)
    }
    
    @IBAction func buttonClicked(sender: AnyObject) {
        toggleOpenClose()
    }
    
    func animateToState(state: BottomDrawerState) {
        edgeConstraint?.constant = CGFloat(state.rawValue)
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.view.superview?.layoutIfNeeded()
            }) { (finished) -> Void in
                self.syncButtonWithState()
        }
    }
    
    func syncButtonWithState() {
        switch state {
        case BottomDrawerState.Open:
            upButton.hidden = true
            downButton.hidden = false
        case BottomDrawerState.ClosedPartial:
            upButton.hidden = false
            downButton.hidden = true
        default:
            upButton.hidden = true
            downButton.hidden = false
        }
    }
    
    func toggleOpenClose() {
        
        self.state = (state == BottomDrawerState.Open) ? BottomDrawerState.ClosedPartial : BottomDrawerState.Open
    }

}
