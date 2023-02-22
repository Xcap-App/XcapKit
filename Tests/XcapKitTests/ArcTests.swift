import XCTest
@testable import XcapKit

class ArcTests: XCTestCase {
    
    func test_angle() {
        // 45 ~ 315
        var arc1 = Arc(
            center: .zero,
            startPoint: .init(x: 10, y: -10),
            endPoint: .init(x: 10, y: 10)
        )
        
        XCTAssertEqual(arc1.angle, Angle.degrees(270).radians)
        arc1.clockwise.toggle()
        XCTAssertEqual(arc1.angle, Angle.degrees(90).radians)
        
        // 225 ~ 360
        var arc2 = Arc(
            center: .zero,
            startPoint: .init(x: 10, y: 0),
            endPoint: .init(x: -10, y: -10)
        )
        
        XCTAssertEqual(arc2.angle, Angle.degrees(135).radians)
        arc2.clockwise.toggle()
        XCTAssertEqual(arc2.angle, Angle.degrees(225).radians)
        
        // 45 ~ 225
        var arc3 = Arc(
            center: .zero,
            start: Angle.degrees(45).radians,
            end: -Angle.degrees(135).radians,
            clockwise: true
        )
        
        XCTAssertEqual(arc3.angle, Angle.degrees(180).radians)
        arc3.clockwise.toggle()
        XCTAssertEqual(arc3.angle, Angle.degrees(180).radians)
        
        // 90 ~ 360
        var arc4 = Arc(
            center: .zero,
            start: Angle.degrees(90).radians,
            end: Angle.degrees(0).radians,
            clockwise: true
        )
        
        XCTAssertEqual(arc4.angle, Angle.degrees(90).radians)
        arc4.clockwise.toggle()
        XCTAssertEqual(arc4.angle, Angle.degrees(270).radians)
        
        // 45 ~ 270
        var arc5 = Arc(
            center: .zero,
            start: -Angle.degrees(90).radians,
            end: Angle.degrees(45).radians,
            clockwise: true
        )

        XCTAssertEqual(arc5.angle, Angle.degrees(225).radians)
        arc5.clockwise.toggle()
        XCTAssertEqual(arc5.angle, Angle.degrees(135).radians)
    }
    
    func test_contains_angle() {
        // 45 ~ -45
        let arc1 = Arc(
            center: .zero,
            start: Angle.degrees(45).radians,
            end: -Angle.degrees(45).radians,
            clockwise: true
        )
        
        // ----- In -----
        let result1 = (-45...45)
            .map(Angle.degrees(_:))
            .map(\.radians)
            .allSatisfy(arc1.contains(_:))
        
        XCTAssertTrue(result1)
        
        // ----- Out -----
        let result2 = (46...314)
            .map(Angle.degrees(_:))
            .map(\.radians)
            .allSatisfy { angle in
                !arc1.contains(angle)
            }
        
        XCTAssertTrue(result2)
        
        // 45 ~ 315
        let arc2 = Arc(
            center: .zero,
            start: Angle.degrees(45).radians,
            end: -Angle.degrees(45).radians,
            clockwise: false
        )
        
        // ----- In -----
        let result3 = (45...315)
            .map(Angle.degrees(_:))
            .map(\.radians)
            .allSatisfy(arc2.contains(_:))
        
        XCTAssertTrue(result3)
        
        // ----- Out -----
        let result4 = (-44...44)
            .map(Angle.degrees(_:))
            .map(\.radians)
            .allSatisfy { angle in
                !arc2.contains(angle)
            }
        
        XCTAssertTrue(result4)
    }
    
    func test_contains_point() {
        let eps = 1e-5
        let radius = 10.0
        
        // -270 ~ 45
        let arc1 = Arc(
            center: .zero,
            start: Angle.degrees(45).radians,
            end: Angle.degrees(90).radians,
            clockwise: true
        )
        
        // ----- In -----
        let result1 = (-270...45)
            .map(Angle.degrees(_:))
            .map(\.radians)
            .allSatisfy { angle in
                let point = arc1.center.extended(length: radius - eps, angle: angle)
                return arc1.contains(point, radius: radius)
            }
        
        XCTAssertTrue(result1)
        
        // ----- Out -----
        let result2 = (46...89)
            .map(Angle.degrees(_:))
            .map(\.radians)
            .allSatisfy { angle in
                let point = arc1.center.extended(length: radius - eps, angle: angle)
                return !arc1.contains(point, radius: radius)
            }
        
        XCTAssertTrue(result2)
        
        // 45 ~ 90
        let arc2 = Arc(
            center: .zero,
            start: Angle.degrees(45).radians,
            end: Angle.degrees(90).radians,
            clockwise: false
        )
        
        // ----- In -----
        let result3 = (45...90)
            .map(Angle.degrees(_:))
            .map(\.radians)
            .allSatisfy { angle in
                let point = arc2.center.extended(length: radius - eps, angle: angle)
                return arc2.contains(point, radius: radius)
            }
        
        XCTAssertTrue(result3)
        
        // ----- Out -----
        let result4 = (-269...44)
            .map(Angle.degrees(_:))
            .map(\.radians)
            .allSatisfy { angle in
                let point = arc2.center.extended(length: radius - eps, angle: angle)
                return !arc2.contains(point, radius: radius)
            }
        
        XCTAssertTrue(result4)
        
        // 90 ~ 315
        let arc3 = Arc(
            center: .zero,
            start: -Angle.degrees(45).radians,
            end: Angle.degrees(90).radians,
            clockwise: true
        )
        
        // ----- In -----
        let result5 = (90...315)
            .map(Angle.degrees(_:))
            .map(\.radians)
            .allSatisfy { angle in
                let point = arc3.center.extended(length: radius - eps, angle: angle)
                return arc3.contains(point, radius: radius)
            }
        
        XCTAssertTrue(result5)
        
        // ----- Out -----
        let result6 = (-44...89)
            .map(Angle.degrees(_:))
            .map(\.radians)
            .allSatisfy { angle in
                let point = arc3.center.extended(length: radius - eps, angle: angle)
                return !arc3.contains(point, radius: radius)
            }
        
        XCTAssertTrue(result6)
    }
    
    func test_line_intersection_points() {
        let arc = Arc(center: .zero, start: 0, end: .pi, clockwise: true)
        let radius: CGFloat = 20
        let lines = (0..<360).map { angle in
            let angle = Angle.degrees(angle)
            let end = arc.center.extended(length: radius, angle: angle.radians)
            return Line(start: .zero, end: end)
        }
        let result1 = lines.filter { line in
            arc.intersectionPoints(line, radius: radius).count == 1
        }
        
        XCTAssertEqual(result1.count, 181) // 0 ~ 180
        
        let result2 = lines.filter { line in
            arc.intersectionPoints(line, radius: radius).isEmpty
        }
        
        XCTAssertEqual(result2.count, 179)
    }
    
    func test_to_minor_arc() {
        let arc1 = Arc(center: .zero, start: .pi / 4, end: 0, clockwise: true) // 45
        let minorArc1 = arc1.toMinorArc() // 45
        XCTAssertEqual(minorArc1.angle, arc1.angle)
        
        let arc2 = Arc(center: .zero, start: .pi * 1.5, end: 0, clockwise: true) // 270
        let minorArc2 = arc2.toMinorArc() // 90
        XCTAssertEqual(minorArc2.angle, .pi / 2)
    }
    
    func test_to_major_arc() {
        let arc1 = Arc(center: .zero, start: .pi / 2, end: 0, clockwise: true) // 90
        let majorArc1 = arc1.toMajorArc() // 270
        XCTAssertEqual(majorArc1.angle, .pi * 1.5)
        
        let arc2 = Arc(center: .zero, start: .pi * 1.5, end: 0, clockwise: true) // 270
        let majorArc2 = arc2.toMajorArc() // 270
        XCTAssertEqual(majorArc2.angle, arc2.angle)
    }
    
}
