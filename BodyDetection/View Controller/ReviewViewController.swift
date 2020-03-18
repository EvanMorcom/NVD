
//
//  ReviewViewController.swift
//  BodyDetection
//
//  Created by Nikhil Yerasi on 2/28/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import UIKit


func approximatelyEqual(val1: Float, val2: Float, tolerence: Float) -> Bool {
        
    let diff = abs(val1-val2)
    
    return tolerence > diff
}


// Hacky unit testing setup
func test_getAngleFromXYZ_xUnitVector() -> String{
    
    let prefix = "angle_from_xyz_x_unit_vector\n"
    
    let endPointPosX = Position3D(x: 1.0, y: 0.0, z: 0.0)
    let endPointNegX = Position3D(x: -1.0, y: 0.0, z: 0.0)
    
    let origin = Position3D(x: 0.0, y: 0.0,z: 0.0 )
    
    let anglePos = getAngleFromXYZ(endPoint: endPointPosX, origin: origin, relativePlane: Plane.XZ )
    let angleNeg = getAngleFromXYZ(endPoint: endPointNegX, origin: origin, relativePlane: Plane.XZ )
    
    let test1 = "PosX: \(anglePos == 0.0)\n"
    let test2 = "NegX: \(angleNeg == 0.0)\n"
    
    return prefix + test1 + test2 + "\n";
}
func test_getAngleFromXYZ_yUnitVector() -> String{
    
    let prefix = "angle_from_xyz_y_unit_vector\n"
    
    let endPointPosY = Position3D(x: 0.0, y: 1.0, z: 0.0)
    let endPointNegY = Position3D(x: 0.0, y: -1.0, z: 0.0)
    
    let origin = Position3D(x: 0.0, y: 0.0,z: 0.0 )
    
    let anglePos = getAngleFromXYZ(endPoint: endPointPosY, origin: origin, relativePlane: Plane.XZ )
    let angleNeg = getAngleFromXYZ(endPoint: endPointNegY, origin: origin, relativePlane: Plane.XZ )
    
    let test1 = "PosY: \(approximatelyEqual(val1: anglePos, val2: 90.0, tolerence: 1.0))\n"
    let test2 = "NegY: \(approximatelyEqual(val1: angleNeg, val2: -90.0, tolerence: 1.0))\n"
    
    return prefix + test1 + test2 + "\n";
}

func test_getAngleFromXYZ_xy_equal() -> String{
    
    let prefix = "angle_from_xyz_xy_equal\n"
    
    let point1 = Position3D(x: 1.0, y: 1.0, z: 0.0)
    let point2 = Position3D(x: -1.0, y: -1.0, z: 0.0)
    
    let origin = Position3D(x: 0.0, y: 0.0,z: 0.0 )
    
    let anglePos = getAngleFromXYZ(endPoint: point1, origin: origin, relativePlane: Plane.XZ )
    let angleNeg = getAngleFromXYZ(endPoint: point2, origin: origin, relativePlane: Plane.XZ )
    
    let test1 = "Pos: \(approximatelyEqual(val1: anglePos, val2: 45.0, tolerence: 1.0))\n"
    let test2 = "Neg: \(approximatelyEqual(val1: angleNeg, val2: -45.0, tolerence: 1.0))\n"
    
    return prefix + test1 + test2 + "\n";
}


class ReviewViewController: UIViewController {
    @IBOutlet var textView: UITextView!
    
    @IBOutlet weak var textV: UITextView!
    
    
    var transformPrintout: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear
        
        textV.text = test_getAngleFromXYZ_xUnitVector() + test_getAngleFromXYZ_yUnitVector() + test_getAngleFromXYZ_xy_equal()
    }
    
}
