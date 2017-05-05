//
//  GameScene.swift
//  phystut
//
//  Created by Collin Klenke on 3/20/17.
//  Copyright © 2017 Collin Klenke. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    var count : CGFloat?
    let ball: SKSpriteNode = SKSpriteNode(imageNamed: "ballscale.png")
    
    var clicked = false
    var firstClick = false
    var firstClick2 = false
    var targAdded = false
    var practice = false
    var onScreen = false
    var ballxPos : CGFloat?
    var ballyPos : CGFloat?
    
    let target = UIView()
    var circleTarget = SKShapeNode()
    var circleTarget2 = SKShapeNode()
    var circleTarget3 = SKShapeNode()
    var circleTarget4 = SKShapeNode()
    var distances = [Int]()
    var hit = [Int]()
    var innerDistances = [Int]()
    var numballs : Int?
    let playAgainButton = UIButton(frame: CGRect(x:0, y:150, width:100, height:30))
    let practiceButton = UIButton(frame: CGRect(x:0, y:250, width:UIScreen.main.bounds.width, height:30))
    let directionsLabel = UILabel(frame:CGRect(x:15, y:95, width:UIScreen.main.bounds.width - 30, height:50))
    let nextBallLabel = UILabel(frame: CGRect(x:0, y:140, width: UIScreen.main.bounds.width, height:50))
    var practiceHit = [Int]()
    var practiceDistances = [Int]()
    var practiceInnerDistances = [Int]()
    
    let finishPracticeButton = UIButton(frame: CGRect(x:0, y:250, width:UIScreen.main.bounds.width, height:30))
    
    override func didMove(to view: SKView) {
        
        self.backgroundColor = UIColor.white
        
        self.count = 0
        self.numballs = 0
        self.ballyPos = UIScreen.main.bounds.height             //initialize values
        
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: -2.0)
        
        self.directionsLabel.textColor = .black
        self.directionsLabel.textAlignment = .center
        self.directionsLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 30)
        self.directionsLabel.text = "Tap once to begin.\n Tap anywhere to stop the ball in the target"
        self.directionsLabel.numberOfLines = 0
        self.directionsLabel.lineBreakMode = .byWordWrapping    //directions label lets user know how
        self.directionsLabel.sizeToFit()                        // to play the game
        self.view?.addSubview(directionsLabel)
        
        self.practiceButton.setTitle("To practice, press here", for: .normal)   //button launches practice mode
        self.practiceButton.setTitleColor(UIColor.black, for: .normal)
        self.practiceButton.addTarget(self, action: #selector(runPractice), for: .touchUpInside)
        self.practiceButton.center = CGPoint(x: (self.view?.center)!.x, y:250)
        self.practiceButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 25)
        self.view?.addSubview(self.practiceButton)

        
    }
    
    func createBall(){              //this function is what starts each "round" by making a ball at a random x location on the screen, and placing the target directly underneath that position
        
        self.nextBallLabel.removeFromSuperview()
        self.circleTarget.removeFromParent()
        self.circleTarget2.removeFromParent()
        self.circleTarget3.removeFromParent()
        self.circleTarget4.removeFromParent()
        
        let screen: CGRect = UIScreen.main.bounds
        
        let randx = CGFloat(Int(arc4random()) % Int(round(screen.width * 1.5)))
        let subx = CGFloat(Int(round(screen.width) * 0.75))
        self.ball.position = CGPoint(
            x: randx - subx,
            y: screen.height - ball.size.height + 500
        )
        
        self.ball.physicsBody = SKPhysicsBody(circleOfRadius: ball.size.width/2)
        
        
        let size = self.ball.size.width/2 + 100 - self.count!
        
        self.circleTarget = SKShapeNode(circleOfRadius: size)
        let xposition = self.ball.position.x
        let yposition = CGFloat(0 - Int(arc4random()%450))
        
        self.circleTarget.position = CGPoint(x: xposition, y: yposition)
        self.circleTarget.strokeColor = SKColor.red
        self.circleTarget.fillColor = SKColor.red
        self.circleTarget.glowWidth = 1.0
        
        self.circleTarget2 = SKShapeNode(circleOfRadius: size - size/4)
        self.circleTarget2.position = CGPoint(x: xposition, y: yposition)
        self.circleTarget2.fillColor = SKColor.white
        self.circleTarget2.glowWidth = 1.0
        
        self.circleTarget3 = SKShapeNode(circleOfRadius: size - size/2)
        self.circleTarget3.position = CGPoint(x: xposition, y: yposition)
        self.circleTarget3.fillColor = SKColor.red
        self.circleTarget3.glowWidth = 1.0
        
        self.circleTarget4 = SKShapeNode(circleOfRadius: size/4)
        self.circleTarget4.position = CGPoint(x: xposition, y: yposition)
        self.circleTarget4.fillColor = SKColor.white
        self.circleTarget4.glowWidth = 1.0
        
        
        self.targAdded = false
        self.addChild(self.circleTarget)
        self.addChild(self.circleTarget2)
        self.addChild(self.circleTarget3)
        self.addChild(self.circleTarget4)
        
        //Make the ball go faster each time by applying an increasing impulse
        //ball.physicsBody?.applyImpulse(CGVector(dx: 0, dy:0-self.count!*1.5)) --> Uncomment this if you want it to go faster each time
        
        if(!self.practice){
            self.count = self.count! + 3 //increasing count will make the target smaller
        }
        
    }
    
    func stopBall(){
        self.ball.physicsBody?.affectedByGravity = false
        self.ball.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        self.ballxPos = self.ball.position.x
        self.ballyPos = self.ball.position.y
        
        let Y = round(self.ball.position.y - self.circleTarget.position.y)
        if(abs(Y) > self.ball.size.width/2 + 100 - self.count!){
            if(!self.practice){
                self.hit.append(0)
                self.distances.append(abs(Int(Y - (self.ball.size.width/2 + 100 - self.count!))))
                self.innerDistances.append(0)
            } else {
                self.practiceHit.append(0)
                self.practiceDistances.append(abs(Int(Y - (self.ball.size.width/2 + 100 - self.count!))))
                self.practiceInnerDistances.append(0)
            }
        } else {
            if(!self.practice){
                self.hit.append(1)
                self.distances.append(0)
                self.innerDistances.append(Int(Y))
            } else {
                self.practiceHit.append(1)
                self.practiceDistances.append(0)
                self.practiceInnerDistances.append(Int(Y))
            }
            
        }
      
        
        self.scoreBoard()
        
        
        self.nextBallLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 30)
        self.nextBallLabel.textColor = .black
        self.nextBallLabel.textAlignment = .center
        self.nextBallLabel.text = "Tap again for the next ball"
        
        self.view?.addSubview(self.nextBallLabel)
        
        
    }
    
    func scoreBoard(){
        var numhits = 0
        var totaldist = 0
        var avgdist : Double?
        
        let ballsLeftLabel = UILabel(frame: CGRect(x:0, y:50, width: UIScreen.main.bounds.width, height:50))
        ballsLeftLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 30)
        ballsLeftLabel.textColor = .black
        ballsLeftLabel.textAlignment = .center
        
        let hitRateLabel = UILabel(frame: CGRect(x:0, y:80, width: UIScreen.main.bounds.width, height:50))
        hitRateLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 30)
        hitRateLabel.textColor = .black
        hitRateLabel.textAlignment = .center
        
        let avgdistLabel = UILabel(frame: CGRect(x:0, y:110, width: UIScreen.main.bounds.width, height:50))
        avgdistLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 30)
        avgdistLabel.textColor = .black
        avgdistLabel.textAlignment = .center
        
        self.playAgainButton.setTitle("Play Again", for: .normal)
        self.playAgainButton.setTitleColor(UIColor.black, for: .normal)
        self.playAgainButton.addTarget(self, action: #selector(playAgain), for: .touchUpInside)
        self.playAgainButton.center = CGPoint(x: (self.view?.center)!.x, y:170)
        
        for view in (self.view?.subviews)! {
            view.removeFromSuperview()
        }
    
        if(!practice){
            for val in self.hit {
                numhits += val
            }
            for val in self.distances {
                totaldist += val
            }
            avgdist = Double(totaldist)/Double(self.distances.count)
            
            ballsLeftLabel.text = "Balls left: \(10 - self.numballs!)"
            hitRateLabel.text = "Hits: \(numhits) Misses: \(self.hit.count - numhits)"
            if(self.numballs! == 0){
                avgdistLabel.text = "Average distance: 0"
            } else {
                avgdistLabel.text = "Average distance: \(Int(round(avgdist!)))"
            }
            if(self.numballs! > 9){
                self.view?.addSubview(self.playAgainButton)
            }
            self.view?.addSubview(ballsLeftLabel)
        } else {
            
            for val in self.practiceHit {
                numhits += val
            }
            for val in self.practiceDistances {
                totaldist += val
            }
            avgdist = Double(totaldist)/Double(self.practiceDistances.count)
            hitRateLabel.text = "Hits: \(numhits) Misses: \(self.practiceHit.count - numhits)"
            if(self.practiceHit.count == 0){
                avgdistLabel.text = "Average distance: 0"
            } else {
                avgdistLabel.text = "Average distance: \(Int(round(avgdist!)))"
            }
            self.view?.addSubview(self.finishPracticeButton)
            
        }
        
        self.view?.addSubview(hitRateLabel)
        self.view?.addSubview(avgdistLabel)
        

    }
    
    func playAgain(sender: UIButton!){  //clears all values to reset it
        self.count = 0
        self.numballs = 0
        self.hit.removeAll()
        self.distances.removeAll()
        self.innerDistances.removeAll()
        self.practiceHit.removeAll()
        self.practiceDistances.removeAll()
        self.practiceInnerDistances.removeAll()
        for view in (self.view?.subviews)! {
            view.removeFromSuperview()
        }
        self.ball.removeFromParent()
        self.circleTarget.removeFromParent()
        self.circleTarget2.removeFromParent()
        self.circleTarget3.removeFromParent()
        self.circleTarget4.removeFromParent()
        self.finishPracticeButton.removeFromSuperview()
        self.firstClick = false
        self.clicked = false
        self.practice = false
        self.view?.addSubview(self.directionsLabel)
        self.view?.addSubview(self.practiceButton)
    }
    
    func runPractice(sender: UIButton!){ //sets practice to true and adds a button to start playing
        self.practice = true
        self.directionsLabel.removeFromSuperview()
        
        for view in (self.view?.subviews)! {
            view.removeFromSuperview()
        }
        self.finishPracticeButton.setTitle("I'm ready to begin", for: .normal)
        self.finishPracticeButton.setTitleColor(UIColor.black, for: .normal)
        self.finishPracticeButton.addTarget(self, action: #selector(playAgain), for: .touchUpInside)
        self.finishPracticeButton.center = CGPoint(x: (self.view?.center)!.x, y:195)
        self.finishPracticeButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 25)
        
        self.scoreBoard()
    }
    
    
    func touchDown(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.green
            self.addChild(n)
        }
        
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.blue
            self.addChild(n)
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.red
            self.addChild(n)
        }
        
        if(!self.firstClick){
            self.directionsLabel.removeFromSuperview()
            self.practiceButton.removeFromSuperview()
            self.addChild(self.ball)
            self.firstClick = true
            self.scoreBoard()
            
        }
        if(!self.clicked){
            if(!(self.numballs! > 9)){
                self.createBall()
                if(!self.practice){
                    self.numballs! += 1
                }
                self.clicked = true
            }
        } else {
            if(self.onScreen){
                self.stopBall()
                self.clicked = false
                if(self.numballs! > 9){
                    self.scoreBoard()
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        if(self.ball.position.y < -(UIScreen.main.bounds.height + 50)){
            self.ball.position.y = UIScreen.main.bounds.height - self.ball.size.height
            self.ball.physicsBody?.velocity = CGVector(dx: 0.0, dy: 0.0)
        }
        if(self.ball.position.y > UIScreen.main.bounds.height){
            self.onScreen = false
        } else {
            self.onScreen = true
        }
    }
}
