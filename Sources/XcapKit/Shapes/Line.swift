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
        CGPoint(
            x: (start.x + end.x) / 2,
            y: (start.y + end.y) / 2
        )
    }
    
    public var length: CGFloat {
        hypot(dx, dy)
    }
    
    public var angle: CGFloat {
        atan2(dy, dx)
    }
    
    public init(start: CGPoint, end: CGPoint) {
        self.start = start
        self.end = end
    }
    
    public func reversed() -> Line {
        Line(start: end, end: start)
    }
    
    public mutating func reverse() {
        self = reversed()
    }
    
    public func contains(_ point: CGPoint) -> Bool {
        let a = (start.x - point.x) * (start.x - point.x) + (start.y - point.y) * (start.y - point.y)
        let b = (end.x - point.x) * (end.x - point.x) + (end.y - point.y) * (end.y - point.y)
        let c = (start.x - end.x) * (start.x - end.x) + (start.y - end.y) * (start.y - end.y)
        
        return (a + b + 2 * sqrt(a * b) - c < 1)
    }
    
    public func collides(with line: Line) -> Bool {
        let a1 = start.x - line.start.x
        let a2 = start.y - line.start.y
        let b1 = line.dy * dx - line.dx * dy
        let uA = (line.dx * a2 - line.dy * a1) / b1
        let uB = (dx * a2 - dy * a1) / b1
        
        return uA >= 0 && uA <= 1 && uB >= 0 && uB <= 1
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
    
    public func projectionPoint(_ point: CGPoint) -> CGPoint? {
        guard length != 0 else {
            return nil
        }
        
        let lineVec = CGPoint(x: dx, y: dy)
        let pointVec = CGPoint(x: point.x - start.x, y: point.y - start.y)
        let scalarProjection = (
            (pointVec.x * lineVec.x + pointVec.y * lineVec.y) /
            (lineVec.x * lineVec.x + lineVec.y * lineVec.y)
        )
        
        return  CGPoint(
            x: start.x + scalarProjection * lineVec.x,
            y: start.y + scalarProjection * lineVec.y
        )
    }
    
}
