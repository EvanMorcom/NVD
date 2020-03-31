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

func test_getAngleFromXYZ_xUnitVector_shifted_origin() -> String{
    
    let prefix = "angle_from_xyz_x_unit_vector_shifted_origin\n"
    
    let endPointPosX = Position3D(x: 2.0, y: 1.0, z: 1.0)
    let endPointNegX = Position3D(x: -2.0, y: 1.0, z: 1.0)
    
    let origin = Position3D(x: 1.0, y: 1.0,z: 1.0 )
    
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

func test_getAngleFromXYZ_xy_equal_plus_z() -> String{
    
    let prefix = "angle_from_xyz_xy_equal_plus_z\n"
    
    let point1 = Position3D(x: 0.707, y: 1.0, z: 0.707)
    let point2 = Position3D(x: -0.707, y: -1.0, z: 0.707)
    
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
        
        textV.text = test_getAngleFromXYZ_xUnitVector() + test_getAngleFromXYZ_yUnitVector() + test_getAngleFromXYZ_xy_equal() + test_getAngleFromXYZ_xy_equal_plus_z() + test_getAngleFromXYZ_xUnitVector_shifted_origin()
        
        let check = "✔️"
        let cross = "❌"
        var topFeedback = ""
        var middleFeedback = ""
        var bottomFeedback = ""
        
        if(topFeedbackAngle < Float(5.0)){
            topFeedback = "Top Position:\n\(check)\n\n"
        }
        else {
            topFeedback = "Top Position:\n\(cross) Your arms need to be \(makeDegreeStringPretty(deg:topFeedbackAngle)) higher!\n\n"
        }
        if(middleFeedbackAngle < Float(5.0)){
            middleFeedback = "Middle Position:\n\(check)\n\n"
        }
        else {
            middleFeedback = "Middle Position:\n\(cross) Your left arm is trailing your right by \(makeDegreeStringPretty(deg: middleFeedbackAngle))!\n\n"
        }
        if(bottomFeedbackAngle < Float(5.0)){
            bottomFeedback = "Bottom Position:\n\(check)\n\n"
        }
        else {
            bottomFeedback = "Bottom Position:\n\(cross) Your arms need to be \(makeDegreeStringPretty(deg: bottomFeedbackAngle)) lower!\n\n"
        }

        
        
        
        textV.text = topFeedback + middleFeedback + bottomFeedback 
    }
    
}
