//
//  RangeSliderViewController.swift
//  RedRock
//
//  Created by Jonathan Alter on 10/8/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import UIKit

class RangeSliderViewController: UIViewController {
    
    @IBOutlet weak var sliderHolder: UIView!
    
    var rangeSlider: RangeSliderUIControl!

    override func viewDidLoad() {
        super.viewDidLoad()

        rangeSlider = RangeSliderUIControl(frame: CGRectMake(0, 0, 314, 22))
        rangeSlider.trackTintColor = UIColor.clearColor()
        rangeSlider.trackHighlightTintColor = Config.darkBlueColorV2
        rangeSlider.thumbTintColor = Config.darkBlueColorV2
        
        sliderHolder.addSubview(rangeSlider)
    }

}
