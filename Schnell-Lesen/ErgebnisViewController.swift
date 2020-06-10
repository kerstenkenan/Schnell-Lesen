//
//  ErgebnisViewController.swift
//  Schnell-Lesen
//
//  Created by Kersten Weise on 01.07.18.
//  Copyright © 2018 Kersten Weise. All rights reserved.
//

import UIKit
import AVFoundation
import SceneKit
import SpriteKit
import CoreData

class ErgebnisViewController: UIViewController, SCNPhysicsContactDelegate, AVAudioPlayerDelegate, SKSceneDelegate {
    
    @IBOutlet weak var SKErgebnisView: SKView!
    @IBOutlet weak var AnimationsView: SCNView!
    
    var punkte = 0
    var durchgaenge = 0
    var minuten = 0
    var xPos = 0
    var zPos = 0
    var euler : Float = 25
    
    var count : AVAudioPlayer!
    var nextRoundBell : AVAudioPlayer!
    var planeCrash : SCNAudioSource!
    private var letterSound : SCNAudioSource!
    
    let scene = SCNScene(named: "Ergebnisszene.scn", inDirectory: "scenes.scnassets", options: nil)!
    var nodes = [SCNNode]()
    var siegelSzene : SKScene!
    var siegel : Siegel!
    let particle = SCNParticleSystem(named: "Feuerwerk.scnp", inDirectory: "scenes.scnassets")!
    let physicField : SCNPhysicsField = .linearGravity()
    var floor : SCNNode!
    var buchstabenArray : [BuchstabeNode] = []
    
    var skPunkte = SKLabelNode(fontNamed: "Verdana-Bold")
    var skRunden : SKLabelNode!
    var skMinuten : SKLabelNode!
    var spriteScene : SKScene!
    
    var counterIsRunning = false
    var counter = 0
    
    var lastCall : TimeInterval = 0
    var intervall = 0.0
    
    // MARK: Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
        
        try? count = AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "counting", ofType: "wav")!))
        count.volume = 0.1
        count.numberOfLoops = -1
        count.prepareToPlay()
        
        try? nextRoundBell = AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "nextRoundBell", ofType: "mp3")!))
        nextRoundBell.volume = 0.1
        nextRoundBell.prepareToPlay()
        
        letterSound = SCNAudioSource(fileNamed: "letter.wav")
        letterSound.volume = 0.6
        letterSound.load()
        
        planeCrash = SCNAudioSource(fileNamed: "planeCrash.mp3")
        planeCrash.volume = 0.3
        planeCrash.load()
        
        scene.background.contents = nil
        scene.physicsWorld.contactDelegate = self
        AnimationsView.allowsCameraControl = true
        AnimationsView.autoenablesDefaultLighting = true
        AnimationsView.backgroundColor = UIColor.clear
        AnimationsView.scene = scene
        AnimationsView.prepare(scene, shouldAbortBlock: nil)
        
        physicField.strength = 1
        floor = scene.rootNode.childNode(withName: "floor", recursively: true)
        floor.physicsField = physicField
        
        siegelSzene = SKScene(size: CGSize(width: AnimationsView.bounds.width, height: AnimationsView.bounds.height))
        siegelSzene.isPaused = false
        AnimationsView.overlaySKScene = siegelSzene
        
        spriteScene = SKScene(size: SKErgebnisView.bounds.size)
        spriteScene.isPaused = false
        spriteScene.backgroundColor = .clear
        spriteScene.delegate = self
        SKErgebnisView.backgroundColor = .clear
        SKErgebnisView.presentScene(spriteScene)
        
        skPunkte.fontColor = UIColor(#colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1))
        skPunkte.fontSize = 60
        skPunkte.position = CGPoint(x: spriteScene.frame.midX, y: spriteScene.frame.maxY - 60)
        skPunkte.text = "Punkte: \(counter)"
        spriteScene.addChild(skPunkte)
        
        let abc = ["A", "B", "C", "X"]
        for letter in abc {
            if let node = scene.rootNode.childNode(withName: letter, recursively: true) {
                node.isHidden = true
                nodes.append(node)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        punkteZaehlen()
    }
    
    // MARK: Credits methods
        
    func setLetter(node: SCNNode, sound: SCNAudioSource, particles: Bool, completion: (()->())? = nil) {
        if particles {
            particle.emitterShape = node.geometry
            node.addParticleSystem(particle)
        }
        node.isHidden = false
        node.runAction(SCNAction.move(to: SCNVector3(node.position.x, 0, node.position.z), duration: 1), completionHandler: {
            if let completion = completion {
                completion()
            }
        })
        node.runAction(SCNAction.playAudio(sound, waitForCompletion: false))
    }
    
    func showCredits() {
        let node1 = SKLabelNode(text: "Das war nichts!")
        let node2 = SKLabelNode(text: "Versuche es gleich nochmal")
        node1.fontName = "Verdana-Bold"
        node2.fontName = "Verdana-Bold"
        node1.fontSize = 60
        node2.fontSize = 55
        node1.fontColor = .red
        node2.fontColor = .orange
        
        node1.position = CGPoint(x: -400, y: 300)
        node2.position = CGPoint(x: 1550, y: 150)
        
        siegelSzene.addChild(node1)
        siegelSzene.addChild(node2)
        
        let action1 = bewegen(node: node1, x: 450)
        let action2 = bewegen(node: node2, x: 450)
        node1.run(action1) {
            node2.run(action2) {
                self.werteAnzeigen(szene: self.spriteScene)
            }
        }
    }
    
    func punkteZaehlen() {
        if punkte < 20 {
            setLetter(node: nodes.last!, sound: planeCrash, particles: false, completion: {
                self.showCredits()
            })
        } else {
            counterIsRunning = true
            count.play()
        }
    }
        
    func update(_ currentTime: TimeInterval, for scene: SKScene) {
        if counterIsRunning {
            self.counter += 2
            self.skPunkte.text = "Punkte: \(String(self.counter))"
            switch self.counter {
            case 20:
                self.setLetter(node: self.nodes[0], sound: self.letterSound, particles: true)
            case 520:
                self.setLetter(node: self.nodes[1], sound: self.letterSound, particles: true)
            case 1040:
                self.setLetter(node: self.nodes[2], sound: self.letterSound, particles: true)
            default:
                break
            }
            if self.counter >= self.punkte {
                self.count.stop()
                if self.durchgaenge > 3 {
                    self.siegelSetzen(self.durchgaenge)
                }
                counterIsRunning = false
                self.werteAnzeigen(szene: self.spriteScene)
            }
        }
    }
    
    func werteAnzeigen(szene: SKScene) {
        var nodesArr = [SKLabelNode]()
        
        skRunden = SKLabelNode(text: "Runden: \(String(durchgaenge))")
        skMinuten = SKLabelNode(text: "Minuten: \(String(minuten))")
        
        nodesArr.append(skRunden)
        nodesArr.append(skMinuten)
        
        let colors = [UIColor(#colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1)), UIColor(#colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1))]
        DispatchQueue.main.async {
            for i in 0..<nodesArr.count {
                nodesArr[i].fontName = "Verdana-Bold"
                nodesArr[i].fontSize = 60
                nodesArr[i].fontColor = colors[i]
            }
        }
        
        skRunden.position = CGPoint(x: szene.frame.maxX, y: szene.frame.midY)
        skMinuten.position = CGPoint(x: szene.frame.minX, y: szene.frame.minY + 40)
        skRunden.alpha = 0
        skMinuten.alpha = 0
        
        spriteScene.addChild(skRunden)
        spriteScene.addChild(skMinuten)
        
        let action1 = bewegen(node: skRunden, x: szene.frame.minX + 200)
        let action2 = bewegen(node: skMinuten, x: szene.frame.maxX - 200)
        skRunden.run(action1) {
            self.skMinuten.run(action2) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    if let navVC = self.storyboard?.instantiateViewController(withIdentifier: "naviVC") {
                        navVC.modalPresentationStyle = .fullScreen
                        self.present(navVC, animated: true, completion: nil)
                    }
                }
                
            }
        }
    }
    
    func bewegen(node: SKLabelNode, x: CGFloat) -> SKAction {
        let action = SKAction.moveTo(x: x, duration: 0.2)
        let soundAction = SKAction.playSoundFileNamed("swipe.mp3", waitForCompletion: true)
        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        let waitAction = SKAction.wait(forDuration: 1)
        let groupAction = SKAction.group([action, fadeIn, soundAction])
        let seqAction = SKAction.sequence([waitAction, groupAction])
        return seqAction
    }
    
    func siegelSetzen(_ anzahl: Int) {
        siegel = Siegel(anzahlRundenStr: anzahl, pos: CGPoint(x: AnimationsView.bounds.midX - 100, y: AnimationsView.bounds.minY + 80), xScale: 0.35, yScale: 0.35, zRotation: nil, skscene: siegelSzene)
        siegel.siegelSetzen()
        nextRoundBell.play()
    }
}
