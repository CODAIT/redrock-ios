//
//  CircleView.swift
//  RedRock
//
//  Created by Rosstin Murphy on 9/25/15.
//  Copyright (c) 2015 IBM. All rights reserved.
//

import Foundation
import UIKit

class CircleView :UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawRect(rect: CGRect) {
        var context = UIGraphicsGetCurrentContext()
        
        CGContextSetLineWidth(context, 5.0)
        
        CGContextAddArc(context, (frame.size.width)/2, frame.size.height/2, (frame.size.width - 10)/2, 0.0, CGFloat(M_PI * 2.0), 1)
        
        CGContextStrokePath(context);
    }
    
    func changeRadiusTo(newRadius: CGFloat){
        self.frame.size.width = newRadius
        self.frame.size.height = newRadius
    }
}