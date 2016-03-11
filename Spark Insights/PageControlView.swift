//
//  PageControlView.swift
//  Spark Insights
//
//  Created by Jonathan Alter on 5/29/15.
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
    var buttonBackgroundColor = UIColor.grayColor()
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
        let height = buttonHeight
        let width = buttonWidth * buttonData.count
        return CGSize(width: width, height: height)
    }
    
    // MARK: private functions
    
    private func updateButtons() {
        for oldButton in buttons {
            oldButton.removeFromSuperview()
        }
        buttons = Array<UIButton>()
        
        let height = buttonHeight
        for (i,data) in buttonData.enumerate() {
            let position = buttonWidth * i
            let v = UIButton(frame: CGRect(x: position, y: 0, width: buttonWidth, height: height))
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
        for (i, btn) in buttons.enumerate() {
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
        let index = Int(sender.frame.origin.x) / buttonWidth
        selectedIndex = index
        delegate?.pageChanged?(index)
    }
}
