import XCTest
@testable import XcapKit

class AngleTests: XCTestCase {
    
    func test_angle() {
        let deg = Angle.degrees(90.0)
        let rad = Angle.radians(.pi / 2)
        
        XCTAssertEqual(deg, rad)
        XCTAssertEqual(deg.radians, .pi / 2)
        XCTAssertEqual(rad.degrees, 90)
    }
    
}
