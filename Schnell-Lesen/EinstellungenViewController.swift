//
//  ViewController.swift
//  Schnell-Lesen
//
//  Created by Kersten Weise on 19.03.18.
//  Copyright © 2018 Kersten Weise. All rights reserved.
//

import UIKit
import Speech
import CoreData

class EinstellungenViewController: UIViewController {
    @IBOutlet var buchstaben: [meinButton]!
    @IBOutlet var minutenArray: [meinButton]!
    @IBOutlet weak var alleBuchstaben: meinButton!
    @IBOutlet weak var zehnMinButton: meinButton!
    @IBOutlet weak var zwanzigMinButton: meinButton!
    @IBOutlet weak var dreissigMinButton: meinButton!
    @IBOutlet weak var kindButton: UIButton!
    @IBOutlet weak var kindErwachsenerButton: UIButton!
    @IBOutlet weak var anleitungButton: UIButton!
    @IBOutlet weak var sentencesButton: meinButton!
    
    var grau : UIColor!
    var zeit : Int?
    
    var container : NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    override func viewDidLoad() {
        super.viewDidLoad()
        grau = buchstaben[0].backgroundColor
        buchstaben.sort{$0.tag < $1.tag}
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.buchstaben.forEach({ (button) in
                        if button.tag == 23 || button.tag == 24 {
                            return
                        } else {
                            button.isEnabled = true
                        }
                    })
                case .denied, .restricted, .notDetermined:
                    let OKAction = UIAlertAction(title: "OK", style: .default)
                    let fehler = UIAlertController(title: "Fehler", message: "Die Spracherkennung konnte nicht initializiert werden. Ohne Spracherkennung funktioniert diese App nicht. Gehe in Einstellungen/Datenschutz/Spracherkennung & Mikrofon und erlaube jeweils die Spracherkennung und den Mikrofon-Zugriff für diese App.", preferredStyle: .alert)
                    fehler.addAction(OKAction)
                    self.present(fehler, animated: true)
                }
            }
        }
        
        AVCaptureDevice.requestAccess(for: .audio) { (granted) in
            if granted {
                DispatchQueue.main.async { [weak self] in
                    self?.buchstaben.forEach({ (button) in
                        if button.tag == 23 || button.tag == 24 {
                            return
                        } else {
                            button.isEnabled = true
                        }
                    })
                    self?.anleitungAnzeigen()
                }
            } else {
                DispatchQueue.main.async {
                    let OKAction = UIAlertAction(title: "OK", style: .default)
                    let fehler = UIAlertController(title: "Fehler", message: "Ohne Zugriff auf das interne Mikrophon funktioniert diese App nicht. Gehe in Einstellungen/Datenschutz/Spracherkennung & Mikrofon und erlaube jeweils die Spracherkennung und den Mikrofon-Zugriff für diese App.", preferredStyle: .alert)
                    fehler.addAction(OKAction)
                    self.present(fehler, animated: true)
                }
            }
        }
    }
    
    func anleitungAnzeigen() {
        if UserDefaults.standard.bool(forKey: "AnleitungOnce") {
            return
        } else {
            DispatchQueue.main.async {
                UserDefaults.standard.set(true, forKey: "AnleitungOnce")
                UserDefaults.standard.synchronize()
                
                let anleitungsVC = self.storyboard?.instantiateViewController(withIdentifier: "AnleitungPageVC") as! AnleitungPageViewController
                anleitungsVC.modalPresentationStyle = .overCurrentContext
                self.present(anleitungsVC, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func resultButtonPressed(_ sender: Any) {
        if let ergebnisTableViewVC = self.storyboard?.instantiateViewController(withIdentifier: "naviVC") {
            ergebnisTableViewVC.modalPresentationStyle = .fullScreen
            self.present(ergebnisTableViewVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func atoZPushed(_ sender: Any) {
        pushButton(button: sender as! meinButton, buttons: buchstaben)
    }
    
    @IBAction func alleBuchstabenPushed(_ sender: Any) {
        pushButton(button: sender as! meinButton, buttons: buchstaben)
    }
    
    @IBAction func zehnMinButtonPushed(_ sender: Any) {
        pushButton(button: sender as! meinButton, buttons: buchstaben)
    }
    
    @IBAction func zwanzigMinButtonPushed(_ sender: Any) {
        pushButton(button: sender as! meinButton, buttons: buchstaben)
    }
    
    @IBAction func dreissigMinButtonPushed(_ sender: Any) {
        pushButton(button: sender as! meinButton, buttons: buchstaben)
    }
    
    func pushButton(button: UIButton, buttons: [UIButton]) {
        switch button.tag {
        case 26:
            toggleSwitch(button: button, grau: grau)
            if button.backgroundColor == .cyan {
                for i in 0..<buttons.count {
                    buttons[i].isEnabled = false
                    buttons[i].backgroundColor = grau
                }
                sentencesButton.backgroundColor = grau
            } else {
                for i in 0..<buttons.count {
                    buttons[i].isEnabled = true
                }
                buttons[23].isEnabled = false
                buttons[24].isEnabled = false
            }
            break
        case 27, 28, 29:
            switch button.tag {
            case 27: zeit = 10
            case 28: zeit = 20
            case 29: zeit = 30
            default: break
            }
            toggleSwitch(button: button, grau: nil)
            for i in 0..<minutenArray.count {
                if minutenArray[i].tag != button.tag {
                    minutenArray[i].backgroundColor = nil
                }
            }
        case 30, 31:
            button.isSelected = true
        case 32:
            toggleSwitch(button: button, grau: grau)
            if button.backgroundColor == .cyan {
                for i in 0..<buttons.count {
                    buttons[i].isEnabled = false
                    buttons[i].backgroundColor = grau
                }
                alleBuchstaben.backgroundColor = grau
            } else {
                for i in 0..<buttons.count {
                    buttons[i].isEnabled = true
                }
                buttons[23].isEnabled = false
                buttons[24].isEnabled = false
            }
            break
        default:
            toggleSwitch(button: button, grau: self.grau)
        }
    }
    
    func toggleSwitch(button: UIButton, grau: UIColor?) {
        if button.backgroundColor == .cyan {
            if button.tag == 27 || button.tag == 28 || button.tag == 29 {
                zeit = nil
            }
            button.backgroundColor = grau
        } else {
            button.backgroundColor = .cyan
        }
    }
    
    
    func auswaehlen() -> [String] {
        let alphDic = [buchstaben[0]: ABC.alphA, buchstaben[1]: ABC.alphB, buchstaben[2]: ABC.alphC, buchstaben[3]: ABC.alphD, buchstaben[4]: ABC.alphE, buchstaben[5]: ABC.alphF, buchstaben[6]: ABC.alphG, buchstaben[7]: ABC.alphH, buchstaben[8]: ABC.alphI, buchstaben[9]: ABC.alphJ, buchstaben[10]: ABC.alphK, buchstaben[11]: ABC.alphL, buchstaben[12]: ABC.alphM, buchstaben[13]: ABC.alphN, buchstaben[14]: ABC.alphO, buchstaben[15]: ABC.alphP, buchstaben[16]: ABC.alphQ, buchstaben[17]: ABC.alphR, buchstaben[18]: ABC.alphS, buchstaben[19]: ABC.alphT, buchstaben[20]: ABC.alphU, buchstaben[21]: ABC.alphV, buchstaben[22]: ABC.alphW, buchstaben[25]: ABC.alphZ]
        
        var woerter = [String]()
        
        for i in 0..<buchstaben.count {
            if buchstaben[i].backgroundColor == UIColor.cyan {
                if let newArr = (alphDic[buchstaben[i]]) {
                    woerter += newArr
                }
            }
        }
        
        if alleBuchstaben.backgroundColor == UIColor.cyan {
            woerter = ABC.grundwortschatz
        }
        return woerter
    }
    
    @IBAction func benutzerButtonTapped(_ sender: UIBarButtonItem) {
        if let benutzerVC = storyboard?.instantiateViewController(withIdentifier: "BenutzerPopViewController") {
            benutzerVC.modalPresentationStyle = .popover
            benutzerVC.popoverPresentationController?.barButtonItem = sender
            self.present(benutzerVC, animated: true)
        }
    }
    
    @IBAction func sentencesButtonPushed(_ sender: Any) {
        pushButton(button: (sender as! UIButton), buttons: buchstaben)
    }
    
    
    @IBAction func weiterButtonPushed(_ sender: Any) {
        if sentencesButton.backgroundColor == .cyan {
            performSegue(withIdentifier: "SentencesSegue", sender: nil)
        } else {
            performSegue(withIdentifier: "WordsSegue", sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SentencesSegue" {
            let testingSentencesVC = segue.destination as! TestingSentencesViewController
            if let zeitIntervall = zeit {
                testingSentencesVC.min = zeitIntervall
            } else {
                testingSentencesVC.min = 5
            }
        } else if segue.identifier == "WordsSegue" {
            let woerter = auswaehlen()
            if woerter.isEmpty {
                let OKAction = UIAlertAction(title: "OK", style: .default) { action in
                    return
                }
                let alert = UIAlertController(title: "Uups!", message: "Bitte triff eine Auswahl", preferredStyle: .alert)
                alert.addAction(OKAction)
                self.present(alert, animated: true)
            }
            let testingVC = segue.destination as! TestingViewController
            testingVC.woerter = woerter
            if let zeitIntervall = zeit {
                testingVC.min = zeitIntervall
            } else {
                testingVC.min = 5
            }
        }
    }
}
