//
//  GameScene.swift
//  Space Cannon Shooter
//
//  Created by David Pirih on 05.10.14.
//  Copyright (c) 2014 Piri-Piri. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    var mainLayer: SKNode!
    var cannon: SKSpriteNode!

    let kShootSpeed: CGFloat = 1000.0
    let kHaloLowAngle: CGFloat  = 200.0 * CGFloat(M_PI) / 180.0;
    let kHaloHighAngle: CGFloat  = 340.0 * CGFloat(M_PI) / 180.0;
    let KHaloSpeed : CGFloat = 100.0

    
    var didShoot = false
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        // Turn off gravity 
        self.physicsWorld.gravity = CGVectorMake(0.0, 0.0)
        
        // Add the background
        let background = SKSpriteNode(imageNamed: "Starfield")
        background.position = CGPointZero
        background.anchorPoint = CGPointZero
        background.blendMode = SKBlendMode.Replace
        
        self.addChild(background)
        
        // Add Edges
        let leftEdge = SKNode.node()
        leftEdge.physicsBody = SKPhysicsBody(edgeFromPoint: CGPointZero, toPoint: CGPointMake(0.0, view.frame.size.height))
        leftEdge.position = CGPointZero
        self.addChild(leftEdge)
        let rightEdge = SKNode.node()
        rightEdge.physicsBody = SKPhysicsBody(edgeFromPoint: CGPointZero, toPoint: CGPointMake(0.0, view.frame.size.height))
        rightEdge.position = CGPointMake(view.frame.size.width, 0.0)
        self.addChild(rightEdge)
        
        // Add the MainLayer
        mainLayer = SKNode.node()
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
        
        
        mainLayer.addChild(halo)
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
