//
//  Line.swift
//  
//
//  Created by scchn on 2022/10/9.
//

import Foundation

public struct Line: Equatable, Hashable, Codable {
    
    public var start: CGPoint
    
    public var end: CGPoint
    
    public var dx: CGFloat {
        end.x - start.x
    }
    
    public var dy: CGFloat {
        end.y - start.y
    }
    
    public var mid: CGPoint {
        CGPoint(x: (start.x + end.x) / 2,
                y: (start.y + end.y) / 2)
    }
    
    public var distance: CGFloat {
        sqrt(dx * dx + dy * dy)
    }
    
    public var angle: CGFloat {
        atan2(dy, dx)
    }
    
    public init(start: CGPoint, end: CGPoint) {
        self.start = start
        self.end = end
    }
    
    public func intersectionPoint(_ line: Line) -> CGPoint? {
        let a1 = self.start.y - self.end.y
        let b1 = self.end.x - self.start.x
        let c1 = self.start.x * self.end.y - self.end.x * self.start.y
        
        let a2 = line.start.y - line.end.y
        let b2 = line.end.x - line.start.x
        let c2 = line.start.x * line.end.y - line.end.x * line.start.y
        
        let det = a1 * b2 - a2 * b1
        
        guard det != 0 else {
            return nil
        }
        
        let x = (b1 * c2 - b2 * c1) / det
        let y = (a2 * c1 - a1 * c2) / det
        
        return CGPoint(x: x, y: y)
    }
    
    public func reversed() -> Line {
        Line(start: end, end: start)
    }
    
    public mutating func reverse() {
        self = reversed()
    }
    
    public func rotated(angle: Angle) -> Line {
        let transform = CGAffineTransform.identity
            .translatedBy(x: start.x, y: start.y)
            .rotated(by: angle.radians)
        let end = CGPoint(x: dx, y: dy)
            .applying(transform)
        return .init(start: start, end: end)
    }
    
    public mutating func rotate(angle: Angle) {
        self = rotated(angle: angle)
    }
    
    public func projection(_ point: CGPoint) -> CGPoint? {
        guard distance != 0 else {
            return nil
        }
        
        let A = start
        let B = end
        let C = point
        let AC = CGPoint(x: C.x - A.x, y: C.y - A.y)
        let AB = CGPoint(x: B.x - A.x, y: B.y - A.y)
        let ACAB = AC.x * AB.x + AC.y * AB.y
        let m = ACAB / (distance * distance)
        let AD = CGPoint(x: AB.x * m, y: AB.y * m)
        
        return CGPoint(x: A.x + AD.x, y: A.y + AD.y)
    }
    
    public func contains(_ point: CGPoint) -> Bool {
        let A = (start.x - point.x) * (start.x - point.x) + (start.y - point.y) * (start.y - point.y)
        let B = (end.x - point.x) * (end.x - point.x) + (end.y - point.y) * (end.y - point.y)
        let C = (start.x - end.x) * (start.x - end.x) + (start.y - end.y) * (start.y - end.y)
        
        return (A + B + 2 * sqrt(A * B) - C < 1)
    }
    
    public func collides(with line: Line) -> Bool {
        let a1 = start.x - line.start.x
        let a2 = start.y - line.start.y
        let b1 = line.dy * dx - line.dx * dy
        let uA = (line.dx * a2 - line.dy * a1) / b1
        let uB = (dx * a2 - dy * a1) / b1
        
        return uA >= 0 && uA <= 1 && uB >= 0 && uB <= 1
    }
    
}
