//
//  BodyDetectionTests.swift
//  BodyDetectionTests
//
//  Created by Evan Morcom on 2020-03-16.
//  Copyright © 2020 Apple. All rights reserved.
//

import XCTest
@testable import BodyDetection

class BodyDetectionTests: XCTestCase {

    var code: ViewController!
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        super.setUp()
        
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        print("hsdf\n")
        
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    
    func test_getAngleFromXYZ_xUnitVector(){
        let endPointPosX = Position3D(x: 1.0, y: 0.0, z: 0.0)
        let endPointNegX = Position3D(x: 1.0, y: 0.0, z: 0.0)
        
        let origin = Position3D(x: 0.0, y: 0.0,z: 0.0 )
        
        let anglePos = code.getAngleFromXYZ(endPoint: endPointPosX, origin: origin, relativePlane: Plane.XZ )
        let angleNeg = code.getAngleFromXYZ(endPoint: endPointNegX, origin: origin, relativePlane: Plane.XZ )
        
        XCTAssertEqual(anglePos, 0.0)
        XCTAssertEqual(angleNeg, 0.0)
        
        
    }

}
