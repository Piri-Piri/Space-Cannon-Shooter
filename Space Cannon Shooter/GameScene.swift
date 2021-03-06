//
//  GameScene.swift
//  Space Cannon Shooter
//
//  Created by David Pirih on 05.10.14.
//  Copyright (c) 2014 Piri-Piri. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var audioPlayer: AVAudioPlayer!
    var mainLayer: SKNode!
    var menu: Menu!
    var cannon: SKSpriteNode!
    var ammoDisplay: SKSpriteNode!
    var pauseButton: SKSpriteNode!
    var resumeButton: SKSpriteNode!
    var scoreLabel: SKLabelNode!
    var multiplierLabel: SKLabelNode!
    
    var bounceSound: SKAction!
    var deepExplosionSound: SKAction!
    var explosionSound: SKAction!
    var laserSound: SKAction!
    var zapSound: SKAction!
    var shieldUpSound: SKAction!
    
    let kShootSpeed: CGFloat = 1000.0
    let kHaloLowAngle: CGFloat  = 200.0 * CGFloat(M_PI) / 180.0;
    let kHaloHighAngle: CGFloat  = 340.0 * CGFloat(M_PI) / 180.0;
    let KHaloSpeed: CGFloat = 100.0
    
    let kHaloCategory:UInt32 = 0x1 << 0
    let kBallCategory:UInt32 = 0x1 << 1
    let kEdgeCategory:UInt32 = 0x1 << 2
    let kShieldCategory:UInt32 = 0x1 << 3
    let kLifebarCategory:UInt32 = 0x1 << 4
    let kShieldUpCategory:UInt32 = 0x1 << 5
    let kCannonUpCategory:UInt32 = 0x1 << 6
    
    let kTopScoreKey = "topScore"
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    let kMultiplierKey = "Multiplier"
    let kHaloBombKey = "HaloBomb"
    
    var shieldPool: NSMutableArray!
    
    var ammo: Int = 0 {
        didSet {
            if ammo >= 0 && ammo <= 5 {
                ammoDisplay.texture = SKTexture(imageNamed: "Ammo\(ammo)")
            }
            else {
                ammo = oldValue
            }
        }
    }
    
    var score: Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }

    }
    
    var multiplier: Int = 0 {
        didSet {
            multiplierLabel.text = "Points: x\(multiplier)"
        }
    }
    
    var isGamePaused: Bool = false {
        willSet{
            print(newValue)
        }
        didSet{
            if !isGameOver {
                pauseButton.hidden = isGamePaused
                resumeButton.hidden = !isGamePaused
                
                // pause/resume the whole scene
                self.paused = isGamePaused
            }
        }
    }
    
    var haloShootedCount = 0
    
    var isMultiShootMode = false
    var isHaloBombPresent = false
    var isGameOver = true
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
        /* Notice: the top has some additional space (100) to avoid a collision on spawn near to the top */
        let leftEdge = SKNode()
        leftEdge.physicsBody = SKPhysicsBody(edgeFromPoint: CGPointZero, toPoint: CGPointMake(0.0, view.frame.size.height + 100))
        leftEdge.physicsBody?.categoryBitMask = kEdgeCategory
        leftEdge.position = CGPointZero
        self.addChild(leftEdge)
        let rightEdge = SKNode()
        rightEdge.physicsBody = SKPhysicsBody(edgeFromPoint: CGPointZero, toPoint: CGPointMake(0.0, view.frame.size.height + 100))
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
        let spawnHalos = SKAction.sequence([SKAction.waitForDuration(2, withRange: 1), SKAction.runBlock({ self.spawnHalo() })])
        self.runAction(SKAction.repeatActionForever(spawnHalos), withKey: "spawnHalo")
        
        // Add a spawn ShieldPowerUp action
        let shieldUp = SKAction.sequence([SKAction.waitForDuration(15, withRange: 4), SKAction.runBlock({ self.spawnShieldPowerUp() })])
        self.runAction(SKAction.repeatActionForever(shieldUp))
        
        // Add Ammo Status
        ammoDisplay = SKSpriteNode(imageNamed: "Ammo5")
        ammoDisplay.anchorPoint = CGPointMake(0.5, 0.0)
        ammoDisplay.position = cannon.position
        self.addChild(ammoDisplay)
        
        let incrementAmmo = SKAction.sequence([SKAction.waitForDuration(1), SKAction.runBlock({ self.ammo += 1 })])
        self.runAction(SKAction.repeatActionForever(incrementAmmo), withKey: "incrementAmmo")
        
        // Setup Shield Pool
        shieldPool = NSMutableArray()
        for var i = 0; i < 6; i++ {
            let shield = SKSpriteNode(imageNamed: "Block")
            shield.name = "shield"
            shield.position = CGPointMake(35.0 + (50.0 * CGFloat(i)), 90)
            shield.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(42, 9))
            shield.physicsBody?.categoryBitMask = kShieldCategory
            shield.physicsBody?.collisionBitMask = 0
            shieldPool.addObject(shield)
        }
        
        // Setup Score Label
        scoreLabel = SKLabelNode(fontNamed: "DIN Alternate")
        scoreLabel.position = CGPointMake(15, 10)
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        scoreLabel.fontSize = 15.0
        self.addChild(scoreLabel)
        
        // Setup Point Label
        multiplierLabel = SKLabelNode(fontNamed: "DIN Alternate")
        multiplierLabel.position = CGPointMake(15, 30)
        multiplierLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        multiplierLabel.fontSize = 15.0
        self.addChild(multiplierLabel)
        
        // Setup pause button
        pauseButton = SKSpriteNode(imageNamed: "PauseButton")
        pauseButton.position = CGPointMake(view.frame.size.width - 30, 20)
        self.addChild(pauseButton)
        
        // Setup resume button
        resumeButton = SKSpriteNode(imageNamed: "ResumeButton")
        resumeButton.position = CGPointMake(view.frame.size.width * 0.5, self.frame.size.height * 0.5)
        self.addChild(resumeButton)
        
        // Setup Sounds
        bounceSound = SKAction.playSoundFileNamed("Bounce.caf", waitForCompletion: false)
        deepExplosionSound = SKAction.playSoundFileNamed("DeepExplosion.caf", waitForCompletion: false)
        explosionSound = SKAction.playSoundFileNamed("Explosion.caf", waitForCompletion: false)
        laserSound = SKAction.playSoundFileNamed("Laser.caf", waitForCompletion: false)
        zapSound = SKAction.playSoundFileNamed("Zap.caf", waitForCompletion: false)
        shieldUpSound = SKAction.playSoundFileNamed("ShieldUp.caf", waitForCompletion: false)
        
        // Setup Menu
        menu = Menu()
        menu.position = CGPointMake(view.frame.size.width * 0.5, view.frame.height - 220)
        self.addChild(menu)
        
        // Set initial values
        ammo = 5
        score = 0
        haloShootedCount = 0
        multiplier = 1
        isGameOver = true
        isMultiShootMode = false
        scoreLabel.hidden = true
        multiplierLabel.hidden = true
        pauseButton.hidden = true
        resumeButton.hidden = true
        
        menu.score = 0
        // Load UserDefaults
        menu.topScore = userDefaults.integerForKey(kTopScoreKey)
        
        // Load Music
        let url = NSBundle.mainBundle().URLForResource("ObservingTheStar", withExtension: "caf")
        do {
            try audioPlayer = AVAudioPlayer(contentsOfURL: url!)
            audioPlayer.numberOfLoops = -1
            audioPlayer.volume = 0.8
            audioPlayer.play()
            menu.isMusicOn = true
        } catch {
            let error = error as NSError
            print("Failed to load audioplayer. Error: \((error as NSError).localizedDescription)")
        }
    }
    
    func newGame() {
        mainLayer.removeAllChildren()
        
        // Add Shield
        while shieldPool.count > 0 {
            mainLayer.addChild(shieldPool.objectAtIndex(0) as! SKSpriteNode)
            shieldPool.removeObjectAtIndex(0)
        }
        
        // Add Lifebar
        let lifebar = SKSpriteNode(imageNamed: "BlueBar")
        lifebar.position = CGPointMake(self.view!.frame.size.width * 0.5, 70)
        lifebar.physicsBody = SKPhysicsBody(edgeFromPoint: CGPointMake(-lifebar.size.width * 0.5, 0), toPoint: CGPointMake(lifebar.size.width * 0.5, 0))
        lifebar.physicsBody?.categoryBitMask = kLifebarCategory
        mainLayer.addChild(lifebar)
        
        // Set initial valuse
        self.actionForKey("spawnHalo")?.speed = 1.0
        ammo = 5
        score = 0
        haloShootedCount = 0
        multiplier = 1
        scoreLabel.hidden = false
        multiplierLabel.hidden = false
        pauseButton.hidden = false
        isHaloBombPresent = false
        isMultiShootMode = false
        isGameOver = false
        menu.hide()
    }
    
    func gameOver() {
        mainLayer.enumerateChildNodesWithName("halo", usingBlock: { (node, stop) -> Void in
            self.addExplosion("HaloExplosion", position: node.position)
            node.removeFromParent()
        })
        mainLayer.enumerateChildNodesWithName("ball", usingBlock: { (node, stop) -> Void in
            node.removeFromParent()
        })
        mainLayer.enumerateChildNodesWithName("shield", usingBlock: { (node, stop) -> Void in
            /* put shield back to pool before removing the node */
            self.shieldPool.addObject(node)
            node.removeFromParent()
        })
        mainLayer.enumerateChildNodesWithName("shieldUp", usingBlock: { (node, stop) -> Void in
            node.removeFromParent()
        })
        mainLayer.enumerateChildNodesWithName("cannonUp", usingBlock: { (node, stop) -> Void in
            node.removeFromParent()
        })
        
        
        menu.score = score
        if score > menu.topScore {
            menu.topScore = score
            userDefaults.setInteger(score, forKey: kTopScoreKey)
            userDefaults.synchronize()
        }
        scoreLabel.hidden = true
        multiplierLabel.hidden = true
        pauseButton.hidden = true
        isGameOver = true
        
        self.runAction(SKAction.sequence([SKAction.waitForDuration(1.0), SKAction.runBlock( { self.menu.show() } )]))
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent: UIEvent?) {
        /* Called when a touch begins */
        for touch: AnyObject in touches {
            //let location = touch.locationInNode(self)
            if !isGameOver && !isGamePaused {
                if !pauseButton.containsPoint(touch.locationInNode(pauseButton.parent!)) {
                    didShoot = true
                }
            }
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    for touch: AnyObject in touches {
            //let location = touch.locationInNode(self)
            if isGameOver && menu.isTouchable {
                let touchedNode = menu.nodeAtPoint(touch.locationInNode(menu))
                if touchedNode.name == "Play" {
                    newGame()
                } else if touchedNode.name == "Music" {
                    menu.isMusicOn = !menu.isMusicOn
                    if menu.isMusicOn {
                        audioPlayer.play()
                    }
                    else {
                        audioPlayer.stop()
                    }
                }
            }
            else if !isGameOver {
                if isGamePaused {
                    if resumeButton.containsPoint(touch.locationInNode(resumeButton.parent!)) {
                        isGamePaused = false
                    }
                }
                else {
                    if pauseButton.containsPoint(touch.locationInNode(pauseButton.parent!)) {
                        isGamePaused = true
                    }
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
            if node.respondsToSelector(Selector("updateTrail")) {
                (node as! Ball).updateTrail()
            }
            if !CGRectContainsPoint(self.frame, node.position) {
                node.removeFromParent()
                self.multiplier = 1
            }
        })
        
        mainLayer.enumerateChildNodesWithName("halo", usingBlock: { (node, stop) -> Void in
            if node.position.y + node.frame.size.height < 0 {
                if node.userData?.valueForKey(self.kHaloBombKey)?.boolValue == true {
                    self.isHaloBombPresent = false
                }
                node.removeFromParent()
            }
        })
        
        mainLayer.enumerateChildNodesWithName("shieldUp", usingBlock: { (node, stop) -> Void in
            if node.position.x + node.frame.size.width < 0 {
                node.removeFromParent()
            }
        })
        mainLayer.enumerateChildNodesWithName("cannonUp", usingBlock: { (node, stop) -> Void in
            if node.position.x - node.frame.size.width > self.frame.size.width {
                node.removeFromParent()
                self.haloShootedCount = 0
            }
        })
    }
 
    func shoot() {
        if ammo > 0 {
            ammo--
            
            // Create a ball node
            if isMultiShootMode {
                let multiShoot = SKAction.sequence([SKAction.waitForDuration(0.1), SKAction.runBlock({ self.createShootBall() })])
                self.runAction(SKAction.repeatAction(multiShoot, count: 5))
            }
            else {
                createShootBall()
            }
            
            /* reset multishoot mode on last shoot */
            if ammo == 0 && isMultiShootMode {
                isMultiShootMode = false
                cannon.texture = SKTexture(imageNamed: "Cannon")
                self.actionForKey("incrementAmmo")?.speed = 1
                ammo = 5
            }
        }
        
    }
    
    func createShootBall() {
        // Create a ball node
        let ball = Ball(imageNamed: "Ball")
        let rotationVector = radiansToVector(cannon.zRotation)
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
        ball.physicsBody?.contactTestBitMask = kEdgeCategory | kShieldUpCategory | kCannonUpCategory
        self.runAction(laserSound)
        
        // Create ball trail effect
        let ballTrailPath = NSBundle.mainBundle().pathForResource("BallTrail", ofType: "sks")
        let ballTrail = NSKeyedUnarchiver.unarchiveObjectWithFile(ballTrailPath!) as! SKEmitterNode
        ballTrail.targetNode = mainLayer
        mainLayer.addChild(ballTrail)
        
        /* handle trail inside the ball class*/
        ball.trail = ballTrail
    }
    
    func spawnHalo() {
        // Increase spawn speed
        let spawnHaloAction = self.actionForKey("spawnHalo")
        if spawnHaloAction?.speed < 1.5 {
            spawnHaloAction?.speed += 0.01
        }
        
        // Create halo node
        let halo = SKSpriteNode(imageNamed: "Halo")
        halo.name = "halo"
        halo.position = CGPointMake(randomInRange(halo.size.width * 0.5, high: self.frame.width - (halo.size.width * 0.5)), self.frame.height + (halo.size.height * 0.5))
        halo.physicsBody = SKPhysicsBody(circleOfRadius: 16.0)
        
        let direction = radiansToVector(randomInRange(kHaloLowAngle, high: kHaloHighAngle))
        halo.physicsBody?.velocity = CGVectorMake(direction.dx * KHaloSpeed, direction.dy * KHaloSpeed)
        halo.physicsBody?.restitution = 1.0
        halo.physicsBody?.linearDamping = 0.0
        halo.physicsBody?.friction = 0.0
        
        halo.physicsBody?.categoryBitMask = kHaloCategory
        halo.physicsBody?.collisionBitMask = kEdgeCategory | kHaloCategory
        halo.physicsBody?.contactTestBitMask = kBallCategory | kShieldCategory | kLifebarCategory | kEdgeCategory
        
        
        /* count present halos */
        var haloCount = 0
        for node in mainLayer.children {
            if (node as SKNode).name == "halo" {
                haloCount++
            }
        }
        
        // Spawn a Halo Bomb, if four halo are present and no one is already present
        if haloCount == 4 && !isHaloBombPresent {
            halo.texture = SKTexture(imageNamed: "HaloBomb")
            halo.userData = NSMutableDictionary()
            halo.userData?.setValue(true, forKey: kHaloBombKey)
            isHaloBombPresent = true
        }
        // Spawn a point multiplier randomly
        else if !isGameOver && arc4random_uniform(UInt32(6)) == 0 {
            halo.texture = SKTexture(imageNamed: "HaloX")
            halo.userData = NSMutableDictionary()
            halo.userData?.setValue(true, forKey: kMultiplierKey)
        }
        
        mainLayer.addChild(halo)
    }
    
    func spawnShieldPowerUp() {
        if shieldPool.count > 0 {

        let shieldUp = SKSpriteNode(imageNamed: "Block")
        shieldUp.name = "shieldUp"
        shieldUp.position = CGPointMake(self.frame.size.width + shieldUp.size.width, randomInRange(150, high: self.frame.size.height - 100))
        shieldUp.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(42, 9))
        shieldUp.physicsBody?.categoryBitMask = kShieldUpCategory
        shieldUp.physicsBody?.collisionBitMask = 0
        
        shieldUp.physicsBody?.velocity = CGVectorMake(-100, randomInRange(-40, high: 40))
        shieldUp.physicsBody?.angularVelocity = CGFloat(M_PI)
        shieldUp.physicsBody?.linearDamping = 0  // no speed reduce due air
        shieldUp.physicsBody?.angularDamping = 0 // no speed reduce due air
        
        mainLayer.addChild(shieldUp)
        }
    }
    
    func spawnCannonPowerUp() {
        let cannonUp = SKSpriteNode(imageNamed: "MultiShotPowerUp")
        cannonUp.name = "cannonUp"
        cannonUp.position = CGPointMake(0 - cannonUp.size.width, randomInRange(150, high: self.frame.size.height - 100))
        cannonUp.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(42, 9))
        cannonUp.physicsBody?.categoryBitMask = kCannonUpCategory
        cannonUp.physicsBody?.collisionBitMask = 0
        
        cannonUp.physicsBody?.velocity = CGVectorMake(+100, randomInRange(-40, high: 40))
        cannonUp.physicsBody?.angularVelocity = CGFloat(M_PI)
        cannonUp.physicsBody?.linearDamping = 0  // no speed reduce due air
        cannonUp.physicsBody?.angularDamping = 0 // no speed reduce due air
        
        mainLayer.addChild(cannonUp)
    }
    
    func addExplosion(name: String, position: CGPoint) {
        let explosionPath = NSBundle.mainBundle().pathForResource(name, ofType: "sks")
        let explosion = NSKeyedUnarchiver.unarchiveObjectWithFile(explosionPath!) as! SKEmitterNode
        
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
                self.addExplosion("BounceExplosion", position: firstBody.node!.position)
                self.runAction(bounceSound)
                
                if firstBody.node!.isKindOfClass(Ball) {
                    (firstBody.node! as! Ball).bounces++
                    if (firstBody.node! as! Ball).bounces > 3 {
                        firstBody.node!.removeFromParent()
                        multiplier = 1
                    }
                }
            }
        }
        
        if firstBody.categoryBitMask == kHaloCategory && secondBody.categoryBitMask == kBallCategory {
            // Collision halo and ball
            haloShootedCount++
            score += multiplier
            
            /* avoid multiple explosion at one time */
            if firstBody.node != nil {
                self.addExplosion("HaloExplosion", position: firstBody.node!.position)
                self.runAction(explosionSound)
            }
            
            /* shoot a halo muliplier will add a points multiplier */
            if firstBody.node?.userData?.valueForKey(kMultiplierKey)?.boolValue == true {
               multiplier++
            }
            /* shoot a halo bomb will cause every shown halo to explode */
            else if firstBody.node?.userData?.valueForKey(kHaloBombKey)?.boolValue == true {
                /* avoid explosion of halo bomb that is already exploded */
                firstBody.node?.name = nil
                
                // now every present halo explode
                mainLayer.enumerateChildNodesWithName("halo", usingBlock: { (node, stop) -> Void in
                    /* Score an bonus for halo bomb?! */
                    //score += multiplier
                    
                    self.addExplosion("HaloExplosion", position: node.position)
                    node.removeFromParent()
                })
                isHaloBombPresent = false
            }
            
            /* avoid multiple shield destroy at one time */
            firstBody.node?.physicsBody?.categoryBitMask = 0
            
            firstBody.node?.removeFromParent()
            secondBody.node?.removeFromParent()
            
            // spawn cannon powerup every tenth halo shooted
            if haloShootedCount > 9 {
                haloShootedCount = 0
                spawnCannonPowerUp()
            }
        }
        
        if firstBody.categoryBitMask == kHaloCategory && secondBody.categoryBitMask == kShieldCategory {
            // Collision halo and shield
            /* avoid multiple explosion at one time */
            if firstBody.node != nil {
                self.addExplosion("HaloExplosion", position: firstBody.node!.position)
                self.runAction(explosionSound)
            }
            
            /* If a missed halo bomb hitting the shield will cause every shield to explode */
            if firstBody.node?.userData?.valueForKey(kHaloBombKey)?.boolValue == true {
                
                // now every present shield explode
                mainLayer.enumerateChildNodesWithName("shield", usingBlock: { (node, stop) -> Void in
                    /* put all shields back to pool before removing the node */
                    self.shieldPool.addObject(node)
                    node.removeFromParent()
                })
                isHaloBombPresent = false
            }
            /* put shield back to pool before removing the node */
            else if secondBody.node != nil {
                shieldPool.addObject(secondBody.node!)
            }
            
            /* avoid multiple shield destroy at one time */
            firstBody.node?.physicsBody?.categoryBitMask = 0
            firstBody.node?.removeFromParent()
            secondBody.node?.removeFromParent()
        }
        
        if firstBody.categoryBitMask == kHaloCategory && secondBody.categoryBitMask == kLifebarCategory {
            // Collision halo and lifebar
            /* avoid multiple explosion at one time */
            if firstBody.node != nil {
                self.addExplosion("LifebarExplosion", position: secondBody.node!.position)
                self.runAction(deepExplosionSound)
            }
            
            secondBody.node?.removeFromParent()
            gameOver()
        }
        
        if firstBody.categoryBitMask == kBallCategory && secondBody.categoryBitMask == kShieldUpCategory {
            // Collision ball and ShieldPowerUp
            if shieldPool.count > 0 {
                let randomIndex = Int(arc4random_uniform(UInt32(shieldPool.count)))
                mainLayer.addChild(shieldPool.objectAtIndex(randomIndex) as! SKSpriteNode)
                shieldPool.removeObjectAtIndex(randomIndex)
                self.runAction(shieldUpSound)
            }
            
            firstBody.node?.removeFromParent()
            secondBody.node?.removeFromParent()
        }
        
        if firstBody.categoryBitMask == kBallCategory && secondBody.categoryBitMask == kCannonUpCategory {
            // Collision ball and Cannon PowerUp
            
            isMultiShootMode = true
            cannon.texture = SKTexture(imageNamed: "GreenCannon")
            self.actionForKey("incrementAmmo")?.speed = 0
            ammo = 5
            
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
