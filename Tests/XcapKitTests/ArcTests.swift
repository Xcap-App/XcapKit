import XCTest
@testable import XcapKit

class ArcTests: XCTestCase {
    
    func testArc_init() {
        let arc1 = Arc(vertex: .zero,
                       radius: 10,
                       point1: .init(x: 10, y: -10),
                       point2: .init(x: 10, y: 10))
        
        XCTAssertEqual(arc1.angle, Angle(degrees: 90).radians)
        XCTAssertTrue(arc1.clockwise)
        
        let arc2 = Arc(vertex: .zero,
                       radius: 10,
                       point1: .init(x: 10, y: 0),
                       point2: .init(x: -10, y: -10))
        
        XCTAssertEqual(arc2.angle, Angle(degrees: 135).radians)
        XCTAssertFalse(arc2.clockwise)
    }
    
    func testArc_angle() {
        // 45 ~ 225
        
        var arc1 = Arc(center: .zero,
                       radius: 10,
                       start: Angle(degrees: 45).radians,
                       end: -Angle(degrees: 135).radians,
                       clockwise: true)
        
        XCTAssertEqual(arc1.angle, Angle(degrees: 180).radians)
        arc1.clockwise.toggle()
        XCTAssertEqual(arc1.angle, Angle(degrees: 180).radians)
        
        // 90 ~ 360
        
        var arc2 = Arc(center: .zero,
                       radius: 10,
                       start: Angle(degrees: 90).radians,
                       end: Angle(degrees: 0).radians,
                       clockwise: true)
        
        XCTAssertEqual(arc2.angle, Angle(degrees: 270).radians)
        arc2.clockwise.toggle()
        XCTAssertEqual(arc2.angle, Angle(degrees: 90).radians)
        
        // 45 ~ 270
        
        var arc3 = Arc(center: .zero,
                       radius: 10,
                       start: -Angle(degrees: 90).radians,
                       end: Angle(degrees: 45).radians,
                       clockwise: true)
        
        XCTAssertEqual(arc3.angle, Angle(degrees: 135).radians)
        arc3.clockwise.toggle()
        XCTAssertEqual(arc3.angle, Angle(degrees: 225).radians)
    }
    
    func testArc_contains_angle() {
        // 45 ~ 315
        
        let arc1 = Arc(center: .zero,
                       radius: 10,
                       start: Angle(degrees: 45).radians,
                       end: -Angle(degrees: 45).radians,
                       clockwise: true)
        
        for deg in 45...315 {
            let angle = Angle(degrees: CGFloat(deg))
            XCTAssertTrue(arc1.contains(angle.radians), "deg=\(deg)")
        }
        
        for deg in -44...44 {
            let angle = Angle(degrees: CGFloat(deg))
            XCTAssertFalse(arc1.contains(angle.radians), "deg=\(deg)")
        }
        
        // -45 ~ 45
        
        let arc2 = Arc(center: .zero,
                       radius: 10,
                       start: Angle(degrees: 45).radians,
                       end: -Angle(degrees: 45).radians,
                       clockwise: false)
        
        for deg in -45...45 {
            let angle = Angle(degrees: CGFloat(deg))
            XCTAssertTrue(arc2.contains(angle.radians), "deg=\(deg)")
        }
        
        for deg in 46...314 {
            let angle = Angle(degrees: CGFloat(deg))
            XCTAssertFalse(arc2.contains(angle.radians), "deg=\(deg)")
        }
    }
    
    func testArc_contains_point() {
        let eps = 1e-5
        
        // 45 ~ 90
        
        let arc1 = Arc(center: .zero,
                       radius: 10,
                       start: Angle(degrees: 45).radians,
                       end: Angle(degrees: 90).radians,
                       clockwise: true)
        
        for deg in 45...90 {
            let angle = Angle(degrees: CGFloat(deg))
            let point = arc1.center.extended(length: arc1.radius - eps, angle: angle.radians)
            XCTAssertTrue(arc1.contains(point), "deg=\(deg)")
        }
        
        for deg in -269...44 {
            let angle = Angle(degrees: CGFloat(deg))
            let point = arc1.center.extended(length: arc1.radius - eps, angle: angle.radians)
            XCTAssertFalse(arc1.contains(point), "deg=\(deg)")
        }
        
        // -270 ~ 45
        
        let arc2 = Arc(center: .zero,
                       radius: 10,
                       start: Angle(degrees: 45).radians,
                       end: Angle(degrees: 90).radians,
                       clockwise: false)
        
        for deg in -270...45 {
            let angle = Angle(degrees: CGFloat(deg))
            let point = arc2.center.extended(length: arc2.radius - eps, angle: angle.radians)
            XCTAssertTrue(arc2.contains(point), "deg=\(deg)")
        }
        
        for deg in 46...89 {
            let angle = Angle(degrees: CGFloat(deg))
            let point = arc2.center.extended(length: arc2.radius - eps, angle: angle.radians)
            XCTAssertFalse(arc2.contains(point), "deg=\(deg)")
        }
    }
    
}
