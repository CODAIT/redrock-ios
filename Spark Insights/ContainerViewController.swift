//
//  ContainerViewController.swift
//  Spark Insights
//
//  Created by Jonathan Alter on 5/28/15.
//  Copyright (c) 2015 IBM. All rights reserved.
//

import UIKit

@objc
protocol ContainerViewControllerDelegate {
    optional func displaySearchViewController()
}

enum SlideOutState {
    case BothCollapsed
    case RightPanelExpanded
}

class ContainerViewController: UIViewController {
    
    weak var delegate: ContainerViewControllerDelegate?
    
    var centerViewController: CenterViewController!
    var rightViewController: RightViewController!
    
    var currentState: SlideOutState = .BothCollapsed
    let centerPanelExpandedOffset: CGFloat = 325
    
    var searchText: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        centerViewController = UIStoryboard.centerViewController()
        centerViewController.delegate = self
        centerViewController.searchText = searchText
        
        view.addSubview(centerViewController.view)
        addChildViewController(centerViewController)
        
        centerViewController.didMoveToParentViewController(self)
    }
    
}

// MARK: - CenterViewControllerDelegate

extension ContainerViewController: RightViewControllerDelegate
{
    func executeActionOnGoClicked(searchTerms: String) {
        self.toggleRightPanel(false)
        self.searchText = searchTerms
        self.centerViewController.searchText = searchTerms
    }
}

extension ContainerViewController: CenterViewControllerDelegate {
    
    // If close is true, always close the panel
    // Necessary because if you go back to the main search screen and the side search is opened,
    // we need to close that
    func toggleRightPanel(close: Bool) {
        var notAlreadyExpanded = (currentState != .RightPanelExpanded)
        if close
        {
            if !notAlreadyExpanded
            {
                animateRightPanel(shouldExpand: false)
            }
        }
        else
        {
            if notAlreadyExpanded {
                addRightPanelViewController()
            }
            animateRightPanel(shouldExpand: notAlreadyExpanded)
        }

    }
    
    func addChildSidePanelController(sidePanelController: UIViewController) {
        view.insertSubview(sidePanelController.view, atIndex: 0)
        
        addChildViewController(sidePanelController)
        sidePanelController.didMoveToParentViewController(self)
    }
    
    func addRightPanelViewController() {
        if (rightViewController == nil) {
            rightViewController = UIStoryboard.rightViewController()
            self.rightViewController.delegate = self
            self.rightViewController.searchString = self.searchText
            addChildSidePanelController(rightViewController!)
        }
    }
    
    func animateRightPanel(#shouldExpand: Bool) {
        if (shouldExpand) {
            self.rightViewController.searchString = self.searchText
            self.rightViewController.tableA.reloadData()
            self.rightViewController.tableB.reloadData()
            currentState = .RightPanelExpanded
            animateCenterPanelXPosition(targetPosition: -centerPanelExpandedOffset)
        } else {
            animateCenterPanelXPosition(targetPosition: 0) { _ in
                self.currentState = .BothCollapsed
                self.rightViewController!.view.removeFromSuperview()
                self.rightViewController = nil;
            }
        }
    }
    
    func displaySearchViewController() {
        delegate?.displaySearchViewController?()
    }
    
    func animateCenterPanelXPosition(#targetPosition: CGFloat, completion: ((Bool) -> Void)! = nil) {
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            self.centerViewController.view.frame.origin.x = targetPosition
            }, completion: completion)
    }
    
}

private extension UIStoryboard {
    class func mainStoryboard() -> UIStoryboard { return UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()) }
    
    class func rightViewController() -> RightViewController? {
        return mainStoryboard().instantiateViewControllerWithIdentifier("RightViewController") as? RightViewController
    }
    
    class func centerViewController() -> CenterViewController? {
        return mainStoryboard().instantiateViewControllerWithIdentifier("CenterViewController") as? CenterViewController
    }
    
}
