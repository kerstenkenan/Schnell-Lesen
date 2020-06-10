//
//  AnleitungSeiten.swift
//  Schnell-Lesen
//
//  Created by Kersten Weise on 20.12.18.
//  Copyright © 2018 Kersten Weise. All rights reserved.
//

import UIKit

class AnleitungSeiten: UIViewController {
    
    @IBAction func zurueckTap(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
}
