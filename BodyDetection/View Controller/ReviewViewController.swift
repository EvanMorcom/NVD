
//
//  ReviewViewController.swift
//  BodyDetection
//
//  Created by Nikhil Yerasi on 2/28/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import UIKit

class ReviewViewController: UIViewController {
    @IBOutlet var textView: UITextView!
    
    @IBOutlet weak var textV: UITextView!
    
    
    var transformPrintout: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear
        
        
        // Hacky unit testing setup
        func test_getAngleFromXYZ_xUnitVector(){
            let endPointPosX = Position3D(x: 1.0, y: 0.0, z: 0.0)
            let endPointNegX = Position3D(x: 1.0, y: 0.0, z: 0.0)
            
            let origin = Position3D(x: 0.0, y: 0.0,z: 0.0 )
            
            let anglePos = getAngleFromXYZ(endPoint: endPointPosX, origin: origin, relativePlane: Plane.XZ )
            let angleNeg = getAngleFromXYZ(endPoint: endPointNegX, origin: origin, relativePlane: Plane.XZ )
            
            let test1 = "Test1: \(anglePos == 0.0)\n"
            let test2 = "Test2: \(angleNeg == 0.0)\n"
            
            
            
            let output  = test1 + test2
            
            textV.text = output
            
            
        }
    }
    
}
