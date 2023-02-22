import XCTest
@testable import XcapKit

class CGPointTests: XCTestCase {
    
    func test_mid() {
        let p1 = CGPoint(x: 0, y: 0)
        let p2 = CGPoint(x: 10, y: 0)
        XCTAssertEqual(p1.mid(with: p2), CGPoint(x: 5, y: 0))
    }
    
    func test_distance() {
        let p1 = CGPoint(x: 0, y: 0)
        let p2 = CGPoint(x: 10, y: 0)
        XCTAssertEqual(p1.distance(with: p2), 10)
    }
    
    func test_extended() {
        let p = CGPoint(x: 0, y: 0)
        let extended = p.extended(length: 10, angle: .pi / 2)
        XCTAssertLessThan(extended.x, 1e-5)
        XCTAssertEqual(extended.y, 10)
    }
    
}
