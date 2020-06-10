//
//  Siegel.swift
//  Schnell-Lesen
//
//  Created by Kersten Weise on 27.10.18.
//  Copyright © 2018 Kersten Weise. All rights reserved.
//

import UIKit
import SpriteKit

class Siegel: SKSpriteNode {
    var skscene : SKScene!
    var image = UIImage(named: "certificate-161050_1280")!
    
    init(anzahlRundenStr: Int, pos: CGPoint, xScale: CGFloat, yScale: CGFloat, zRotation: CGFloat?, skscene: SKScene) {
        self.skscene = skscene
        super.init(texture: SKTexture(image: image), color: UIColor(white: 1, alpha: 0), size: image.size)
        self.position = pos
        self.xScale = xScale
        self.yScale = yScale
        self.zPosition = 1
        if let zRotation = zRotation {
        self.zRotation = zRotation
        self.name = "siegelNode"
        }
        let anzahlRunden = SKLabelNode(text: "\(anzahlRundenStr)")
        anzahlRunden.fontName = "Helvetica-Bold"
        anzahlRunden.fontSize = 220
        anzahlRunden.fontColor = UIColor.yellow
        anzahlRunden.position.y += 30
        anzahlRunden.position.x += 30
        anzahlRunden.zPosition = 2
        self.addChild(anzahlRunden)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func siegelSetzen() {
        skscene.addChild(self)
    }
}
