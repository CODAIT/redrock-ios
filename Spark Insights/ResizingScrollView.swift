//
//  ResizingScrollView.swift
//  RedRock
//
//  Created by Jonathan Alter on 10/5/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import UIKit

class ResizingScrollView: UIScrollView {
    
    var childVisualisations: [UIView] = []
    var page: Int = 0
    
    func addVisualisation(view: UIView) {
        childVisualisations.append(view)
        self.addSubview(view)
    }
    
    // Call this method immediately before resizing the ScrollView
    func viewWillResize() {
        let pageWidth = self.frame.size.width
        let fractionalPage = Float(self.contentOffset.x / pageWidth)
        page = Int(round(fractionalPage))
        
        UIView.animateWithDuration(0.2) { () -> Void in
            self.alpha = 0
        }
    }
    
    // Call this method immediately after resizing the ScrollView
    func viewDidResize() {
        relayoutSubviews()
        
        UIView.animateWithDuration(0.2) { () -> Void in
            self.alpha = 1
        }
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
    }

}
