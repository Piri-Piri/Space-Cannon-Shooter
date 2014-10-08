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
    
    var scoreLabel: SKLabelNode!
    var topScoreLabel: SKLabelNode!
    
    var scoreValue: Int = 0
    var score: Int {
        set {
            scoreValue = newValue
            scoreLabel.text = "\(scoreValue)"
        }
        get {
            return scoreValue
        }
    }
    
    var topScoreValue: Int = 0
    var topScore: Int {
        set {
            topScoreValue = newValue
            topScoreLabel.text = "\(topScoreValue)"
        }
        get {
            return topScoreValue
        }
    }
    
    override init() {
        super.init()
        let title = SKSpriteNode(imageNamed: "Title")
        title.position = CGPointMake(0, 140)
        self.addChild(title)
        
        let scoreBoard = SKSpriteNode(imageNamed: "ScoreBoard")
        scoreBoard.position = CGPointMake(0, 70)
        self.addChild(scoreBoard)
        
        let playButton = SKSpriteNode(imageNamed: "PlayButton")
        playButton.name = "Play"
        playButton.position = CGPointMake(0, 0)
        self.addChild(playButton)
        
        scoreLabel = SKLabelNode(fontNamed: "DIN Alternate")
        scoreLabel.fontSize = 30
        scoreLabel.position = CGPointMake(-52, 50)
        self.addChild(scoreLabel)
        
        topScoreLabel = SKLabelNode(fontNamed: "DIN Alternate")
        topScoreLabel.fontSize = 30
        topScoreLabel.position = CGPointMake(48, 50)
        self.addChild(topScoreLabel)
        
        score = 0
        topScore = 0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
