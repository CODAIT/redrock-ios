//
//  RangeSliderViewController.swift
//  RedRock
//
//  Created by Jonathan Alter on 10/8/15.
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
    
    func resetViewController() {
        rangeSlider.lowerValue = 0.0
        rangeSlider.upperValue = 1.0
    }

}
