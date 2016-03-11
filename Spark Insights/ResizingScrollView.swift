//
//  ResizingScrollView.swift
//  RedRock
//
//  Created by Jonathan Alter on 10/5/15.
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

class ResizingScrollView: UIScrollView {
    
    var childVisualisations: [UIView] = []
    var page: Int = 0
    var endedRelayout = true
    
    func addVisualisation(view: UIView) {
        let newOrigin = CGFloat(childVisualisations.count) * self.frame.size.width
        let newFrame = CGRectMake(newOrigin, 0, self.frame.size.width, self.frame.size.height)
        view.frame = newFrame
    
        childVisualisations.append(view)
        self.addSubview(view)
        
        let pageWidth = self.frame.size.width
        self.contentSize = CGSizeMake(pageWidth * CGFloat(childVisualisations.count), self.frame.size.height)
    }
    
    // Call this method immediately before resizing the ScrollView
    func viewWillResize() {
        endedRelayout = false
        let pageWidth = self.frame.size.width
        let fractionalPage = Float(self.contentOffset.x / pageWidth)
        page = Int(round(fractionalPage))
    }
    
    // Call this method immediately after resizing the ScrollView
    func viewDidResize() {
        relayoutSubviews()
    }
    
    private func relayoutSubviews() {
        self.layoutIfNeeded()
        
        let pageWidth = self.frame.size.width
        
        for (i, view) in childVisualisations.enumerate() {
            let myOrigin = CGFloat(i) * pageWidth
            view.frame.origin.x = myOrigin
            view.frame.size.width = pageWidth
        }
        
        self.contentSize = CGSizeMake(pageWidth * CGFloat(childVisualisations.count), self.frame.size.height)
        let offset = pageWidth * CGFloat(page)
        self.setContentOffset(CGPointMake(offset, 0), animated: false)
        endedRelayout = true
    }

}
