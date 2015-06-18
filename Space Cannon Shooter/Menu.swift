//
//  Menu.swift
//  Space Cannon Shooter
//
//  Created by David Pirih on 08.10.14.
//  Copyright (c) 2014 Piri-Piri. All rights reserved.
//

import UIKit
import SpriteKit

class Menu: SKNode {
    
    let title: SKSpriteNode!
    let scoreBoard: SKSpriteNode!
    let playButton: SKSpriteNode!
    let musicButton: SKSpriteNode!
        
    let scoreLabel: SKLabelNode!
    let topScoreLabel: SKLabelNode!
    
    var isTouchable: Bool = false
    
    var isMusicOn: Bool = true {
        didSet {
            if isMusicOn {
                musicButton.texture = SKTexture(imageNamed: "MusicOnButton")
            }
            else {
                musicButton.texture = SKTexture(imageNamed: "MusicOffButton")
            }
        }
    }
    
    var score: Int = 0 {
        didSet {
            scoreLabel.text = "\(score)"
        }
    }
    
    var topScore: Int = 0 {
        didSet {
            topScoreLabel.text = "\(topScore)"
        }
    }
    
    override init() {
        title = SKSpriteNode(imageNamed: "Title")
        title.position = CGPointMake(0, 140)
        
        scoreBoard = SKSpriteNode(imageNamed: "ScoreBoard")
        scoreBoard.position = CGPointMake(0, 70)
        
        playButton = SKSpriteNode(imageNamed: "PlayButton")
        playButton.name = "Play"
        playButton.position = CGPointMake(0, 0)
        
        musicButton = SKSpriteNode(imageNamed: "MusicOnButton")
        musicButton.name = "Music"
        musicButton.position = CGPointMake(90, 0)
        
        scoreLabel = SKLabelNode(fontNamed: "DIN Alternate")
        scoreLabel.fontSize = 30
        scoreLabel.position = CGPointMake(-52, -20)
        scoreBoard.addChild(scoreLabel)
        
        topScoreLabel = SKLabelNode(fontNamed: "DIN Alternate")
        topScoreLabel.fontSize = 30
        topScoreLabel.position = CGPointMake(48, -20)
        scoreBoard.addChild(topScoreLabel)
        
        isTouchable = true
        
        super.init()
        
        self.addChild(title)
        self.addChild(scoreBoard)
        self.addChild(playButton)
        self.addChild(musicButton)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show() {
        self.hidden = false
        isTouchable = false
        
        let fadeOutAction = SKAction.fadeInWithDuration(0.5)
        
        // Animate Title
        title.position = CGPointMake(0, 280)
        title.alpha = 0.0
        let animateTitle = SKAction.group([SKAction.moveToY(140, duration: 0.5), fadeOutAction])
        /* slow down the aminateion by getting near to the end */
        animateTitle.timingMode = SKActionTimingMode.EaseOut
        title.runAction(animateTitle)
        
        // Animate ScoreBoard
        scoreBoard.xScale = 4.0
        scoreBoard.yScale = 4.0
        scoreBoard.alpha = 0.0
        let animateScoreBoard = SKAction.group([SKAction.scaleTo(1.0, duration: 0.5), fadeOutAction])
        /* slow down the aminateion by getting near to the end */
        animateScoreBoard.timingMode = SKActionTimingMode.EaseOut
        scoreBoard.runAction(animateScoreBoard)
        
        // Animate PlayButton
        playButton.alpha = 0
        let animatePlayButton = SKAction.fadeInWithDuration(2.0)
        animatePlayButton.timingMode = SKActionTimingMode.EaseIn
        playButton.runAction(SKAction.sequence([animatePlayButton, SKAction.runBlock( { self.isTouchable = true } ) ]))
        
        // Animate MusicButton
        musicButton.alpha = 0
        musicButton.runAction(animatePlayButton)
    }
    
    func hide() {
        isTouchable = false
        
        // Animate whole menu
        let animateMenu = SKAction.scaleTo(0.0, duration: 0.5)
        animateMenu.timingMode = SKActionTimingMode.EaseIn
        self.runAction(SKAction.sequence([animateMenu,
            SKAction.runBlock(
            {
                self.hidden = true
                self.xScale = 1.0
                self.yScale = 1.0
            } ) ]))
    }
    
    func musicOn() {
    
    }
    
    func musicOff() {
    
    }
}
