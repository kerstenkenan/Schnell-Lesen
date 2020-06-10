//
//  FehlerAnzeigeViewController.swift
//  Schnell-Lesen
//
//  Created by Kersten Weise on 13.02.20.
//  Copyright © 2020 Kersten Weise. All rights reserved.
//

import UIKit

class FehlerAnzeigeViewController: UIViewController {

    @IBOutlet weak var fehlerLabel: UILabel!
        
    var anzeigeText : String?
    
    var ergebnisVC : ErgebnisViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let anzeigeText = anzeigeText {
            fehlerLabel.text = anzeigeText
        }
    }
    
    @IBAction func letsGoButtonTapped(_ sender: Any) {
        NotificationCenter.default.post(name: .FehlerAnzeigeGotDismissed, object: self)
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func cancelButtonTapped(_ sender: Any) {
        NotificationCenter.default.post(name: .ShouldEnterIntoDatabase, object: self)
        ergebnisVC.modalPresentationStyle = .fullScreen
        self.present(ergebnisVC, animated: true, completion: nil)
    }
}

extension Notification.Name {
    static let FehlerAnzeigeGotDismissed = Notification.Name("FehlerAnzeigeGotDismissed")
    static let ShouldEnterIntoDatabase = Notification.Name(rawValue: "ShouldEnterIntoDatabase")
}
