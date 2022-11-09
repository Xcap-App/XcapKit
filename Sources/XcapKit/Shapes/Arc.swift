//
//  Arc.swift
//  
//
//  Created by scchn on 2022/10/10.
//

import Foundation

public struct Arc: Equatable, Hashable, Codable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(center.x)
        hasher.combine(center.y)
        hasher.combine(radius)
        hasher.combine(start)
        hasher.combine(end)
        hasher.combine(clockwise)
    }
    
    public var center: CGPoint
    
    public var radius: CGFloat
    
    public var start: CGFloat
    
    public var end: CGFloat
    
    public var clockwise: Bool
    
    public var angle: CGFloat {
        let (start, end, clockwise) = transformed()
        
        return clockwise
            ? end - start
            : .pi * 2 - (end - start)
    }
    
    public init(center: CGPoint, radius: CGFloat, start: CGFloat, end: CGFloat, clockwise: Bool) {
        self.center = center
        self.radius = radius
        self.start = start
        self.end = end
        self.clockwise = clockwise
    }
    
    public init(vertex: CGPoint, radius: CGFloat, point1: CGPoint, point2: CGPoint) {
        let line1 = Line(start: vertex, end: point1)
        let line2 = Line(start: vertex, end: point2)
        
        self.init(center: vertex,
                  radius: radius,
                  start: line1.angle,
                  end: line2.angle,
                  clockwise: true)
        
        clockwise = angle <= .pi
    }
    
    private func normalizedAngle(_ angle: CGFloat) -> CGFloat {
        let cirRad = CGFloat.pi * 2
        let angle = angle.truncatingRemainder(dividingBy: cirRad)
        
        return angle >= 0
            ? angle
            : cirRad + angle
    }
    
    private func transformed() -> (start: CGFloat, end: CGFloat, clockwise: Bool) {
        let start = normalizedAngle(start)
        let end = normalizedAngle(end)
        
        return start > end
            ? (end, start, !clockwise)
            : (start, end, clockwise)
    }
    
    public func contains(_ angle: CGFloat) -> Bool {
        let target = normalizedAngle(angle)
        let (start, end, clockwise) = transformed()
        
        return clockwise
            ? (start...end).contains(target)
            : target <= start || target >= end
    }
    
    public func contains(_ point: CGPoint) -> Bool {
        let line = Line(start: center, end: point)
        
        return line.distance <= radius && contains(line.angle)
    }
    
}
