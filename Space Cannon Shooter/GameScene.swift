//
//  GameScene.swift
//  Space Cannon Shooter
//
//  Created by David Pirih on 05.10.14.
//  Copyright (c) 2014 Piri-Piri. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var mainLayer: SKNode!
    var cannon: SKSpriteNode!
    var ammoDisplay: SKSpriteNode!
    
    var ammoValue: Int = 5 // private value
    var ammo: Int {
        set {
            if newValue >= 0 && newValue <= 5 {
                ammoValue = newValue
                ammoDisplay.texture = SKTexture(imageNamed: "Ammo\(ammoValue)")
            }
        }
        get {
            return ammoValue
        }
    }

    let kShootSpeed: CGFloat = 1000.0
    let kHaloLowAngle: CGFloat  = 200.0 * CGFloat(M_PI) / 180.0;
    let kHaloHighAngle: CGFloat  = 340.0 * CGFloat(M_PI) / 180.0;
    let KHaloSpeed: CGFloat = 100.0
    
    let kHaloCategory:UInt32 = 0x1 << 0
    let kBallCategory:UInt32 = 0x1 << 1
    let kEdgeCategory:UInt32 = 0x1 << 2
    
    var didShoot = false
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        // Turn off gravity 
        self.physicsWorld.gravity = CGVectorMake(0.0, 0.0)
        self.physicsWorld.contactDelegate = self
        
        // Add the background
        let background = SKSpriteNode(imageNamed: "Starfield")
        background.position = CGPointZero
        background.anchorPoint = CGPointZero
        background.blendMode = SKBlendMode.Replace
        
        self.addChild(background)
        
        // Add Edges
        let leftEdge = SKNode()
        leftEdge.physicsBody = SKPhysicsBody(edgeFromPoint: CGPointZero, toPoint: CGPointMake(0.0, view.frame.size.height))
        leftEdge.physicsBody?.categoryBitMask = kEdgeCategory
        leftEdge.position = CGPointZero
        self.addChild(leftEdge)
        let rightEdge = SKNode()
        rightEdge.physicsBody = SKPhysicsBody(edgeFromPoint: CGPointZero, toPoint: CGPointMake(0.0, view.frame.size.height))
        rightEdge.physicsBody?.categoryBitMask = kEdgeCategory
        rightEdge.position = CGPointMake(view.frame.size.width, 0.0)
        self.addChild(rightEdge)
        
        // Add the MainLayer
        mainLayer = SKNode()
        self.addChild(mainLayer)
        
        // Add the Cannon
        cannon = SKSpriteNode(imageNamed: "Cannon")
        cannon.position = CGPointMake(view.frame.size.width * 0.5, 0.0)
        mainLayer.addChild(cannon)
        
        // Add a rotate action for the cannon
        let rotateCannon = SKAction.sequence([SKAction.rotateByAngle(CGFloat(M_PI), duration: 2.0), SKAction.rotateByAngle(CGFloat(-M_PI), duration: 2.0)])
        cannon.runAction(SKAction.repeatActionForever(rotateCannon))
        
        
        // Add a spawn halos action
        let spawnHalos = SKAction.sequence([SKAction.waitForDuration(2, withRange: 1), SKAction.runBlock({self.spawnHalo()})])
        self.runAction(SKAction.repeatActionForever(spawnHalos))
        
        
        // Display Ammo Status
        ammoDisplay = SKSpriteNode(imageNamed: "Ammo5")
        ammoDisplay.anchorPoint = CGPointMake(0.5, 0.0)
        ammoDisplay.position = cannon.position
        mainLayer.addChild(ammoDisplay)
        
        let incrementAmmo = SKAction.sequence([SKAction.waitForDuration(1), SKAction.runBlock({ self.ammo += 1 })])
        self.runAction(SKAction.repeatActionForever(incrementAmmo))
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        /* Called when a touch begins */
        
        for touch: AnyObject in touches {
            let location = touch.locationInNode(self)
            
            didShoot = true
        }
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
    
    override func didSimulatePhysics() {
        /* remove ball that are out of the screen due game performence */
        
        if didShoot {
            self.shoot()
            didShoot = false
        }
        
        mainLayer.enumerateChildNodesWithName("ball", usingBlock: { (node, stop) -> Void in
            if !CGRectContainsPoint(self.frame, node.position) {
                node.removeFromParent()
            }
        })
    }
 
    func shoot() {
        if ammo > 0 {
            ammo--
            
            let ball =  SKSpriteNode(imageNamed: "Ball")
            var rotationVector = radiansToVector(cannon.zRotation)
            ball.name = "ball"
            ball.position = CGPointMake(cannon.position.x + (cannon.size.width * 0.5 * rotationVector.dx),
                cannon.position.y + (cannon.size.width * 0.5 * rotationVector.dy));
            mainLayer.addChild(ball)
            
            ball.physicsBody = SKPhysicsBody(circleOfRadius: 6.0)
            ball.physicsBody?.velocity = CGVectorMake(rotationVector.dx * kShootSpeed, rotationVector.dy * kShootSpeed)
            ball.physicsBody?.restitution = 1.0
            ball.physicsBody?.linearDamping = 0.0
            ball.physicsBody?.friction = 0.0
            
            ball.physicsBody?.categoryBitMask = kBallCategory
            ball.physicsBody?.collisionBitMask = kEdgeCategory
        }
    }
    
    func spawnHalo() {
        let halo = SKSpriteNode(imageNamed: "Halo")
        halo.name = "halo"
        halo.position = CGPointMake(randomInRange(halo.size.width * 0.5, high: self.frame.width - (halo.size.width * 0.5)), self.frame.height + (halo.size.height * 0.5))
        halo.physicsBody = SKPhysicsBody(circleOfRadius: 16.0)
        
        var direction = radiansToVector(randomInRange(kHaloLowAngle, high: kHaloHighAngle))
        halo.physicsBody?.velocity = CGVectorMake(direction.dx * KHaloSpeed, direction.dy * KHaloSpeed)
        halo.physicsBody?.restitution = 1.0
        halo.physicsBody?.linearDamping = 0.0
        halo.physicsBody?.friction = 0.0
        
        halo.physicsBody?.categoryBitMask = kHaloCategory
        halo.physicsBody?.collisionBitMask = kEdgeCategory | kHaloCategory
        halo.physicsBody?.contactTestBitMask = kBallCategory
        
        
        mainLayer.addChild(halo)
    }
    
    
    func addExplosionToPosition(position: CGPoint) {
        //let explosionPath = NSBundle.mainBundle().pathForResource("HaloExplosion", ofType: "sks")
        //var explosion = NSKeyedUnarchiver.unarchiveObjectWithFile(explosionPath!) as SKEmitterNode
        
        var explosion = SKEmitterNode()
        explosion.particleTexture = SKTexture(imageNamed: "Halo")
        explosion.particleLifetime = 1;
        explosion.particleBirthRate = 2000;
        explosion.numParticlesToEmit = 100;
        explosion.emissionAngleRange = 360;
        explosion.particleScale = 0.2;
        explosion.particleScaleSpeed = -0.2;
        explosion.particleSpeed = 200;
        
        explosion.position = position
        mainLayer.addChild(explosion)
        
        let removeExplosion = SKAction.sequence([SKAction.waitForDuration(1.5), SKAction.removeFromParent()])
        explosion.runAction(removeExplosion)
    }

    // MARK: SKPhysicsContactDelegate 
    
    func didBeginContact(contact: SKPhysicsContact) {
        var firstBody:SKPhysicsBody
        var secondBody:SKPhysicsBody
        
        /* Ensure that the halo is the firstBody */
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        }
        else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if firstBody.categoryBitMask == kHaloCategory && secondBody.categoryBitMask == kBallCategory {
            
            self.addExplosionToPosition(firstBody.node!.position)
            
            firstBody.node?.removeFromParent()
            secondBody.node?.removeFromParent()
        }
    }
    
    // MARK: Helper Functions
    
    private func radiansToVector(radians : CGFloat) -> CGVector
    {
        let vector : CGVector = CGVectorMake(cos(radians), sin(radians))
        return vector
    }
    
    private func randomInRange(low : CGFloat, high : CGFloat) -> CGFloat
    {
        let value = CGFloat(arc4random_uniform(UINT32_MAX)) / CGFloat(UINT32_MAX)
        return value * (high - low) + low
    }
    

}
