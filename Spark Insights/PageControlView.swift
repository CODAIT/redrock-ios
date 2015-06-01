//
//  PageControlView.swift
//  Spark Insights
//
//  Created by Jonathan Alter on 5/29/15.
//  Copyright (c) 2015 IBM. All rights reserved.
//

import UIKit

@objc
protocol PageControlDelegate {
    optional func pageChanged(index: Int)
}

struct PageControlButtonData {
    var imageName = ""
    var selectedImageName = ""
}

class PageControlView: UIView {
    
    weak var delegate: PageControlDelegate?
    
    // Defaults
    var buttonWidth = 50
    var buttonHeight = 60
    var buttonImageEdgeInsets = UIEdgeInsetsMake(20, 15, 20, 15)
    var buttonBackgroundColor = UIColor.whiteColor()
    var buttonSelectedBackgroundColor = UIColor.blueColor()

    var selectedIndex = 0 {
        didSet {
            refresh()
        }
    }
    var buttonData = Array<PageControlButtonData>() {
        didSet {
            updateButtons()
        }
    }
    
    private var buttons = Array<UIButton>()
    
    // MARK: UIView overrides
    
    override func intrinsicContentSize() -> CGSize {
        var height = buttonHeight
        var width = buttonWidth * buttonData.count
        return CGSize(width: width, height: height)
    }
    
    // MARK: private functions
    
    private func updateButtons() {
        for oldButton in buttons {
            oldButton.removeFromSuperview()
        }
        buttons = Array<UIButton>()
        
        var height = buttonHeight
        for (i,data) in enumerate(buttonData) {
            var position = buttonWidth * i
            var v = UIButton(frame: CGRect(x: position, y: 0, width: buttonWidth, height: height))
            v.setImage(UIImage(named: data.imageName), forState: UIControlState.Normal)
            v.setImage(UIImage(named: data.selectedImageName), forState: UIControlState.Disabled)
            v.setImage(UIImage(named: data.selectedImageName), forState: UIControlState.Highlighted)
            v.backgroundColor = buttonBackgroundColor
            v.imageEdgeInsets = buttonImageEdgeInsets
            v.addTarget(self, action: "buttonClicked:", forControlEvents: UIControlEvents.TouchDown)
            buttons.append(v)
            self.addSubview(v)
            
            if i == selectedIndex {
                v.backgroundColor = buttonSelectedBackgroundColor
                v.enabled = false
            }
        }
        layoutIfNeeded()
        refresh()
        
    }
    
    private func refresh() {
        for (i, btn) in enumerate(buttons) {
            if i == selectedIndex {
                selectButton(btn)
            } else {
                deselectButton(btn)
            }
        }
    }
    
    private func deselectButton(button: UIButton) {
        button.backgroundColor = buttonBackgroundColor
        button.enabled = true
    }
    
    private func selectButton(button: UIButton) {
        button.backgroundColor = buttonSelectedBackgroundColor
        button.enabled = false
    }
    
    // MARK: Actions
    
    func buttonClicked(sender: UIButton) {
        var index = Int(sender.frame.origin.x) / buttonWidth
        selectedIndex = index
        delegate?.pageChanged?(index)
    }
}
