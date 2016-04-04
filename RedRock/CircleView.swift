//
//  CircleView.swift
//  RedRock
//
//  Created by Rosstin Murphy on 9/25/15.
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

import Foundation
import UIKit

class CircleView :UIImageView {
    
    var myOriginX :CGFloat!
    var myOriginY :CGFloat!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.image = UIImage(named: "Bubble-64.png")
        
        self.backgroundColor = UIColor.clearColor()
        self.myOriginX = frame.origin.x
        self.myOriginY = frame.origin.y
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        CGContextSetLineWidth(context, 5.0)
        
        CGContextAddArc(context, (frame.size.width)/2, frame.size.height/2, (frame.size.width - 10)/2, 0.0, CGFloat(M_PI * 2.0), 1)
        
        CGContextStrokePath(context);
    }
    
    func changeRadiusTo(newRadius: CGFloat){
        
        UIView.animateWithDuration(0.7, delay: 0.1, options: .CurveEaseOut, animations: {
                self.frame.size.width = newRadius
                self.frame.size.height = newRadius
                self.frame.origin = CGPoint(x: self.myOriginX - newRadius/2, y: self.myOriginY - newRadius/2)
            }, completion: { finished in
            })
    }
}