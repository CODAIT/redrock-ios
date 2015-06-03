//
//  SearchMenuTableViewCell.swift
//  Spark Insights
//
//  Created by Barbara Gomes on 6/3/15.
//  Copyright (c) 2015 IBM. All rights reserved.
//

import UIKit

class SearchMenuTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func willTransitionToState(state: UITableViewCellStateMask) {
        if state == UITableViewCellStateMask.ShowingEditControlMask
        {
            println("here")
        }
    }

}
