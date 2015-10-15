//
//  VisHolderViewController.swift
//  RedRock
//
//  Created by Jonathan Alter on 10/9/15.
//  Copyright © 2015 IBM. All rights reserved.
//

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
