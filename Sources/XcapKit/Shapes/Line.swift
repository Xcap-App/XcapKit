//
//  Line.swift
//  
//
//  Created by scchn on 2022/10/9.
//

import Foundation

extension Line {
    
    public enum Intersection: Equatable {
        case cross(CGPoint)
        case parallel
    }
    
}

public struct Line: Equatable, Hashable, Codable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(start.x)
        hasher.combine(start.y)
        hasher.combine(end.x)
        hasher.combine(end.y)
    }
    
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
    
    func intersection(with line: Line) -> Intersection {
        func EQ(x: CGFloat, y: CGFloat) -> Bool {
            let EPS: CGFloat = 1e-5
            return abs(x - y) < EPS
        }
        
        let line1 = self, line2 = line
        let a1 = line1.end.y - line1.start.y
        let a2 = line2.end.y - line2.start.y
        let b1 = line1.start.x - line1.end.x
        let b2 = line2.start.x - line2.end.x
        let c1 = line1.end.x * line1.start.y - line1.start.x * line1.end.y
        let c2 = line2.end.x * line2.start.y - line2.start.x * line2.end.y
        
        guard !EQ(x: a1 * b2, y: b1 * a2) else {
//            if EQ(x: (a1 + b1) * c2, y: (a2 + b2) * c1) {
//                return .coincident;
//            } else {
//                return .parallel;
//            }
            return .parallel
        }
        
        let point = CGPoint(x: (b2 * c1 - b1 * c2) / (a2 * b1 - a1 * b2),
                            y: (a1 * c2 - a2 * c1) / (a2 * b1 - a1 * b2))
        
        return.cross(point);
    }
    
    public func collides(with line: Line) -> Bool {
        let a1 = start.x - line.start.x
        let a2 = start.y - line.start.y
        let b1 = line.dy * dx - line.dx * dy
        let uA = (line.dx * a2 - line.dy * a1) / b1
        let uB = (dx * a2 - dy * a1) / b1
        
        return uA >= 0 && uA <= 1 && uB >= 0 && uB <= 1
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
    
    public func contains(_ point: CGPoint) -> Bool {
        let A = (start.x - point.x) * (start.x - point.x) + (start.y - point.y) * (start.y - point.y)
        let B = (end.x - point.x) * (end.x - point.x) + (end.y - point.y) * (end.y - point.y)
        let C = (start.x - end.x) * (start.x - end.x) + (start.y - end.y) * (start.y - end.y)
        
        return (A + B + 2 * sqrt(A * B) - C < 1)
    }
    
}
