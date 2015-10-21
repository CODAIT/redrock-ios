//
//  RightPickerViewController.swift
//  RedRock
//
//  Created by Jonathan Alter on 10/20/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import UIKit

class RightPickerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    weak var delegate: RightViewControllerDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - UITableViewDataSource

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Config.liveSearches.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PickerCell", forIndexPath: indexPath)
        
        let label = cell.contentView.viewWithTag(30) as! UILabel
        label.text = Config.liveSearches[indexPath.row]
        if indexPath.row == Config.liveCurrentSearchIndex {
            makeCellSelected(true, cell: cell)
        }

        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return CGFloat(62)
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        for c in tableView.visibleCells {
            makeCellSelected(false, cell: c)
        }
        makeCellSelected(true, cell: cell!)
        
        Config.liveCurrentSearchIndex = indexPath.row
        delegate.executeActionOnGoClicked(Config.liveSearches[indexPath.row])
    }
    
    // MARK: - Utils
    
    func makeCellSelected(selected: Bool, cell: UITableViewCell) {
        let label = cell.viewWithTag(30) as! UILabel
        label.textColor = selected ? Config.lightBlueTextColorV2 : Config.superLightBlueTextColorV2
    }
}
