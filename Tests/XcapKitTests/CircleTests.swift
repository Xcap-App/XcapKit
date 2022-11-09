import XCTest
@testable import XcapKit

class CustomTypesTests: XCTestCase {
    
    func testCircle_Hashable() {
        let circle1 = Circle(center: .zero, radius: 0)
        let circle2 = Circle(center: .zero, radius: 1)
        let circle3 = Circle(center: .zero, radius: 2)
        let dict = [
            circle1: 0,
            circle2: 1,
            circle3: 2,
        ]
        
        XCTAssertEqual(dict[circle1], 0)
        XCTAssertEqual(dict[circle2], 1)
        XCTAssertEqual(dict[circle3], 2)
    }
    
    func testCircle_initWith3Points() {
        XCTAssertNil(Circle(.zero, .zero, .zero))
        XCTAssertNil(Circle(.init(x: -10, y: 0), .init(x: 0, y: 0), .init(x: 10, y: 0)))
        XCTAssertNil(Circle(.init(x: 0, y: 10), .init(x: 0, y: 0), .init(x: 0, y: -10)))
        
        let p1 = CGPoint(x: -10, y: 0)
        let p2 = CGPoint(x: 10, y: 0)
        let p3 = CGPoint(x: 0, y: 10)
        
        guard let circle = Circle(p1, p2, p3) else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(circle.radius, 10)
        XCTAssertEqual(circle.center, .zero)
        
        XCTAssertTrue(circle.contains(.zero))
        XCTAssertTrue(circle.contains(p1))
        XCTAssertTrue(circle.contains(p2))
        XCTAssertTrue(circle.contains(p3))
        XCTAssertFalse(circle.contains(.init(x: 11, y: 0)))
    }
    
}
