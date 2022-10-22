//
//  GameViewController.swift
//  BouncyBall
//



import UIKit
import SceneKit
import CoreMotion


class GameViewController : UIViewController, SCNPhysicsContactDelegate {
    
    // MARK: Properties
    
    // SCN setup
    var scene : SCNScene!
	var cameraNode : SCNNode!
    var wallNode: SCNNode!
	var motionManager : CMMotionManager!
    var initialAttitude: (roll: Double, pitch:Double, yaw:Double)?
    var room:SCNScene!
    var crate:SCNNode!
    
    var playerScore:Int = 0
    var numberOfBalls:Int = 10
    
    // anmations for labels
    let animation = CATransition()
    let animationKey = convertFromCATransitionType(CATransitionType.push)
    
    // game state tracking variables
    var updating = false
    
    // outlets
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var sceneView: SCNView!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var middleLabel: UILabel!
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
		super.viewDidLoad()
        
        // for nice animations on the text
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        animation.type = convertToCATransitionType(animationKey)
        animation.duration = 0.5
        
		// Setup environment
        // save  orientaton of phone for z device to point down
        self.initialAttitude = (0, Double.pi/3, 0)
        
        addCrate() // make scene
        addTapGestureToSceneView()  // make taps for selecting objects
        setupMotion() // use motion to control camera
        
        topLabel.backgroundColor = UIColor.blue
	}
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let deadlineTime = DispatchTime.now() + 1
        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
            self.updateScore() // start the game and tell user what object to use!
        }
    }
    
    
    // MARK: Motion in World
    func setupMotion(){
        // use motion for camera movement
        motionManager = CMMotionManager()
        motionManager.deviceMotionUpdateInterval = 1/30.0
        
        motionManager.startDeviceMotionUpdates(to: OperationQueue.main)
        {
            (deviceMotion, error) -> Void in
            
            if let deviceMotion = deviceMotion{
                
                // update camera angle based upon the difference to original position
                let pitch = Float(self.initialAttitude!.pitch - deviceMotion.attitude.pitch)
                let yaw = Float(self.initialAttitude!.yaw - deviceMotion.attitude.yaw)
                
                self.cameraNode.eulerAngles.x = -pitch
                self.cameraNode.eulerAngles.y = -yaw
                
                // ball is affected by rotation to the left and right
                self.scene.physicsWorld.gravity.x =  Float(deviceMotion.gravity.x)*200
                
                // ball is affected by gravity "y" in the up down direction
                self.scene.physicsWorld.gravity.y =  Float(deviceMotion.gravity.z)*(90.8)
                
            }
            
        }
    }
    

    // MARK: Scene Setup
    func addCrate(){
        
        guard let sceneView = sceneView else {
            return
        }
        
        // Setup Original Scene
        scene = SCNScene()
        
        // we will handle all collisions
        scene.physicsWorld.contactDelegate = self

        // load crate model we created in sketchup
        room = SCNScene(named: "crate.scn")!
        
        room.physicsWorld.gravity = SCNVector3(x: 0, y: 0, z: 0)
        
        crate = room.rootNode
        
        // Setup base crate object for scene
        if let crate = room.rootNode.childNode(withName: "SketchUp", recursively: false){
            scene.rootNode.addChildNode(crate)
            print(crate.categoryBitMask)
        }
        
        // Setup camera position from existing scene
        if let cameraNodeTmp = room.rootNode.childNode(withName: "camera", recursively: true){
            cameraNode = cameraNodeTmp
            scene.rootNode.addChildNode(cameraNode)
        }
        
        // Setup lighting
        if let lighting = room.rootNode.childNode(withName: "Lighting", recursively: true){
            scene.rootNode.addChildNode(lighting)
            print(lighting.categoryBitMask)
        }
        
        if let box = room.rootNode.childNode(withName: "box", recursively: true){
            scene.rootNode.addChildNode(box)
        }
        
        // make this the scene in the view
        sceneView.scene = scene
        
        //Debugging
        sceneView.showsStatistics = true
    

    }
    
    // MARK: Contact Delegation
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        
        func updateContact(ball:String, node:SCNNode){
            // remove ball from the scene
            if ball == "ball"{
                self.playerScore += 1
            }
            
            node.removeFromParentNode()
            
            DispatchQueue.main.async {
                self.updateScore()
            }
        }
        
        if let nameA = contact.nodeA.name,
            let nameB = contact.nodeB.name,
            nameA == "box" { // this is the name of the collision box
            // remove ball from the scene
            updateContact(ball: nameB, node: contact.nodeB)
        }
        
        if let nameB = contact.nodeB.name,
           let nameA = contact.nodeA.name,
            nameB == "box"{
            updateContact(ball: nameA, node: contact.nodeA)
        }
        
    }
    
    // MARK: User Interface Interactions
    @IBAction func doneButtonPressed(_ sender: UIButton) {
        // this button was enabled by end of game, time to go away
        self.dismiss(animated: true, completion: nil)
    }
    
    func addTapGestureToSceneView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleObjectTap(_:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func handleObjectTap(_ sender:UITapGestureRecognizer){
        if(updating){return}
        updating = true // prevent from tapping wildly
        
        // add sphere to the world to make things harder
        let ball = SCNNode(geometry: SCNSphere(radius: 15))
        numberOfBalls -= 1
        
        let material = SCNMaterial()

        // create a ball with random colors
        material.diffuse.contents = UIColor.init(red: CGFloat(self.random()), green: CGFloat(self.random()), blue: CGFloat(self.random()), alpha: 1)
        ball.name = "ball"
        
        // place the ball in the scene at the position of the camera
        let physics = SCNPhysicsBody(type: .dynamic,
                                     shape:SCNPhysicsShape(geometry: ball.geometry!, options:nil))

        physics.isAffectedByGravity = true
        physics.friction = 1
        physics.restitution = 1
        physics.velocity = SCNVector3(0.0, 0.0, -200)
        // setup so that it can collide with the goal
        physics.categoryBitMask  = 0xFFFFFFFF
        physics.collisionBitMask = 0xFFFFFFFF
        physics.contactTestBitMask  = 0xFFFFFFFF
        
        ball.geometry?.firstMaterial = material
        // offset the bals x position for slight variation
        ball.position = SCNVector3(cameraNode.position.x + 50*(0.5 - self.random()), cameraNode.position.y, cameraNode.position.z)
        ball.physicsBody = physics
        ball.castsShadow = true

        scene.rootNode.addChildNode(ball)
        
        self.updating = false
        self.updateScore()
    }
    
    func updateScore(){
        if(updating){return}
        // change the current object we are asking the participant to find
        
        topLabel.layer.add(animation, forKey: animationKey)
        topLabel.text = "Balls Remaining: \(self.numberOfBalls) | Score: \(self.playerScore)"
        
        if(playerScore>=5 || numberOfBalls < 0){
            // if here, End the game
            topLabel.layer.add(animation, forKey: animationKey)
            if playerScore >= 5{
                topLabel.text = "You Win!"
            }else{
                topLabel.text = "You Lose!"
            }

            // add in the done button
            doneButton.layer.add(animation, forKey: animationKey)
            doneButton.isHidden = false
        }else{
            updating = false
        }

        
    }
	
    // MARK: Utility Functions
    func displayBriefly(_ text:String){
        // display quickly on screen and then move out
        middleLabel.layer.add(animation,forKey:animationKey)
        middleLabel.text = text
        let deadlineTime = DispatchTime.now() + 0.5
        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
            self.middleLabel.layer.add(self.animation,forKey:self.animationKey)
            self.middleLabel.text = ""
        }
    }
    
    // MARK: Utility Functions (thanks ray wenderlich!)
    func random() -> Float {
        return Float(arc4random()) / Float(UInt32.max)
    }
        
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromCATransitionType(_ input: CATransitionType) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToCATransitionType(_ input: String) -> CATransitionType {
	return CATransitionType(rawValue: input)
}
