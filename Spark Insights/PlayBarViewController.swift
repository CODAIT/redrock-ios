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
    optional func scrubberScrubbed( progress : Float ) // Called when the scrubber position is changed
}

enum PlayBarState {
    case Playing
    case Paused
}

class PlayBarViewController: UIViewController {
    
    @IBOutlet weak var progressBarHolder: UIView!
    @IBOutlet weak var progressBar: UIView!
    @IBOutlet weak var progressBarLeadingEdge: NSLayoutConstraint!
    @IBOutlet weak var slider: UISlider!
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var dateLabel: UILabel!
    
    weak var delegate: PlayBarViewControllerDelegate?
    
    var playOnTouchEnd = false
    
    // Usage Example: playBar.date = NSDate()
    var date: NSDate? {
        didSet {
            let dateStringFormatter = NSDateFormatter()
            dateStringFormatter.dateFormat = Config.dateFormatMonthDay
            dateLabel.text = dateStringFormatter.stringFromDate(date!)
        }
    }
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

        setupSlider()
        
        playButton.hidden = true
        updateState()
    }
    
    @IBAction func buttonClicked(sender: UIButton) {
        // self.state = (self.state == .Play) ? .Pause : .Play
        guard delegate != nil else {
            Log("No delegate set for PlayBarViewController")
            return
        }
        guard playOnTouchEnd == false else {
            // Can't press play while scrubbing
            return
        }
        delegate?.playPauseClicked!()
    }
    
    private func updateProgress() {
        let prog = CGFloat(progress) * (progressBarHolder.frame.size.width / 100)
        progressBarLeadingEdge.constant = prog
        if !slider.selected {
            slider.setValue((progress / 100), animated: false)   
        }
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
    
    private func setupSlider() {
        // All parts of the slider need to be clear
        slider.setThumbImage(UIImage(), forState: .Normal)
        slider.setMinimumTrackImage(UIImage(), forState: .Normal)
        slider.setMaximumTrackImage(UIImage(), forState: .Normal)
    }
    
    @IBAction func sliderTapped(gesture: UIGestureRecognizer) {
        updateSliderForGesture(gesture)
    }
    
    @IBAction func sliderPan(gesture: UIPanGestureRecognizer) {
        switch (gesture.state) {
        case .Began:
            pauseDurringGesture()
        case .Cancelled, .Ended, .Failed:
            playAfterGesture()
        default:
            break
        }
        
        updateSliderForGesture(gesture)
    }
    
    func updateSliderForGesture(gesture: UIGestureRecognizer) {
        let s = gesture.view as! UISlider
        if s.highlighted {
            return // If handle is selected, let it do its job
        }
        let point = gesture.locationInView(s)
        let percent = point.x / s.bounds.size.width
        let delta = Float(percent) * (s.maximumValue - s.minimumValue)
        let value = s.minimumValue + delta
        s.setValue(value, animated: true)
        sliderValueChanged(s)
    }
    
    @IBAction func sliderTouchDown(sender: UISlider) {
        pauseDurringGesture()
    }
    
    @IBAction func sliderTouchUp(sender: UISlider) {
        playAfterGesture()
    }
    
    func pauseDurringGesture() { //TODO: spelling
        if state == .Playing {
            playOnTouchEnd = true
            delegate?.playPauseClicked!()
        }
    }
    
    func playAfterGesture() {
        if playOnTouchEnd {
            playOnTouchEnd = false
            if state == .Paused {
                delegate?.playPauseClicked!()
            }
        }
    }
    
    @IBAction func sliderValueChanged(sender: UISlider) {
        delegate?.scrubberScrubbed!( sender.value )
    }
}
