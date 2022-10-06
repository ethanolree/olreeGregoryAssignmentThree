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
    var rink:SCNNode!
    
    var playerScore:Int = 0
    var computerScore:Int = 0
    
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
        
        addRink() // make scene
        addTapGestureToSceneView()  // make taps for selecting objects
        setupMotion() // use motion to control camera
        
        
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
                
                // rink has x in same direction, left or right in rink
                self.scene.physicsWorld.gravity.x =  Float(deviceMotion.gravity.x)*90.8
                
                // reverse the y device such that subtle changes
                // really change the up and down rink actions
                self.scene.physicsWorld.gravity.z =  Float(deviceMotion.gravity.y)*(-900.8)
                
                // hockey rink has "y" in the up down direction
                // so gravity is down when looking down (z device)
                // onto the rink
                self.scene.physicsWorld.gravity.y =  Float(deviceMotion.gravity.z)*(90.8)
                
            }
            
        }
    }
    

    // MARK: Scene Setup
    func addRink(){
        
        guard let sceneView = sceneView else {
            return
        }
        
        // Setup Original Scene
        scene = SCNScene()
        
        // we will handle all collisions
        scene.physicsWorld.contactDelegate = self

        // load living room model we created in sketchup
        room = SCNScene(named: "model.scn")!
        
        room.physicsWorld.gravity = SCNVector3(x: 0, y: 0, z: 0)
        
        rink = room.rootNode
        scene.rootNode.addChildNode(room.rootNode.childNode(withName: "SketchUp", recursively: true)!)
        
        // Setup camera position from existing scene
        if let cameraNodeTmp = room.rootNode.childNode(withName: "camera", recursively: true){
            cameraNode = cameraNodeTmp
            scene.rootNode.addChildNode(cameraNode)
        }
        
        if let lighting = room.rootNode.childNode(withName: "Lighting", recursively: true){
            scene.rootNode.addChildNode(lighting)
        }
        
        // make this the scene in the view
        sceneView.scene = scene
        
        //Debugging
        sceneView.showsStatistics = true
    

    }
    // MARK: Contact Delegation
    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
        
        func updateContact(puck:String, node:SCNNode){
            // remove puck from the scene
            if puck == "player"{
                self.playerScore += 1
            }else{
                self.computerScore += 1
            }
            node.removeFromParentNode()
            
            DispatchQueue.main.async {
                self.updateScore()
            }
        }
        
        if let nameA = contact.nodeA.name,
            let nameB = contact.nodeB.name,
            nameA == "Goal" { // this is the name of the goal
            // remove puck from the scene
            updateContact(puck: nameB, node: contact.nodeB)
        }
        
        if let nameB = contact.nodeB.name,
           let nameA = contact.nodeA.name,
            nameB == "Goal"{
            
            updateContact(puck: nameA, node: contact.nodeA)
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
        let puck = SCNNode(geometry: SCNCylinder(radius: 25, height: 15))
        
        let material = SCNMaterial()

        // randomly generate a player puck or CPU puck
        if self.random() > 0.5 {
            material.diffuse.contents = UIColor.green
            puck.name = "player"
        }else{
            material.diffuse.contents = UIColor.red
            puck.name = "cpu"
        }
        
        // place hockey puck in the scene, directly where camera is
        let physics = SCNPhysicsBody(type: .dynamic,
                                     shape:SCNPhysicsShape(geometry: puck.geometry!, options:nil))

        physics.isAffectedByGravity = true
        physics.friction = 1
        physics.restitution = 1
        // setup so that it can collide with the goal
        physics.categoryBitMask  = 0xFFFF
        physics.collisionBitMask = 0xFFFF
        physics.contactTestBitMask  = 0xFFFF
        
        puck.geometry?.firstMaterial = material
        puck.position = cameraNode.position
        puck.position.y -= 150
        puck.position.z -= 200
        puck.physicsBody = physics
        puck.castsShadow = true

        scene.rootNode.addChildNode(puck)
        
        self.updating = false
        
    }
    
    func updateScore(){
        if(updating){return}
        // change the current object we are asking the participant to find
        
        topLabel.layer.add(animation, forKey: animationKey)
        topLabel.text = "You: \(self.playerScore), CPU: \(self.computerScore)"
        
        if(playerScore>=5 || computerScore>=5){
            // if here, End the game
            topLabel.layer.add(animation, forKey: animationKey)
            if playerScore > computerScore{
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
