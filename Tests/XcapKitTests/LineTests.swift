import XCTest
@testable import XcapKit

class LineTests: XCTestCase {
    
    func test_hashable() {
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
    
    func test_vars() {
        let line1 = Line(start: .zero, end: CGPoint(x: 10, y: 10))
        
        XCTAssertEqual(line1.dx, 10)
        XCTAssertEqual(line1.dy, 10)
        XCTAssertEqual(line1.mid, .init(x: 5, y: 5))
        XCTAssertEqual(Angle.radians(line1.angle), Angle.degrees(45))
    }
    
    func test_reversed() {
        let start = CGPoint(x: 0, y: 0)
        let end = CGPoint(x: 1, y: 1)
        var line = Line(start: start, end: end)
        
        line.reverse()
        
        XCTAssertEqual(line.start, end)
        XCTAssertEqual(line.end, start)
    }
    
    func test_contains() {
        let line = Line(start: .zero, end: CGPoint(x: 10, y: 10))
        
        XCTAssertTrue(line.contains(.init(x: 5, y: 5)))
    }
    
    func test_collides() {
        let line = Line(start: .zero, end: CGPoint(x: 10, y: 10))
        let line2 = Line(start: .init(x: 0, y: 1), end: CGPoint(x: 10, y: 11))
        let line3 = Line(start: .init(x: 10, y: 0), end: CGPoint(x: 0, y: 10))
        
        XCTAssertFalse(line.collides(with: line2))
        XCTAssertTrue(line.collides(with: line3))
    }
    
    func test_intersection_points() {
        let line = Line(start: .zero, end: CGPoint(x: 10, y: 10))
        let line2 = Line(start: .init(x: 0, y: 1), end: CGPoint(x: 10, y: 11))
        let line3 = Line(start: .init(x: 10, y: 0), end: CGPoint(x: 0, y: 10))
        
        XCTAssertEqual(line.intersectionPoint(line2), nil)
        XCTAssertEqual(line.intersectionPoint(line3), .init(x: 5, y: 5))
    }
    
    func test_projection_points() {
        func erase(_ point: CGPoint?) -> CGPoint? {
            guard let point = point else {
                return nil
            }
            
            let n = CGFloat(pow(10.0, 8))
            
            return CGPoint(
                x: (point.x * n).rounded() / n,
                y: (point.y * n).rounded() / n
            )
        }
        
        let line1 = Line(start: .zero, end: .init(x: 10, y: 10))
        let p1 = line1.projectionPoint(.init(x: 10, y: 0))
        XCTAssertEqual(erase(p1), .init(x: 5, y: 5))
        
        let line2 = Line(start: .zero, end: .init(x: -10, y: 10))
        let p2 = line2.projectionPoint(.init(x: 0, y: 10))
        XCTAssertEqual(erase(p2), .init(x: -5, y: 5))
        
        let line3 = Line(start: .zero, end: .init(x: -10, y: -10))
        let p3 = line3.projectionPoint(.init(x: -10, y: 0))
        XCTAssertEqual(erase(p3), .init(x: -5, y: -5))
        
        let line4 = Line(start: .zero, end: .init(x: 10, y: -10))
        let p4 = line4.projectionPoint(.init(x: -10, y: 0))
        XCTAssertEqual(erase(p4), .init(x: -5, y: 5))
        
        let line5 = Line(start: .zero, end: .zero)
        let p5 = line5.projectionPoint(.zero)
        XCTAssertNil(p5)
    }
    
}
