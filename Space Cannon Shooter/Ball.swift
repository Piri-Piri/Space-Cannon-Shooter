//
//  Ball.swift
//  Space Cannon Shooter
//
//  Created by David Pirih on 08.10.14.
//  Copyright (c) 2014 Piri-Piri. All rights reserved.
//

import UIKit
import SpriteKit

class Ball: SKSpriteNode {
   
    var trail: SKEmitterNode?

    func updateTrail() {
        if trail != nil {
            trail!.position = self.position
        }
    }
    
    override func removeFromParent() {
        if trail != nil {
            self.trail!.particleBirthRate = 0.0
            
            let effectDuration = Double(self.trail!.particleLifetime) + Double(self.trail!.particleLifetimeRange)
            let removeTrail = SKAction.sequence([SKAction.waitForDuration(effectDuration), SKAction.removeFromParent()])
            self.runAction(removeTrail)
        }
        super.removeFromParent()
    }
    
    
}
