//
//  InfoViewController.swift
//  RedRock
//
//  Created by Barbara Gomes on 7/21/15.
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

class InfoViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //self.tableView.rowHeight = UITableViewAutomaticDimension
        //self.tableView.estimatedRowHeight = 150
        
        self.preferredContentSize = CGSizeMake(350,600)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Config.visualizationTitles.count + 1
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        if indexPath.row == 0
        {
            return CGFloat(45)
        }
        else
        {
            
            let label:UILabel = UILabel(frame: CGRectMake(0, 0, 230, CGFloat.max))
            label.numberOfLines = 0
            label.lineBreakMode = NSLineBreakMode.ByWordWrapping
            label.font = UIFont(name: "HelveticaNeue-Medium", size: 14)
            label.text = Config.visualizationDescription[indexPath.row-1]
            label.sizeToFit()
            return (label.frame.height + 80)
            
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
       if indexPath.row != 0
        {
            let cellDescription = tableView.dequeueReusableCellWithIdentifier("ChartHelpCell", forIndexPath: indexPath) as! ChartHelpDecriptionTableViewCell
        
            cellDescription.chartTitleLabel.text = Config.visualizationTitles[indexPath.row-1]
            cellDescription.chartIconImage.image = UIImage(named: Config.visualizationButtons[indexPath.row-1])
            cellDescription.chartDescriptionLabel.text = Config.visualizationDescription[indexPath.row-1]
            //cellDescription.chartDescriptionLabel.numberOfLines = 0
            return cellDescription
        }
        else
        {
            let cell = tableView.dequeueReusableCellWithIdentifier("TitleCell", forIndexPath: indexPath) 
            cell.backgroundColor = Config.lightGrayColor
            cell.frame.height
            
            return cell
        }
    }

}
