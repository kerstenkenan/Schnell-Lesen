//
//  meinButton.swift
//  Schnell-Lesen
//
//  Created by Kersten Weise on 04.05.18.
//  Copyright © 2018 Kersten Weise. All rights reserved.
//

import UIKit
@IBDesignable
class meinButton : UIButton {

    @IBInspectable var cornerRadius : CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
    @IBInspectable var hintergrundfarbe : UIColor? = nil {
        didSet {
            self.backgroundColor = hintergrundfarbe
        }
    }
    
    @IBInspectable var textfarbe : UIColor? = nil {
        didSet {
            self.tintColor = textfarbe
        }
    }
    @IBInspectable var bild_selected : UIImage? = nil {
        didSet {
            self.setImage(bild_selected, for: .selected)
        }
    }
    @IBInspectable var bild_normal : UIImage? = nil {
        didSet {
        self.setImage(bild_normal, for: .normal)
        }
    }
    
    override func awakeFromNib() {
        self.layer.shadowOffset = CGSize(width: 2.4, height: 2.4)
        self.layer.shadowColor = UIColor.gray.cgColor
        self.layer.shadowRadius = 1.3
        self.layer.shadowOpacity = 5.8
    }
}
