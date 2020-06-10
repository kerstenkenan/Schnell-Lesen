//
//  BuchstabeNode.swift
//  Schnell-Lesen
//
//  Created by Kersten Weise on 24.10.18.
//  Copyright © 2018 Kersten Weise. All rights reserved.
//

import UIKit
import SceneKit

class BuchstabeNode: SCNNode {
    var buchstabe : NSString!
    var farbe : UIColor!
    var shape : SCNPhysicsShape!
    var groesse : CGFloat!
    
    init(buchstabe: NSString, farbe: UIColor, groesse: CGFloat) {
        super.init()
        self.buchstabe = buchstabe
        self.farbe = farbe
        self.groesse = groesse
        initNode()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initNode() {
        let text = SCNText(string: buchstabe, extrusionDepth: 2.5)
        text.font = UIFont.boldSystemFont(ofSize: self.groesse)
        text.firstMaterial?.lightingModel = .physicallyBased
        text.firstMaterial?.diffuse.contents = farbe
        text.chamferRadius = 1.75
        text.flatness = 0.17
        
        self.geometry = text
        self.name = "textnode" + String(buchstabe)
        shape = SCNPhysicsShape(geometry: SCNCone(topRadius: 0, bottomRadius: CGFloat(self.boundingBox.max.x), height: CGFloat(self.boundingBox.min.y)))
        self.physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape)
        self.physicsBody!.categoryBitMask = 1
        self.physicsBody!.collisionBitMask = 0
        self.physicsBody!.contactTestBitMask = 2        
    }
}
