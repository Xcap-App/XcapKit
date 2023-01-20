import XCTest
@testable import XcapKit

class ArcTests: XCTestCase {
    
    func testArc_angle() {
        func degText(rad: CGFloat) -> String {
            "deg = \(Angle(radians: rad).degrees)"
        }
        
        // 45 ~ 315
        var arc1 = Arc(center: .zero,
                       startPoint: .init(x: 10, y: -10),
                       endPoint: .init(x: 10, y: 10))
        
        XCTAssertEqual(arc1.angle, Angle.degrees(270).radians, degText(rad: arc1.angle))
        arc1.clockwise.toggle()
        XCTAssertEqual(arc1.angle, Angle.degrees(90).radians, degText(rad: arc1.angle))
        
        // 225 ~ 360
        var arc2 = Arc(center: .zero,
                       startPoint: .init(x: 10, y: 0),
                       endPoint: .init(x: -10, y: -10))
        
        XCTAssertEqual(arc2.angle, Angle.degrees(135).radians, degText(rad: arc2.angle))
        arc2.clockwise.toggle()
        XCTAssertEqual(arc2.angle, Angle.degrees(225).radians, degText(rad: arc2.angle))
        
        // 45 ~ 225
        var arc3 = Arc(center: .zero,
                       start: Angle.degrees(45).radians,
                       end: -Angle.degrees(135).radians,
                       clockwise: true)
        
        XCTAssertEqual(arc3.angle, Angle.degrees(180).radians, degText(rad: arc3.angle))
        arc3.clockwise.toggle()
        XCTAssertEqual(arc3.angle, Angle.degrees(180).radians, degText(rad: arc3.angle))
        
        // 90 ~ 360
        var arc4 = Arc(center: .zero,
                       start: Angle.degrees(90).radians,
                       end: Angle.degrees(0).radians,
                       clockwise: true)
        
        XCTAssertEqual(arc4.angle, Angle.degrees(90).radians, degText(rad: arc4.angle))
        arc4.clockwise.toggle()
        XCTAssertEqual(arc4.angle, Angle.degrees(270).radians, degText(rad: arc4.angle))
        
        // 45 ~ 270
        var arc5 = Arc(center: .zero,
                       start: -Angle.degrees(90).radians,
                       end: Angle.degrees(45).radians,
                       clockwise: true)

        XCTAssertEqual(arc5.angle, Angle.degrees(225).radians, degText(rad: arc5.angle))
        arc5.clockwise.toggle()
        XCTAssertEqual(arc5.angle, Angle.degrees(135).radians, degText(rad: arc5.angle))
    }
    
    func testArc_contains_angle() {
        // 45 ~ -45
        let arc1 = Arc(center: .zero,
                       start: Angle.degrees(45).radians,
                       end: -Angle.degrees(45).radians,
                       clockwise: true)
        
        // ----- In -----
        for deg in -45...45 {
            let angle = Angle.degrees(CGFloat(deg))
            XCTAssertTrue(arc1.contains(angle.radians), "deg=\(deg)")
        }
        
        // ----- Out -----
        for deg in 46...314 {
            let angle = Angle.degrees(CGFloat(deg))
            XCTAssertFalse(arc1.contains(angle.radians), "deg=\(deg)")
        }
        
        // 45 ~ 315
        let arc2 = Arc(center: .zero,
                       start: Angle.degrees(45).radians,
                       end: -Angle.degrees(45).radians,
                       clockwise: false)
        
        // ----- In -----
        for deg in 45...315 {
            let angle = Angle.degrees(CGFloat(deg))
            XCTAssertTrue(arc2.contains(angle.radians), "deg=\(deg)")
        }
        
        // ----- Out -----
        for deg in -44...44 {
            let angle = Angle.degrees(CGFloat(deg))
            XCTAssertFalse(arc2.contains(angle.radians), "deg=\(deg)")
        }
    }
    
    func testArc_contains_point() {
        let eps = 1e-5
        let radius = 10.0
        
        // -270 ~ 45
        let arc1 = Arc(center: .zero,
                       start: Angle.degrees(45).radians,
                       end: Angle.degrees(90).radians,
                       clockwise: true)
        
        // ----- In -----
        for deg in -270...45 {
            let angle = Angle.degrees(CGFloat(deg))
            let point = arc1.center.extended(length: radius - eps, angle: angle.radians)
            XCTAssertTrue(arc1.contains(point, radius: radius), "deg=\(deg)")
        }
        
        // ----- Out -----
        for deg in 46...89 {
            let angle = Angle.degrees(CGFloat(deg))
            let point = arc1.center.extended(length: radius - eps, angle: angle.radians)
            XCTAssertFalse(arc1.contains(point, radius: radius), "deg=\(deg)")
        }
        
        // 45 ~ 90
        let arc2 = Arc(center: .zero,
                       start: Angle.degrees(45).radians,
                       end: Angle.degrees(90).radians,
                       clockwise: false)
        
        // ----- In -----
        for deg in 45...90 {
            let angle = Angle.degrees(CGFloat(deg))
            let point = arc2.center.extended(length: radius - eps, angle: angle.radians)
            XCTAssertTrue(arc2.contains(point, radius: radius), "deg=\(deg)")
        }
        
        // ----- Out -----
        for deg in -269...44 {
            let angle = Angle.degrees(CGFloat(deg))
            let point = arc2.center.extended(length: radius - eps, angle: angle.radians)
            XCTAssertFalse(arc2.contains(point, radius: radius), "deg=\(deg)")
        }
        
        // 90 ~ 315
        let arc3 = Arc(center: .zero,
                       start: -Angle.degrees(45).radians,
                       end: Angle.degrees(90).radians,
                       clockwise: true)
        
        // ----- In -----
        for deg in 90...315 {
            let angle = Angle.degrees(CGFloat(deg))
            let point = arc3.center.extended(length: radius - eps, angle: angle.radians)
            XCTAssertTrue(arc3.contains(point, radius: radius), "deg=\(deg)")
        }
        
        // ----- Out -----
        for deg in -44...89 {
            let angle = Angle.degrees(CGFloat(deg))
            let point = arc3.center.extended(length: radius - eps, angle: angle.radians)
            XCTAssertFalse(arc3.contains(point, radius: radius), "deg=\(deg)")
        }
    }
    
}
