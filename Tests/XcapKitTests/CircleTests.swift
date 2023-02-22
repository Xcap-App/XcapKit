import XCTest
@testable import XcapKit

class CircleTests: XCTestCase {
    
    func test_hashable() {
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
    
    func test_init_with_3_points() {
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
    
    func test_line_intersection_points() {
        let circle = Circle(center: .zero, radius: 20)
        
        // 1 Intersection
        let line_1_intersection = Line(start: .init(x: -10, y: 20), end: .init(x: 10, y: 20))
        let result0 = circle.intersectionPoints(line_1_intersection)
        
        XCTAssertEqual(result0.first, .init(x: 0, y: 20))
        XCTAssertTrue(result0.count == 1)
        
        // 1 Intersection
        let lines_1_intersection = (0..<360).map { angle in
            let angle = Angle.degrees(angle)
            let end = circle.center.extended(length: circle.radius, angle: angle.radians)
            return Line(start: .zero, end: end)
        }
        
        let result1_1 = lines_1_intersection.allSatisfy { line in
            circle.intersectionPoints(line).count == 1
        }
        
        XCTAssertTrue(result1_1)
        
        let result_1_2 = lines_1_intersection.allSatisfy { line in
            let intersections = circle.intersectionPoints(line)
            return circle.center.distance(with: intersections[0]) - circle.radius < 0.000001
        }
        
        XCTAssertTrue(result_1_2)
        
        // 2 Intersections
        let lines_2_intersection = (0..<360).map { angle in
            let angle = Angle.degrees(angle)
            let start = circle.center.extended(length: circle.radius * 2, angle: angle.radians)
            let end = circle.center.extended(length: circle.radius * 2, angle: angle.radians + .pi)
            return Line(start: start, end: end)
        }
        
        let result_2_1 = lines_2_intersection.allSatisfy { line in
            circle.intersectionPoints(line).count == 2
        }
        
        XCTAssertTrue(result_2_1)
        
        let result_2_2 = lines_2_intersection.allSatisfy { line in
            circle.intersectionPoints(line)
                .allSatisfy { point in
                    circle.center.distance(with: point) - circle.radius < 0.000001
                }
        }
        
        XCTAssertTrue(result_2_2)
        
        // No Intersection (In)
        let lines_no_intersection_1 = (0..<360).map { angle in
            let angle = Angle.degrees(angle)
            let end = circle.center.extended(length: circle.radius - 1, angle: angle.radians + .pi)
            return Line(start: .zero, end: end)
        }
        let result3 = lines_no_intersection_1.allSatisfy { line in
            circle.intersectionPoints(line).isEmpty
        }
        
        XCTAssertTrue(result3)
        
        // No Intersection (out)
        let lines_no_intersection_2 = (0..<360).map { angle in
            let angle = Angle.degrees(angle)
            let start = circle.center.extended(length: circle.radius + 1, angle: angle.radians + .pi)
            let end = circle.center.extended(length: circle.radius * 2, angle: angle.radians + .pi)
            return Line(start: start, end: end)
        }
        let result4 = lines_no_intersection_2.allSatisfy { line in
            circle.intersectionPoints(line).isEmpty
        }
        
        XCTAssertTrue(result4)
        
        // No Intersection
        let line_no_intersection = Line(start: .zero, end: .zero)
        let result5 = circle.intersectionPoints(line_no_intersection)
        XCTAssertTrue(result5.isEmpty)
    }
    
}
