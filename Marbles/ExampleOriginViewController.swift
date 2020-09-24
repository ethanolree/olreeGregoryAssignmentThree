//
//  ExampleOriginViewController.swift
//  Marbles
//
//  Created by Eric Larson on 9/5/18.
//

import UIKit

class ExampleOriginViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // here is where we set an image name to the new view controller
        // this image should be in the image.assets directory
        
        let vc = segue.destination as! GameViewController
        // set the view controller to display an images
        vc.imageToShow = "Wood_Floor_Light"
        
        // you could also set the property 'objectsToFind' here
        // if you wanted to change what views were accesible
    }
    

}
