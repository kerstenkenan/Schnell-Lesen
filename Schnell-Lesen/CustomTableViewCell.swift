//
//  CustomTableViewCell.swift
//  Schnell-Lesen
//
//  Created by Kersten Weise on 28.01.19.
//  Copyright © 2019 Kersten Weise. All rights reserved.
//

import UIKit

class CustomTableViewCell: UITableViewCell {
    @IBOutlet weak var datumLabel: UILabel!
    @IBOutlet weak var punkteLabel: UILabel!
    @IBOutlet weak var minutenLabel: UILabel!
    @IBOutlet weak var rundenLabel: UILabel!
    @IBOutlet weak var namenLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        namenLabel.adjustsFontSizeToFitWidth = true
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
