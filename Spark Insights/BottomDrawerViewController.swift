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

    weak var currentControl: UIViewController?
    weak var edgeConstraint: NSLayoutConstraint?
    
    @IBOutlet weak var downButton: UIButton!
    @IBOutlet weak var upButton: UIButton!
    @IBOutlet weak var controlHolderView: UIView!
    
    private var currentState: BottomDrawerState = BottomDrawerState.ClosedFully
    
    var state: BottomDrawerState = BottomDrawerState.ClosedFully {
        didSet {
            currentState = state
            self.animateToState(state, complete: {})
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize views to match properties
        downButton.hidden = true
        edgeConstraint?.constant = CGFloat(currentState.rawValue)
    }
    
    @IBAction func buttonClicked(sender: AnyObject) {
        toggleOpenClose()
    }
    
    func animateToState(newState: BottomDrawerState, complete: () -> Void) {
        self.currentState = newState
        edgeConstraint?.constant = CGFloat(newState.rawValue)
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.view.superview?.layoutIfNeeded()
            }) { (finished) -> Void in
                complete()
                self.syncButtonWithState()
        }
    }
    
    private func syncButtonWithState() {
        switch currentState {
        case BottomDrawerState.Open:
            upButton.hidden = true
            downButton.hidden = false
        case BottomDrawerState.ClosedPartial:
            upButton.hidden = false
            downButton.hidden = true
        case BottomDrawerState.ClosedFully:
            upButton.hidden = false
            downButton.hidden = true
        }
    }
    
    private func toggleOpenClose() {
        self.state = (currentState == BottomDrawerState.Open) ? BottomDrawerState.ClosedPartial : BottomDrawerState.Open
    }
    
    func addControl(controller: UIViewController) {
        currentControl = controller
        addChildViewController(currentControl!)
        currentControl!.didMoveToParentViewController(self)
        controlHolderView.addSubview(currentControl!.view)
        
        let views = [
            "control": currentControl!.view
        ]
        currentControl!.view.translatesAutoresizingMaskIntoConstraints = false
        let viewConst_W = NSLayoutConstraint.constraintsWithVisualFormat("H:|[control]|", options: NSLayoutFormatOptions.DirectionLeadingToTrailing, metrics: nil, views: views)
        let viewConst_H = NSLayoutConstraint.constraintsWithVisualFormat("V:|[control]|", options: NSLayoutFormatOptions.DirectionLeadingToTrailing, metrics: nil, views: views)
        controlHolderView.addConstraints(viewConst_W)
        controlHolderView.addConstraints(viewConst_H)
    }
    
    func removeControl() {
        currentControl?.willMoveToParentViewController(nil)
        currentControl?.view.removeFromSuperview()
        currentControl?.removeFromParentViewController()
    }

}
