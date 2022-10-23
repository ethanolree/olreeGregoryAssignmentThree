//
//  ExampleOriginViewController.swift
//  Marbles
//
//  Created by Eric Larson on 9/5/18.
//

import UIKit
import CoreMotion
import MorphingLabel

class ExampleOriginViewController: UIViewController {

    // MARK: =====Class Variables=====
    let activityManager = CMMotionActivityManager()
    let pedometer = CMPedometer()
    let cal = Calendar(identifier: .gregorian)
    let defaults = UserDefaults.standard
    
    
    // UI Outlets
    @IBOutlet weak var yesterdaySteps: LTMorphingLabel!
    @IBOutlet weak var todaySteps: LTMorphingLabel!
    @IBOutlet weak var stepsToGoal: LTMorphingLabel!
    @IBOutlet weak var currentActivity: LTMorphingLabel!
    @IBOutlet weak var updatedStepGoal: UITextField!
    @IBOutlet weak var playGameButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.getYesterdaySteps()
        self.startPedometerMonitoring()
        self.startActivityMonitoring()
        
        if (self.defaults.integer(forKey: "stepGoal") == 0){
            self.defaults.set(Int(0), forKey: "stepGoal")
        }
    }
    
    // MARK: =====Motion Methods=====
    func getYesterdaySteps(){
        if CMPedometer.isStepCountingAvailable(){
            pedometer.queryPedometerData(from: cal.startOfDay(for: (Calendar.current.date(byAdding: .day, value: -1, to: Date())!)) ,
                                         to: cal.startOfDay(for: Date())) {(pedData:CMPedometerData?, error:Error?)in
                if let data = pedData {
                    DispatchQueue.main.async {
                        self.yesterdaySteps.text = String(data.numberOfSteps.floatValue)
                        self.yesterdaySteps.textColor = .darkText
                    }
                    print("yesterday's steps")
                    
                    print(data.numberOfSteps.floatValue)
                    
                    
                    print(self.cal.startOfDay(for: (Calendar.current.date(byAdding: .day, value: -1, to: Date())!)))
                    print(self.cal.startOfDay(for: Date()))
                }
            }
        }
    }
    
    func startActivityMonitoring(){
        // is activity is available
        if CMMotionActivityManager.isActivityAvailable(){
            // update from this queue (should we use the MAIN queue here??.... )
            self.activityManager.startActivityUpdates(to: OperationQueue.main)
            {(activity:CMMotionActivity?)->Void in
                // unwrap the activity and display
                // using the real time pedometer influences how often we get activity updates...
                // so these updates can come through less often than we may want
                if let unwrappedActivity = activity {
                    // Print if we are walking or running
                    print("%@",unwrappedActivity.description)
                    if(unwrappedActivity.unknown){
                        self.currentActivity.text = "unknown"
                    }
                    if(unwrappedActivity.walking){
                        self.currentActivity.text = "Walking"
                    }
                    if(unwrappedActivity.running){
                        self.currentActivity.text = "Running"
                    }
                    if(unwrappedActivity.cycling){
                        self.currentActivity.text = "Cycling"
                    }
                    if(unwrappedActivity.stationary){
                        self.currentActivity.text = "Still"
                    }
                    if(unwrappedActivity.automotive){
                        self.currentActivity.text = "Driving"
                    }
                    self.currentActivity.textColor = .darkText
                }
            }
        }
        
    }
    
    func startPedometerMonitoring(){
        // check if pedometer is okay to use
        if CMPedometer.isStepCountingAvailable(){
            // start updating the pedometer from the current date and time
            pedometer.startUpdates(from: self.cal.startOfDay(for: Date()))
            {(pedData:CMPedometerData?, error:Error?)->Void in
                
                // if no errors, update the main UI
                if let data = pedData {
                    
                    // display the output directly on the phone
                    DispatchQueue.main.async {
                        
                        // this updates the slider with number of steps
                        self.todaySteps.text = String( data.numberOfSteps.floatValue)
                        self.todaySteps.textColor = .darkText
                        
                        
                        self.stepsToGoal.text = String( self.defaults.integer(forKey: "stepGoal") - Int(data.numberOfSteps.floatValue))
                        self.stepsToGoal.textColor = .darkText
                        
                        self.defaults.set(Int(data.numberOfSteps.floatValue), forKey: "steps")
                        
                        if (self.defaults.integer(forKey: "stepGoal") < Int(data.numberOfSteps.floatValue)){
                            self.playGameButton.isEnabled = true
                        } else{
                            self.playGameButton.isEnabled = false
                        }
                        
                        print(self.defaults.integer(forKey: "steps"))
                    }
                    
                }
            }
            
        }
    }
    
    @IBAction func tapBackground(_ sender: Any) {
        self.updatedStepGoal.resignFirstResponder()
    }

    @IBAction func updateStepGoal(_ sender: Any) {
        if let goal = self.updatedStepGoal.text,
           !goal.isEmpty {
            self.defaults.set(Int(goal), forKey: "stepGoal")
            self.stepsToGoal.text = String( self.defaults.integer(forKey: "stepGoal") - Int(self.defaults.integer(forKey: "steps")))
            self.stepsToGoal.textColor = .darkText
            
            if (self.defaults.integer(forKey: "stepGoal") < self.defaults.integer(forKey: "steps")){
                self.playGameButton.isEnabled = true
            } else{
                self.playGameButton.isEnabled = false
            }
            
        }
    }
}
