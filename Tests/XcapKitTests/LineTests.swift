import XCTest

@testable import XcapKit

class LineTests: XCTestCase {
    
    func testLine_Hashable() {
        let line1 = Line(start: .zero, end: .init(x: 0, y: 0))
        let line2 = Line(start: .zero, end: .init(x: 1, y: 0))
        let line3 = Line(start: .zero, end: .init(x: 2, y: 0))
        let dict = [
            line1: 0,
            line2: 1,
            line3: 2,
        ]
        
        XCTAssertEqual(dict[line1], 0)
        XCTAssertEqual(dict[line2], 1)
        XCTAssertEqual(dict[line3], 2)
    }
    
    func testLine_vars() {
        let line1 = Line(start: .zero, end: CGPoint(x: 10, y: 10))
        
        XCTAssertEqual(line1.dx, 10)
        XCTAssertEqual(line1.dy, 10)
        XCTAssertEqual(line1.mid, .init(x: 5, y: 5))
        XCTAssertEqual(Angle.radians(line1.angle), Angle.degrees(45))
    }
    
    func testLine_contains() {
        let line = Line(start: .zero, end: CGPoint(x: 10, y: 10))
        
        XCTAssertTrue(line.contains(.init(x: 5, y: 5)))
    }
    
    func testLine_rotated() {
        var line = Line(start: .zero, end: CGPoint(x: 10, y: 0))
        
        line.rotate(angle: Angle.degrees(90))
        
        XCTAssertEqual(line.start, .zero)
        XCTAssertLessThan(line.end.x, 1e-5)
        XCTAssertEqual(line.end.y, 10)
    }
    
    func testLine_intersectionType() {
        let line = Line(start: .zero, end: CGPoint(x: 10, y: 10))
        let line2 = Line(start: .init(x: 0, y: 1), end: CGPoint(x: 10, y: 11))
        let line3 = Line(start: .init(x: 10, y: 0), end: CGPoint(x: 0, y: 10))
        
        XCTAssertEqual(line.intersection(with: line2), .parallel)
        XCTAssertEqual(line.intersection(with: line3), .cross(.init(x: 5, y: 5)))
    }
    
    func testLine_collides() {
        let line = Line(start: .zero, end: CGPoint(x: 10, y: 10))
        let line2 = Line(start: .init(x: 0, y: 1), end: CGPoint(x: 10, y: 11))
        let line3 = Line(start: .init(x: 10, y: 0), end: CGPoint(x: 0, y: 10))
        
        XCTAssertFalse(line.collides(with: line2))
        XCTAssertTrue(line.collides(with: line3))
    }
    
}
