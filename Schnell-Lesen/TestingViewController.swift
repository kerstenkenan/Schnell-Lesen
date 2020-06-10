//
//  TestingViewController.swift
//  Schnell-Lesen
//
//  Created by Kersten Weise on 22.05.18.
//  Copyright © 2018 Kersten Weise. All rights reserved.
//

import UIKit
import Speech
import GameplayKit
import AVFoundation
import AudioToolbox
import CoreData

class TestingViewController: UIViewController, SCNPhysicsContactDelegate, NSFetchedResultsControllerDelegate, UINavigationBarDelegate {
    // MARK: IBOulets
    
    @IBOutlet weak var WortLabel: UILabel!
    @IBOutlet weak var SpracherkennungErgebnisLabel: UILabel!
    @IBOutlet weak var punkteLabel: UILabel!
    @IBOutlet weak var zeitLabel: UILabel!
    @IBOutlet weak var richtigButton: meinButton!
    @IBOutlet weak var punkteBalken: SCNView!
    @IBOutlet weak var anzeigeStackView: UIStackView!
    @IBOutlet weak var skViewEinfuehrung: SKView!
    @IBOutlet weak var speakingImageView: UIImageView!
    
    //MARK: SpeechRecognition
    
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "de"))
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    var inputNode : AVAudioInputNode?
    var audioSession = AVAudioSession.sharedInstance()
    var klack : AVAudioPlayer!
    var bell : AVAudioPlayer!
    private var winSound : AVAudioPlayer!
    
    // MARK: Word properties
    
    var woerter = [String]()
    var alteWoerter = [String]()
    var neuesWort : String? {
        var wort : String?
        if !woerter.isEmpty {
            let zufallGen = GKRandomDistribution(lowestValue: 0, highestValue: woerter.count - 1)
            let stelle = zufallGen.nextInt()
            
            wort = woerter[stelle]
            if let wort = wort {
                alteWoerter.append(wort)
            }
            woerter.remove(at: stelle)
            if woerter.isEmpty {
                woerter = alteWoerter
                alteWoerter.removeAll()
            }
        }
        return wort
    }
    var wort : String?
    var animationen = [UIViewPropertyAnimator?]()
    var versuch = 0
    
    // MARK: Time properties
    
    var sek = 0
    var minuten = 0
    var min = 0
    var passedMinutes = 0
    weak var t1 : Timer?
    private weak var t2 : Timer?
    weak var t3 : Timer?
    weak var t4 : Timer?
    var t3Interval = 14.0
    
    // MARK: Animation properties
    
    let einblendZeitNormal = 0.4
    let einblendZeitSchnell = 0.3
    let einblendDelay = 0.3
    let ausblendZeitNormal = 0.4
    let ausblendZeitSchnell = 0.3
    let ausblendDelay = 0.3
    
    // MARK: Points
    
    var punkte = 0
    
    // MARK: Scenekit properties
    
    let ausgangsPosition = SCNVector3(-19.5, 1.5, 0)
    var pos : SCNVector3!
    let farbe = [UIColor.yellow, UIColor.green, UIColor.red, UIColor.blue]
    var abcStelle = 0
    
    private var scene : SCNScene!
    private var textnode : BuchstabeNode!
    private var textnodeArray = [SCNNode]()
    
    private var siegel : Siegel!
    private var siegelSzene : SKScene!
    private var anzahlRunden : SKLabelNode!
    private var schritte : CGFloat = 25.0
    
    var skScene : SKScene!
    
    // MARK: Core Data
    
    lazy var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
//    lazy var frc : NSFetchedResultsController<Fehler>? = {
//        var resultController : NSFetchedResultsController<Fehler>?
//        let request : NSFetchRequest<Fehler> = Fehler.fetchRequest()
//        request.sortDescriptors = [NSSortDescriptor(key: "datum", ascending: false)]
//        if let context = container?.viewContext {
//            resultController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
//            resultController?.delegate = self
//            do {
//                try resultController?.performFetch()
//            } catch let err {
//                print("NSFetchedResultsController couldn't fetch any results: \(err)")
//            }
//        }
//        return resultController
//    }()
    

    
    // MARK: Observers
    
    var backObserver : NSObjectProtocol?
    var didResignObserver : NSObjectProtocol?
    var shouldEnterIntoDatabase : NSObjectProtocol?
    
    
    // MARK: Others
    
    var fehler = [String]()
    
    var durchgaenge = 1
    var anzahlGedrueckt = 3
    
    var label : UILabel?
    
    var anzeigeZuEnde = false
    var fehlerAngezeigt = false
    var readyToGo = false
    var timeOver = false
    
    let soundID : SystemSoundID = 1022
    
    
    // MARK: LifeCycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var counter = 0

        richtigButton.layer.cornerRadius = richtigButton.frame.size.width/2
        
        minuten = min
        pos = ausgangsPosition
        
        scene = SCNScene(named: "Buchstabenszene.scn", inDirectory: "scenes.scnassets", options: nil)
        scene.physicsWorld.contactDelegate = self
        
        punkteBalken.allowsCameraControl = false
        punkteBalken.autoenablesDefaultLighting = true
        punkteBalken.showsStatistics = false
        punkteBalken.scene = scene
        punkteBalken.prepare(scene, shouldAbortBlock: nil)
        
        siegelSzene = SKScene(size: CGSize(width: punkteBalken.bounds.width, height: punkteBalken.bounds.height))
        siegelSzene.isPaused = false
        punkteBalken.overlaySKScene = siegelSzene
        
        skScene = SKScene(size: CGSize(width: skViewEinfuehrung.bounds.width, height: skViewEinfuehrung.bounds.height))
        skScene.backgroundColor = .clear
        skScene.isPaused = false
        skViewEinfuehrung.backgroundColor = .clear
        skViewEinfuehrung.presentScene(skScene)
        
        try? klack = AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "Klack", ofType: "m4a")!))
        klack.volume = 0.3
        klack.prepareToPlay()
        
        try? bell = AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "nextRoundBell", ofType: "mp3")!))
        bell.volume = 0.2
        bell.prepareToPlay()
        
        try? winSound = AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "win", ofType: "wav")!))
        winSound.volume = 0.1
        winSound.prepareToPlay()
        
        for buchstabe in ABC.abc {
            initLetter(letter: buchstabe as NSString, farbe: farbe[counter], pos: pos)
            pos.x += 1.5
            if counter >= 3 {
                counter = 0
            } else {
                counter += 1
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        backObserver = NotificationCenter.default.addObserver(forName: .FehlerAnzeigeGotDismissed, object: nil, queue: OperationQueue.main, using: { _ in
            self.gotBack()
        })
        didResignObserver = NotificationCenter.default.addObserver(forName: .UIApplicationWillResignActive, object: nil, queue: nil, using: { _ in
            self.eintragenInDatenbank(self.passedMinutes)
        })
        shouldEnterIntoDatabase = NotificationCenter.default.addObserver(forName: .ShouldEnterIntoDatabase, object: nil, queue: nil, using: { _ in
            self.eintragenInDatenbank(self.min)
        })
        
        checkSystemVolume(audiosession: audioSession)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        badgeUI(number: anzahlGedrueckt)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let observer = backObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = didResignObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = shouldEnterIntoDatabase {
            NotificationCenter.default.removeObserver(observer)
        }
        animationenStoppen()
        t1?.invalidate()
        t2?.invalidate()
        t3?.invalidate()
        t4?.invalidate()
        t1 = nil
        t2 = nil
        t3 = nil
        t4 = nil
        klack?.stop()
        bell?.stop()        
        klack = nil
        bell = nil
    }
    
    // MARK: Prepare methods
    
    func checkSystemVolume(audiosession: AVAudioSession) {
        if audiosession.outputVolume < 0.4 {
            let OKButton = UIAlertAction(title: "OK", style: .default) { (action) in
                self.vorZaehlen()
            }
            let alert = UIAlertController(title: "Achtung!", message: "Die Lautstärke deines iPads ist zu leise eingestellt. Bitte verändere die Lautstärke so, dass Du auch alle Hinweistöne gut hören kannst.", preferredStyle: .alert)
            alert.addAction(OKButton)
            self.present(alert, animated: true)
        } else {
            vorZaehlen()
        }
    }
    
    func vorZaehlen() {
        self.readyToGo = false
        var zaehler = 1
        let zahl = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        zahl.fontSize = 100
        zahl.fontColor = .red
        zahl.position = CGPoint(x: skScene.frame.midX, y: skScene.frame.midY - 20)
        zahl.alpha = 0
        skScene.addChild(zahl)
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let playCount = SKAction.playSoundFileNamed("count.mp3", waitForCompletion: false)
        let fadeInOut = SKAction.sequence([playCount,fadeIn, fadeOut])
        
        t4 = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self](timer) in
            if zaehler >= 4 {
                self?.readyToGo = true
                self?.start(str: nil)
                self?.startClock()
                Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { (timer) in
                    self?.richtigButton.isEnabled = true
                })
                timer.invalidate()
            } else {
                zahl.text = String(zaehler)
                zahl.run(fadeInOut)
                zaehler += 1
            }
        }
    }
    
    // MARK: animation methods
    
    func start(str: String?) {
        animieren(label: self.WortLabel, wort: str, einblendZeit: self.einblendZeitNormal, ausblendZeit: self.ausblendZeitNormal, scaleX: nil, scaleY: nil, delay: 1, nurAnzeigen: false)
    }
    
    func animieren(label: UILabel, wort: String?, einblendZeit: TimeInterval, ausblendZeit: TimeInterval, scaleX: CGFloat?, scaleY: CGFloat?, delay: TimeInterval, nurAnzeigen: Bool, completion: ((UIViewAnimatingPosition) -> Void)? = nil) {
        animationen.removeAll()
        let anim1 : UIViewPropertyAnimator!
        let anim2 : UIViewPropertyAnimator!
        
        anim1 = UIViewPropertyAnimator(duration: einblendZeit, curve: .linear, animations: {
            if !self.fehlerAngezeigt {
                if wort != nil {
                    label.text = wort
                } else {
                    self.wort = self.neuesWort
                    label.text = self.wort
                }
            } else {
                if wort != nil {
                    label.text = wort
                } else {
                    if self.fehler.isEmpty && self.fehlerAngezeigt {
                        self.animationenStoppen()
                        self.eintragenInDatenbank(self.min)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            if let ergebnisVC = self.storyboard?.instantiateViewController(withIdentifier: "ErgebnisViewController") as? ErgebnisViewController {
                                ergebnisVC.punkte = self.punkte
                                ergebnisVC.durchgaenge = self.durchgaenge
                                ergebnisVC.minuten = self.min
                                ergebnisVC.modalPresentationStyle = .fullScreen
                                self.present(ergebnisVC, animated: true)
                            }
                        }
                    } else {
                        self.wort = self.fehler.first
                        label.text = self.wort
                    }
                }
            }
            label.textColor = .black
            label.alpha = 1.0
            if let factorX = scaleX {
                if let factorY = scaleY {
                    label.transform = CGAffineTransform.identity.scaledBy(x: factorX, y: factorY)
                }
            }
        })
        anim1.isInterruptible = true
        anim2 = UIViewPropertyAnimator(duration: ausblendZeit, curve: .linear, animations: {
            label.alpha = 0
            if let factorX = scaleX {
                if let factorY = scaleY {
                    label.transform = CGAffineTransform.identity.scaledBy(x: factorX / factorX, y: factorY / factorY)
                }
            }
        })
        anim2.isInterruptible = true
        anim2.addCompletion { [weak self] (pos) in
            if !nurAnzeigen {
                do {
                    try self?.startRecording()
                } catch {
                    print("Couldn't record anything")
                }
            }
            if let completionHandler = completion {
                completionHandler(pos)
            }
        }
        anim1.addCompletion { (pos) in
            anim2.startAnimation()
        }
        animationen.append(anim1)
        animationen.append(anim2)
        anim1.startAnimation(afterDelay: delay)
    }
    
    // Recording method
    
    func startRecording() throws {
        if let realSpeechRecognizer = speechRecognizer {
            if realSpeechRecognizer.isAvailable {
                speakingImageView.isHidden = false
                // Cancel the previous task if it's running.
                if let recognitionTask = recognitionTask {
                    recognitionTask.cancel()
                    self.recognitionTask = nil
                }
                
                try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
                try audioSession.setMode(AVAudioSessionModeMeasurement)
                try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
                
                recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
                inputNode = audioEngine.inputNode
                guard let recognitionRequest = recognitionRequest else {
                    print("Unable to created a SFSpeechAudioBufferRecognitionRequest object")
                    return
                }
                
                // Configure request so that results are returned before audio recording is finished
                recognitionRequest.shouldReportPartialResults = true
                
                // A recognition task represents a speech recognition session.
                // We keep a reference to the task so that it can be cancelled.
                
                
                t3 = Timer.scheduledTimer(withTimeInterval: t3Interval, repeats: false, block: { (timer) in
                    self.ergebnisStimmtNicht(icon: "👎")
                })
                self.recognitionTask = realSpeechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] (result, error) in
                    self?.checkResult(result: result, error: error)
                }
                
                let recordingFormat = inputNode?.outputFormat(forBus: 0)
                inputNode?.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
                    self.recognitionRequest?.append(buffer)
                }
                
                audioEngine.prepare()
                try audioEngine.start()
            } else {
                let OKButton = UIAlertAction(title: "OK", style: .default)
                let alert = UIAlertController(title: "Achtung!", message: "Es scheint keine Internetverbindung zu bestehen. Ohne Verbindung zum Internet funktioniert die Spracherkennung nicht.", preferredStyle: .alert)
                alert.addAction(OKButton)
                self.present(alert, animated: true)
            }
        }
    }
    
    // Check methods
    
    func checkResult(result: SFSpeechRecognitionResult?, error: Error?) {
        if let result = result {
            let bestResult = result.bestTranscription.formattedString
            if let vorhandenesWort = self.wort {
                let umgewandeltesWort = self.umwandeln(wort: vorhandenesWort)
                if bestResult.count >= umgewandeltesWort.count {
                    print("Umgewandeltes Wort: \(umgewandeltesWort)")
                    print("Ergebnis: \(bestResult)")
                    if bestResult.localizedCaseInsensitiveContains(umgewandeltesWort) {
                        self.t3?.invalidate()
                        DispatchQueue.main.async {
                            self.ergebnisStimmt(icon: "👍")
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.ergebnisStimmtNicht(icon: "👎", word: umgewandeltesWort, result: bestResult)
                        }
                    }
                }
            }
        }
        if let error = error {
            print("Fehler: \(error.localizedDescription)")
        }
    }
    
    func umwandeln(wort: String) -> String {
        var wort = wort
        
        ABC.ausnahmen.forEach { (key, value) in
            if key == wort {
                wort = value
            }
        }
        wort = wort.replacingOccurrences(of: "/", with: " ")
        wort = wort.replacingOccurrences(of: "(", with: "")
        wort = wort.replacingOccurrences(of: ")", with: "")
        
        return wort
    }
    
    // MARK: Stopping methods
    
    func aufnahmeStoppen() {
        speakingImageView.isHidden = true
        audioEngine.stop()
        recognitionTask?.cancel()
        inputNode?.removeTap(onBus: 0)
        recognitionRequest = nil
        recognitionTask = nil
        t3?.invalidate()
    }
    
    func animationenStoppen() {
        aufnahmeStoppen()
        if !animationen.isEmpty {
            for i in 0..<animationen.count {
                animationen[i]!.stopAnimation(true)
                animationen[i] = nil
            }
        }
        animationen.removeAll()
        SpracherkennungErgebnisLabel?.text = ""
        WortLabel?.text = ""
    }
    
    // MARK: Result methods
    
    func ergebnisStimmt(icon: String) {
        anzeigeZuEnde = false
        versuch = 0
        aufnahmeStoppen()
        print("ergebnisStimmt")
        animieren(label: SpracherkennungErgebnisLabel, wort: icon, einblendZeit: einblendZeitSchnell, ausblendZeit: ausblendZeitSchnell, scaleX: 3.0, scaleY: 3.0, delay: 0, nurAnzeigen: true) { (pos) in
            self.setLetter()
            self.anzeigeZuEnde = true
            if self.fehlerAngezeigt && !self.fehler.isEmpty {
                self.fehler.removeFirst()
            }
            self.animieren(label: self.WortLabel, wort: nil, einblendZeit: self.einblendZeitNormal, ausblendZeit: self.ausblendZeitNormal, scaleX: nil, scaleY: nil, delay: 1, nurAnzeigen: false)
        }
    }
    
    func ergebnisStimmtNicht(icon: String, word: String? = nil, result: String? = nil) {
        anzeigeZuEnde = false
        aufnahmeStoppen()
        print("ergebnisStimmtNicht")
        versuch += 1
        
        animieren(label: SpracherkennungErgebnisLabel, wort: icon, einblendZeit: einblendZeitSchnell, ausblendZeit: ausblendZeitSchnell, scaleX: 3.0, scaleY: 3.0, delay: 0, nurAnzeigen: true) { (pos) in
            self.weitereVersuche(versuch: self.versuch, word: self.wort, result: result)
        }
    }
    
    func weitereVersuche(versuch: Int, word: String?, result: String?) {
        switch versuch {
        case 1, 2:
            self.animieren(label: self.WortLabel, wort: word, einblendZeit: self.einblendZeitNormal, ausblendZeit: self.ausblendZeitNormal, scaleX: nil, scaleY: nil, delay: 1, nurAnzeigen: false)
        case 3:
            if let word = word {
                if !self.fehlerAngezeigt {
                    fehler.append(word)
                }
            }
            if self.fehlerAngezeigt && !self.fehler.isEmpty {
                self.fehler.removeFirst()
            }

            DispatchQueue.main.async {
                self.animieren(label: self.WortLabel, wort: nil, einblendZeit: self.einblendZeitNormal, ausblendZeit: self.ausblendZeitNormal, scaleX: nil, scaleY: nil, delay: 1, nurAnzeigen: false)
            }
            self.versuch = 0
        default: break
        }
        anzeigeZuEnde = true
    }
    
    // Count points
       
       func punkteZaehlen() {
           var zaehler = 0
           t2 = Timer.scheduledTimer(withTimeInterval: 0.025, repeats: true, block: { (timer) in
               zaehler += 1
               self.klack?.play()
               self.punkteLabel.text = String(self.punkte + zaehler)
               
               if zaehler >= 20 {
                   self.punkte += zaehler
                   self.klack?.stop()
                   zaehler = 0
                   self.t2?.invalidate()
               }
           })
       }
    
    //    func saveWrongResultsInCoreData(word: String, result: String) {
    //        container?.performBackgroundTask({ (context ) in
    //            let neuerFehler = Fehler(context: context)
    //            neuerFehler.datum = Date() as NSDate
    //            neuerFehler.deviceName = UIDevice().name
    //            neuerFehler.wort = "\(word)"
    //            neuerFehler.erkanntesWort = "\(result)"
    //            do {
    //                try context.save()
    //                print("Eintrag gespeichert")
    //            } catch let error {
    //                print("Eintrag nicht gespeichert: \(error)")
    //            }
    //        })
    //    }
    
    
    // MARK: SceneKit methods

    func setLetter() {
        var counter = 0
        if abcStelle >= 26 {
            abcStelle = 0
            pos = ausgangsPosition
            for nodes in textnodeArray {
                nodes.removeFromParentNode()
            }
            textnodeArray.removeAll()
            siegelErstellen()
            for buchstabe in ABC.abc {
                initLetter(letter: buchstabe as NSString, farbe: farbe[counter], pos: pos)
                pos.x += 1.5
                if counter >= 3 {
                    counter = 0
                } else {
                    counter += 1
                }
            }
        } else {
            textnodeArray[abcStelle].isHidden = false
            textnodeArray[abcStelle].runAction(SCNAction.move(to: SCNVector3(textnodeArray[abcStelle].position.x, -1.5, textnodeArray[abcStelle].position.z), duration: 0.5), completionHandler: {
                DispatchQueue.main.async {
                    self.punkteZaehlen()
                }
            })
        }
    }
    
    func siegelErstellen() {
        durchgaenge += 1
        siegel = Siegel(anzahlRundenStr: durchgaenge, pos: CGPoint(x: punkteLabel.bounds.minX + schritte, y: (punkteLabel.bounds.height / 2) + 5), xScale: 0.12, yScale: 0.12, zRotation: 30 * (.pi / 180), skscene: siegelSzene)
        siegel.siegelSetzen()
        bell.play()
        schritte += 30
    }
    
    func initLetter(letter: NSString, farbe: UIColor, pos: SCNVector3) {
        textnode = BuchstabeNode(buchstabe: letter, farbe: farbe, groesse: 8)
        textnode.position = pos
        textnode.scale = SCNVector3(x: 0.3, y: 0.3, z: 0.3)
        textnode.eulerAngles = SCNVector3(0,0,0)
        textnode.physicsBody!.isAffectedByGravity = false
        textnode.physicsBody!.mass = 0
        textnode.physicsBody!.restitution = 0
        textnode.physicsBody?.categoryBitMask = 1
        textnode.physicsBody?.contactTestBitMask = 2
        textnode.name = "textnode" + (letter as String)
        textnode.isHidden = false
        scene.rootNode.addChildNode(textnode)
        textnodeArray.append(textnode)
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        if contact.nodeA.name == "textnode" + ABC.abc[abcStelle] && contact.nodeB.name == "floor" {
            if let particle = scene.rootNode.childNode(withName: "firework", recursively: true)?.particleSystems?.first {
                particle.emitterShape = textnodeArray[abcStelle].geometry
                textnodeArray[abcStelle].addParticleSystem(particle)
            }
            winSound.play()
        }
        abcStelle += 1
    }
    
    // MARK: The clock
    
    @objc func ermittleZeit() {
        zeitLabel.alpha = 1
        timeOver = false
        if readyToGo {
            if minuten >= 0 && sek >= 0 {
                sek -= 1
                if sek < 0 {
                    sek = 59
                    minuten -= 1
                    passedMinutes += 1
                }
                self.zeitLabel.textColor = .black
                self.zeitLabel.text = "\(String(format: "%02d", minuten))" + " : " + "\(String(format: "%02d", sek))"
            }
            if minuten == 0 && sek <= 10 {
                self.zeitLabel.textColor = .red
                UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.3, delay: 0, options: .curveLinear, animations: {
                    self.zeitLabel.alpha = 1
                    self.zeitLabel.text = "\(String(format: "%02d", self.minuten))" + " : " + "\(String(format: "%02d", self.sek))"
                }) { (pos) in
                    if pos == .end{
                        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.3, delay: 0.2, options: .curveLinear, animations: {
                            self.zeitLabel.alpha = 0
                        })
                    }
                }
            }
            if minuten < 0 && sek == 59 {
                self.zeitLabel.textColor = .red
                UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.3, delay: 0, options: .curveLinear, animations: {
                    self.zeitLabel.alpha = 1
                    self.zeitLabel.text = "\(String(format: "%02d", 0))" + " : " + "\(String(format: "%02d", 0))"
                }) { (pos) in
                    if pos == .end {
                        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.3, delay: 0.2, options: .curveLinear, animations: {
                            self.zeitLabel.alpha = 0
                        })
                    }
                }
                timeOver = true
                if anzeigeZuEnde {
                    self.animationenStoppen()
                    if let ergebnisVC = self.storyboard?.instantiateViewController(withIdentifier: "ErgebnisViewController") as? ErgebnisViewController {
                        var wortVsSatz = String()
                        if self is TestingSentencesViewController {
                            wortVsSatz = self.fehler.count == 1 ? "Satz" : "Sätze"
                        } else {
                            wortVsSatz = self.fehler.count == 1 ? "Wort" : "Wörter"
                        }
                        ergebnisVC.punkte = punkte
                        ergebnisVC.durchgaenge = durchgaenge
                        ergebnisVC.minuten = min
                        
                        if !fehler.isEmpty && !fehlerAngezeigt {
                            t1?.invalidate()
                            if let fehlerVC = self.storyboard?.instantiateViewController(withIdentifier: "FehlerViewController") as? FehlerAnzeigeViewController {
                                fehlerVC.ergebnisVC = ergebnisVC
                                fehlerVC.anzeigeText = "Du hast \(self.fehler.count) \(wortVsSatz) nicht erkannt. Wenn du noch mehr Punkte machen möchtest, dann hast Du jetzt zwei weitere Minuten Zeit."
                                
                                fehlerVC.modalPresentationStyle = .overCurrentContext
                                self.present(fehlerVC, animated: true, completion: nil)
                            }
                        } else {
                            eintragenInDatenbank(min)
                            t1?.invalidate()
                            ergebnisVC.modalPresentationStyle = .fullScreen
                            self.present(ergebnisVC, animated: true, completion: nil)
                        }
                    }
                }
            }
        }
    }
    
    func startClock() {
        t1 = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.ermittleZeit), userInfo: nil, repeats: true)
    }
    
    // MARK: Button methods
    
    func badgeUI(number: Int) {
        if number < 0 {
            return
        } else {
            label = UILabel(frame: CGRect(x: richtigButton.frame.minX + 10, y: richtigButton.frame.minY, width: richtigButton.frame.width / 4, height: richtigButton.frame.height / 4))
            label!.font = UIFont.boldSystemFont(ofSize: 26)
            label!.layer.backgroundColor = UIColor.red.cgColor
            label!.textColor = .white
            label!.textAlignment = .center
            label!.layer.cornerRadius = label!.frame.height / 2
            label?.text = String(number)
            richtigButton.superview?.addSubview(label!)
        }
    }
    
    @IBAction func richtigButtonPushed(_ sender: Any) {
        animationenStoppen()
        ergebnisStimmt(icon: "👍")
        if anzahlGedrueckt <= 0 {
            richtigButton.isEnabled = false
        } else {
            anzahlGedrueckt -= 1
            badgeUI(number: anzahlGedrueckt)
        }
        if richtigButton.isEnabled {
            richtigButton.isEnabled = false
            Timer.scheduledTimer(withTimeInterval: 8, repeats: false) { [weak self] (timer) in
                self?.richtigButton.isEnabled = true
            }
        }
    }
    
    func gotBack() {
        minuten = 1
        anzahlGedrueckt = 1
        fehlerAngezeigt = true
        badgeUI(number: anzahlGedrueckt)
        vorZaehlen()
    }
    
    // MARK: Entry in database
     
    func eintragenInDatenbank(_ minutes: Int) {
        var ergebnis : Ergebnis!
        
        if let context = container?.viewContext {
            ergebnis = Ergebnis(context: context)
            ergebnis.benutzer = self.chooseUser(context: context)
            ergebnis.datum = Date() as NSDate
            ergebnis.minuten = Int32(minutes)
            ergebnis.punkte = Int32(self.punkte)
            ergebnis.runden = Int32(self.durchgaenge)
            if self is TestingSentencesViewController {
                ergebnis.words = false
            } else {
                ergebnis.words = true
            }
            try? context.save()
            if let eintraege = try? context.fetch(Ergebnis.fetchRequest()) as? [Ergebnis] {
                print("Anzahl Einträge: \(String(describing: eintraege!.count))")
            }
        }
    }
    
    func chooseUser(context: NSManagedObjectContext) -> Benutzer? {
        let request : NSFetchRequest<Benutzer> = Benutzer.fetchRequest()
        request.predicate = NSPredicate(format: "ausgewaehlt == TRUE")
        if let user = try? context.fetch(request) {
            if let benutzer = user.first {
                return benutzer
            }
        }
        return nil
    }
}
