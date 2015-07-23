//
//  ChartHelpDecriptionTableViewCell.swift
//  RedRock
//
//  Created by Barbara Gomes on 7/21/15.
//  Copyright (c) 2015 IBM. All rights reserved.
//

import UIKit

class ChartHelpDecriptionTableViewCell: UITableViewCell {

    @IBOutlet weak var chartDescriptionLabel: UILabel!
    @IBOutlet weak var chartTitleLabel: UILabel!
    @IBOutlet weak var chartIconImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}