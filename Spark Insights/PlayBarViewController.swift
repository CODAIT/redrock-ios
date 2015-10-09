//
//  PlayProgressViewController.swift
//  RedRock
//
//  Created by Jonathan Alter on 10/9/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import UIKit

@objc
protocol PlayBarViewControllerDelegate {
    optional func playPauseClicked() // Called when play or pause is clicked
}

enum PlayBarState {
    case Playing
    case Paused
}

class PlayBarViewController: UIViewController {
    
    @IBOutlet weak var progressBarHolder: UIView!
    @IBOutlet weak var progressBar: UIView!
    @IBOutlet weak var progressBarLeadingEdge: NSLayoutConstraint!
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    
    weak var delegate: PlayBarViewControllerDelegate?
    
    // Usage Example: playBar.progress = 45.5
    var progress: Float = 0 {
        didSet {
            guard progress >= 0 && progress <= 100 else {
                Log("Invalid progress \(progress) should be 0-100")
                return
            }
            updateProgress()
        }
    }
    // Usage Example: playBar.state = PlayBarState.Play
    var state: PlayBarState = .Paused {
        didSet {
            self.updateState()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        playButton.hidden = true
        updateState()
    }
    
    @IBAction func buttonClicked(sender: UIButton) {
        // self.state = (self.state == .Play) ? .Pause : .Play
        guard delegate != nil else {
            Log("No deleget set for PlayBarViewController")
            return
        }
        delegate?.playPauseClicked!()
    }
    
    private func updateProgress() {
        progressBarLeadingEdge.constant = CGFloat(progress) * (progressBarHolder.frame.size.width / 100)
    }
    
    private func updateState() {
        switch state {
        case .Playing:
            playButton.hidden = true
            pauseButton.hidden = false
        case .Paused:
            playButton.hidden = false
            pauseButton.hidden = true
        }
    }
}
