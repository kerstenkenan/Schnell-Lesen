//
//  TestingSentencesViewController.swift
//  Schnell-Lesen
//
//  Created by Kersten Weise on 05.04.19.
//  Copyright © 2019 Kersten Weise. All rights reserved.
//

import Foundation
import SpriteKit
import GameplayKit
import AVFoundation
import Speech



class TestingSentencesViewController: TestingViewController, SKSceneDelegate {
    @IBOutlet weak var sliderLabel: UILabel!
    @IBOutlet weak var sliderLabel2: UILabel!
    @IBOutlet weak var newSentenceButton: meinButton!
    
    var sentence = String()
    
    var lastCall : TimeInterval = 0
    var nodeArr = [SKLabelNode]()
    var zaehler = -1
    var counter = 1
    var zwischenZeit : TimeInterval = 0
    
    var intervall = 0.3
    
    
    lazy var fadeIn = SKAction.fadeIn(withDuration: intervall)
    lazy var fadeOut = SKAction.fadeOut(withDuration: intervall)
    lazy var animSeq = SKAction.sequence([fadeIn,fadeOut])
        
    lazy var satzzeichenInWords = ["," : " Komma", "?" : " Fragezeichen", "!" : " Ausrufezeichen", "." : " Punkt", ":" : " Doppelpunkt", "'" : "Anführungszeichen"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sliderLabel.text = "Geschwindigkeit"
        sliderLabel2.text = "Länge"
        newSentenceButton.cornerRadius = newSentenceButton.frame.size.width / 2
        
        skScene.delegate = self
        fadeIn.timingMode = .easeOut
        fadeOut.timingMode = .easeIn
        
        Timer.scheduledTimer(withTimeInterval: 7, repeats: false, block: { (timer) in
            self.newSentenceButton.isEnabled = true
        })
    }
    
    // MARK: New animation for sentences
    
    override func checkResult(result: SFSpeechRecognitionResult?, error: Error?) {
        if let result = result {
            var bestResult = result.bestTranscription.formattedString
            satzzeichenLoop: for (key, value) in self.satzzeichenInWords {
                if bestResult.contains(key) {
                    bestResult = bestResult.replacingOccurrences(of: key, with: value)
                    break satzzeichenLoop
                }
            }
            nodeArr.forEach { (node) in
                var text = node.text
                text?.removeAll(where: { (self.satzzeichenInWords.keys.joined()).contains($0) })
                if bestResult.localizedCaseInsensitiveContains(text!) {
                    node.fontColor = .green
                    node.run(SKAction.fadeIn(withDuration: 0.4))
                }
            }
            if (self.nodeArr.allSatisfy({ $0.fontColor == .green })) {
                self.aufnahmeStoppen()
                if super.fehlerAngezeigt && !super.fehler.isEmpty {
                    super.fehler.removeFirst()
                }
                
                
                Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { (timer) in
                    let grp = SKAction.group([SKAction.scale(by: 2, duration: 0.4),SKAction.fadeOut(withDuration: 0.4)])
                    self.nodeArr.forEach({ (node) in
                        node.run(grp)
                    })
                    self.executeWin()
                }
            }
        }
    }
    
    func executeWin() {
        counter = 1
        aufnahmeStoppen()
        super.setLetter()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.start(str: nil)
        }
    }
    
    func moreTries(_ counter: Int, text: String) {
        let grp = SKAction.group([SKAction.scale(by: 1.5, duration: 0.4),SKAction.fadeOut(withDuration: 0.4)])
        self.nodeArr.forEach({ (node) in
            node.run(grp)
        })
        aufnahmeStoppen()
        if !super.timeOver {
            switch counter {
            case 1,2:
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.start(str: self.sentence)
                    self.counter += 1
                }
            default:
                if super.fehlerAngezeigt {
                    super.fehler.removeFirst()
                } else {
                    super.fehler.append(self.sentence)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.start(str: nil)
                    self.counter = 1
                }
            }
        }
    }
    
    override func ergebnisStimmtNicht(icon: String, word: String? = nil, result: String? = nil) {
        moreTries(counter, text: sentence)
    }
    
    func newSentence() -> String {
        let text = ABC.saetze
        var textArr = [String]()
        var str = String()
        for ch in text {
            switch ch {
            case ".", "?", "!":
                str.append(ch)
                textArr.append(str)
                str.removeAll()
            default:
                str.append(ch)
            }
        }
        for i in 0..<textArr.count {
            if textArr[i].first == " " {
                textArr[i].removeFirst()
            }
        }
        
        switch sliderLabel2.text {
        case "kurz":
            let shortSentence = textArr.filter { $0.count <= 50 }
            let index = GKRandomDistribution(lowestValue: 0, highestValue: shortSentence.count - 1).nextInt()
            return shortSentence[index]
        case "mittel":
            let middleSentence = textArr.filter { $0.count <= 100 }
            let index = GKRandomDistribution(lowestValue: 0, highestValue: middleSentence.count - 1).nextInt()
            return middleSentence[index]
        default:
            let index = GKRandomDistribution(lowestValue: 0, highestValue: textArr.count - 1).nextInt()
            return textArr[index]
        }
    }
    
    func arrangeNodes(sentence: String) {
        nodeArr.forEach({ (node) in
            node.run(SKAction.fadeOut(withDuration: 0.4))
        })
        self.nodeArr.removeAll()
        self.sentence.removeAll()
        let resultArr = sentence.split(separator: " ")
        var posX : CGFloat = 0
        var posY : CGFloat = skViewEinfuehrung.frame.midY
        for i in 0..<resultArr.count {
            let labelNode = SKLabelNode(text: String(resultArr[i]))
            
            labelNode.fontColor = .black
            labelNode.alpha = 0
            labelNode.fontName = "HelveticaNeue-Bold"
            labelNode.fontSize = 45
            labelNode.horizontalAlignmentMode = .left
            
            if (posX + labelNode.frame.width) > skViewEinfuehrung.frame.maxX {
                posX = 0
                posY -= 50
            }
            
            labelNode.position.x = posX
            labelNode.position.y = posY
            
            posX += labelNode.frame.width + 10
            
            skScene.addChild(labelNode)
            nodeArr.append(labelNode)
        }
        self.sentence = sentence
    }
    
    override func start(str: String?) {
        super.anzeigeZuEnde = false
        if super.fehlerAngezeigt {
            if super.fehler.isEmpty {
                super.animationenStoppen()
                super.eintragenInDatenbank(super.min)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if let ergebnisVC = self.storyboard?.instantiateViewController(withIdentifier: "ErgebnisViewController") as? ErgebnisViewController {
                        ergebnisVC.punkte = super.punkte
                        ergebnisVC.durchgaenge = super.durchgaenge
                        ergebnisVC.minuten = super.min
                        ergebnisVC.modalPresentationStyle = .fullScreen
                        self.present(ergebnisVC, animated: true, completion: nil)
                    }
                }
            } else {
                arrangeNodes(sentence: super.fehler.first!)
                self.zaehler = 0
            }
        } else {
            if let str = str {
                arrangeNodes(sentence: str)
                self.zaehler = 0
            } else {
                arrangeNodes(sentence: newSentence())
                self.zaehler = 0
            }
        }
    }
    
    func getNode(number: Int) -> SKLabelNode {
        return nodeArr[number]
    }
    
    func update(_ currentTime: TimeInterval, for scene: SKScene) {
        if lastCall == 0 {
            lastCall = currentTime
        } else if (currentTime-lastCall) > intervall {
            switch zaehler {
            case -1:
                break
            case nodeArr.count - 1:
                let node = getNode(number: zaehler)
                node.run(animSeq) {
                    super.anzeigeZuEnde = true
                    if !super.timeOver {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: {
                            do {
                                try super.startRecording()
                            } catch let err {
                                print("Could not record anything: \(err.localizedDescription)")
                            }
                        })
                    }
                }
                self.zaehler = -1
            default:
                let node = getNode(number: zaehler)
                node.run(animSeq)
                zaehler += 1
            }
            lastCall = 0
        }
    }
    
    override func richtigButtonPushed(_ sender: Any) {
        aufnahmeStoppen()
        nodeArr.forEach { (node) in
            node.run(SKAction.fadeOut(withDuration: 0.4))
        }
        nodeArr.removeAll()
        if super.anzahlGedrueckt <= 0 {
            super.richtigButton.isEnabled = false
        } else {
            super.anzahlGedrueckt -= 1
            super.badgeUI(number: super.anzahlGedrueckt)
        }
        if super.richtigButton.isEnabled {
            super.richtigButton.isEnabled = false
            Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] (timer) in
                self?.richtigButton.isEnabled = true
            }
        }
        start(str: sentence)
    }
    
    @IBAction func newSentenceButtonPushed(_ sender: Any) {
        aufnahmeStoppen()
        nodeArr.forEach { (node) in
            node.run(SKAction.fadeOut(withDuration: 0.4))
        }
        nodeArr.removeAll()
        
        newSentenceButton.isEnabled = false
        Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { (timer) in
            self.newSentenceButton.isEnabled = true
        }
        self.counter = 1
        start(str: nil)
    }
    
    @IBAction func sliderMoved(_ sender: UISlider) {
        switch sender.value {
        case 0...0.25:
            switch sender.tag {
            case 0:
                sliderLabel.text = "langsam"
                intervall = 0.6
            default:
                super.t3Interval = 10.0
                sliderLabel2.text = "kurz"
            }
        case 0.35...0.4:
            switch sender.tag {
            case 0:
                sliderLabel.text = "schnell"
                intervall = 0.3
            default:
                super.t3Interval = 18.0
                sliderLabel2.text = "lang"
            }
        default:            
            switch sender.tag {
            case 0:
                sliderLabel.text = "mittel"
                intervall = 0.4
            default:
                super.t3Interval = 14.0
                sliderLabel2.text = "mittel"
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        super.aufnahmeStoppen()
        zaehler = -1
    }
}
