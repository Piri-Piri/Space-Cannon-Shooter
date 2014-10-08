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
    var menu: Menu!
    var cannon: SKSpriteNode!
    var ammoDisplay: SKSpriteNode!
    var scoreLabel: SKLabelNode!
    
    var bounceSound: SKAction!
    var deepExplosionSound: SKAction!
    var explosionSound: SKAction!
    var laserSound: SKAction!
    var zapSound: SKAction!
    
    var ammoValue: Int = 0 // private value
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
    
    var scoreValue: Int = 0 // private value
    var score: Int {
        set {
            scoreValue = newValue
            scoreLabel.text = "Score: \(scoreValue)"
        }
        get {
            return scoreValue
        }
    }
    
    var isGameOver: Bool = true

    let kShootSpeed: CGFloat = 1000.0
    let kHaloLowAngle: CGFloat  = 200.0 * CGFloat(M_PI) / 180.0;
    let kHaloHighAngle: CGFloat  = 340.0 * CGFloat(M_PI) / 180.0;
    let KHaloSpeed: CGFloat = 100.0
    
    let kHaloCategory:UInt32 = 0x1 << 0
    let kBallCategory:UInt32 = 0x1 << 1
    let kEdgeCategory:UInt32 = 0x1 << 2
    let kShieldCategory:UInt32 = 0x1 << 3
    let kLifeBarCategory:UInt32 = 0x1 << 4
    
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
        self.addChild(cannon)
        
        // Add a rotate action for the cannon
        let rotateCannon = SKAction.sequence([SKAction.rotateByAngle(CGFloat(M_PI), duration: 2.0), SKAction.rotateByAngle(CGFloat(-M_PI), duration: 2.0)])
        cannon.runAction(SKAction.repeatActionForever(rotateCannon))
        
        
        // Add a spawn halos action
        let spawnHalos = SKAction.sequence([SKAction.waitForDuration(2, withRange: 1), SKAction.runBlock({self.spawnHalo()})])
        self.runAction(SKAction.repeatActionForever(spawnHalos))
        
        
        // Add Ammo Status
        ammoDisplay = SKSpriteNode(imageNamed: "Ammo5")
        ammoDisplay.anchorPoint = CGPointMake(0.5, 0.0)
        ammoDisplay.position = cannon.position
        self.addChild(ammoDisplay)
        
        let incrementAmmo = SKAction.sequence([SKAction.waitForDuration(1), SKAction.runBlock({ self.ammo += 1 })])
        self.runAction(SKAction.repeatActionForever(incrementAmmo))
        
        // Setup Score Label
        scoreLabel = SKLabelNode(fontNamed: "DIN Alternate")
        scoreLabel.position = CGPointMake(15, 10)
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        scoreLabel.fontSize = 15.0
        self.addChild(scoreLabel)
        
        // Setup Sounds
        bounceSound = SKAction.playSoundFileNamed("Bounce.caf", waitForCompletion: false)
        deepExplosionSound = SKAction.playSoundFileNamed("DeepExplosion.caf", waitForCompletion: false)
        explosionSound = SKAction.playSoundFileNamed("Explosion.caf", waitForCompletion: false)
        laserSound = SKAction.playSoundFileNamed("Laser.caf", waitForCompletion: false)
        zapSound = SKAction.playSoundFileNamed("Zap.caf", waitForCompletion: false)
        
        // Setup Menu
        menu = Menu()
        menu.position = CGPointMake(view.frame.size.width * 0.5, view.frame.height - 220)
        self.addChild(menu)
        
        // Set initial values
        ammo = 5
        score = 0
        isGameOver = true
        scoreLabel.hidden = true
    }
    
    func newGame() {
        scoreLabel.hidden = false
        isGameOver = false
        menu.hidden = true
        ammo = 5
        score = 0
        
        mainLayer.removeAllChildren()
        
        // Add Shields
        for var i = 0; i < 6; i++ {
            let shield = SKSpriteNode(imageNamed: "Block")
            shield.name = "shield"
            shield.position = CGPointMake(35.0 + (50.0 * CGFloat(i)), 90)
            shield.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(42, 9))
            shield.physicsBody?.categoryBitMask = kShieldCategory
            shield.physicsBody?.collisionBitMask = 0
            mainLayer.addChild(shield)
        }
        // Add a Lifebar
        let lifeBar = SKSpriteNode(imageNamed: "BlueBar")
        lifeBar.position = CGPointMake(self.view!.frame.size.width * 0.5, 70)
        lifeBar.physicsBody = SKPhysicsBody(edgeFromPoint: CGPointMake(-lifeBar.size.width * 0.5, 0), toPoint: CGPointMake(lifeBar.size.width * 0.5, 0))
        lifeBar.physicsBody?.categoryBitMask = kLifeBarCategory
        mainLayer.addChild(lifeBar)
    }
    
    func gameOver() {
        mainLayer.enumerateChildNodesWithName("halo", usingBlock: { (node, stop) -> Void in
            self.addHaloExplosionToPosition(node.position)
            node.removeFromParent()
        })
        mainLayer.enumerateChildNodesWithName("ball", usingBlock: { (node, stop) -> Void in
            node.removeFromParent()
        })
        mainLayer.enumerateChildNodesWithName("shield", usingBlock: { (node, stop) -> Void in
            node.removeFromParent()
        })
        
        
        menu.score = score
        if score > menu.topScore {
            menu.topScore = score
        }
        menu.hidden = false
        scoreLabel.hidden = true
        isGameOver = true
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        /* Called when a touch begins */
        
        for touch: AnyObject in touches {
            //let location = touch.locationInNode(self)
            if !isGameOver {
                didShoot = true
            }
        }
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        for touch: AnyObject in touches {
            //let location = touch.locationInNode(self)
            if isGameOver {
                let touchedNode = menu.nodeAtPoint(touch.locationInNode(menu))
                if touchedNode.name == "Play" {
                    newGame()
                }
            }
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
            ball.physicsBody?.contactTestBitMask = kEdgeCategory
            self.runAction(laserSound)
            
            ammo--
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
        halo.physicsBody?.contactTestBitMask = kBallCategory | kShieldCategory | kLifeBarCategory | kEdgeCategory
        
        mainLayer.addChild(halo)
    }
    
    func addBounceExplosionToPosition(position: CGPoint) {
        //let explosionPath = NSBundle.mainBundle().pathForResource("BounceExplosion", ofType: "sks")
        //var explosion = NSKeyedUnarchiver.unarchiveObjectWithFile(explosionPath!) as SKEmitterNode
        
        var explosion = SKEmitterNode()
        explosion.particleTexture = SKTexture(imageNamed: "Ball")
        explosion.particleLifetime = 1
        explosion.particleBirthRate = 2000
        explosion.numParticlesToEmit = 100
        explosion.emissionAngle = 0
        explosion.emissionAngleRange = 360
        explosion.particleScale = 0.2
        explosion.particleScaleRange = 0.2
        explosion.particleScaleSpeed = -0.2
        explosion.particleSpeed = 200
        explosion.particleSpeedRange = 200
        
        explosion.position = position
        mainLayer.addChild(explosion)
    }
    
    func addHaloExplosionToPosition(position: CGPoint) {
        //let explosionPath = NSBundle.mainBundle().pathForResource("HaloExplosion", ofType: "sks")
        //var explosion = NSKeyedUnarchiver.unarchiveObjectWithFile(explosionPath!) as SKEmitterNode
        
        var explosion = SKEmitterNode()
        explosion.particleTexture = SKTexture(imageNamed: "Halo")
        explosion.particleLifetime = 1
        explosion.particleBirthRate = 2000
        explosion.numParticlesToEmit = 100
        explosion.emissionAngle = 0
        explosion.emissionAngleRange = 360
        explosion.particleScale = 0.2
        explosion.particleScaleRange = 0.2
        explosion.particleScaleSpeed = -0.2
        explosion.particleSpeed = 200
        explosion.particleSpeedRange = 200
        
        explosion.position = position
        mainLayer.addChild(explosion)
        
        let removeExplosion = SKAction.sequence([SKAction.waitForDuration(1.5), SKAction.removeFromParent()])
        explosion.runAction(removeExplosion)
    }
    
    func addLifeBarExplosionToPosition(position: CGPoint) {
        //let explosionPath = NSBundle.mainBundle().pathForResource("LifeBarExplosion", ofType: "sks")
        //var explosion = NSKeyedUnarchiver.unarchiveObjectWithFile(explosionPath!) as SKEmitterNode
        
        var explosion = SKEmitterNode()
        explosion.particleTexture = SKTexture(imageNamed: "BlueBar")
        explosion.particleLifetime = 1
        explosion.particleBirthRate = 5000
        explosion.numParticlesToEmit = 800
        explosion.emissionAngle = 90
        explosion.emissionAngleRange = 360
        explosion.particleScale = 0.1
        explosion.particleScaleRange = 0.2
        explosion.particleScaleSpeed = -0.4
        explosion.particleSpeed = 300
        explosion.particleSpeedRange = 200
        
        explosion.position = position
        mainLayer.addChild(explosion)
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
        
        if firstBody.categoryBitMask == kHaloCategory && secondBody.categoryBitMask == kEdgeCategory {
            // halo bounce effect an the side egdes
            if firstBody.node != nil {
                self.runAction(zapSound)
            }
        }
        
        if firstBody.categoryBitMask == kBallCategory && secondBody.categoryBitMask == kEdgeCategory {
            // ball bounce effect an the side egdes
            if firstBody.node != nil {
                self.addBounceExplosionToPosition(firstBody.node!.position)
                self.runAction(bounceSound)
            }
        }
        
        if firstBody.categoryBitMask == kHaloCategory && secondBody.categoryBitMask == kBallCategory {
            // Collision halo and ball
            if firstBody.node != nil {
                self.addHaloExplosionToPosition(firstBody.node!.position)
                self.runAction(explosionSound)
            }
            
            firstBody.node?.removeFromParent()
            secondBody.node?.removeFromParent()
            score++
        }
        
        if firstBody.categoryBitMask == kHaloCategory && secondBody.categoryBitMask == kShieldCategory {
            // Collision halo and shield
            if firstBody.node != nil {
                self.addHaloExplosionToPosition(firstBody.node!.position)
                self.runAction(explosionSound)
            }
            
            firstBody.node?.removeFromParent()
            secondBody.node?.removeFromParent()
        }
        
        if firstBody.categoryBitMask == kHaloCategory && secondBody.categoryBitMask == kLifeBarCategory {
            // Collision halo and lifebar
            if firstBody.node != nil {
                self.addLifeBarExplosionToPosition(secondBody.node!.position)
                self.runAction(deepExplosionSound)
            }
            
            secondBody.node?.removeFromParent()
            gameOver()
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
