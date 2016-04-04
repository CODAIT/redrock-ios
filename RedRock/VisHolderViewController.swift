//
//  VisHolderViewController.swift
//  RedRock
//
//  Created by Jonathan Alter on 10/9/15.
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

class VisHolderViewController: UIViewController {

    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var holderView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment if vis should be closed when tapped anywhere
        // let clickGesture = UITapGestureRecognizer(target: self, action: "removeView")
        // view.addGestureRecognizer(clickGesture)
    }

    @IBAction func closeButtonClicked(sender: UIButton) {
        removeView()
    }
    
    func removeView() {
        willMoveToParentViewController(nil)
        view.removeFromSuperview()
        removeFromParentViewController()
    }
    
    func addVisualisationController(vc: UIViewController) {
        vc.view.frame = CGRectMake(0, 0, holderView.bounds.size.width, holderView.bounds.size.height)
        
        self.addChildViewController(vc)
        holderView.addSubview(vc.view)
        vc.didMoveToParentViewController(self)
    }

}
