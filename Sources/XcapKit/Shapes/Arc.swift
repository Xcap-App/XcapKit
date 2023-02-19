//
//  Arc.swift
//  
//
//  Created by scchn on 2022/10/10.
//

import Foundation

public struct Arc: Equatable, Hashable, Codable {
    
    public var center: CGPoint
    
    public var start: CGFloat
    
    public var end: CGFloat
    
    public var clockwise: Bool
    
    public var angle: CGFloat {
        var start = normalizeAngle(start)
        var end = normalizeAngle(end)
        
        if !clockwise {
            swap(&start, &end)
        }
        
        if start >= end {
            return start - end
        } else {
            return .pi * 2 - (end - start)
        }
    }
    
    public init(center: CGPoint, start: CGFloat, end: CGFloat, clockwise: Bool) {
        self.center = center
        self.start = start
        self.end = end
        self.clockwise = clockwise
    }
    
    // Always clockwise.
    public init(center: CGPoint, startPoint: CGPoint, endPoint: CGPoint) {
        let start = Line(start: center, end: startPoint).angle
        let end = Line(start: center, end: endPoint).angle
        
        self.init(
            center: center,
            start: start,
            end: end,
            clockwise: true
        )
    }
    
    public func toMajorArc() -> Arc {
        guard angle < .pi else {
            return self
        }
        var arc = self
        arc.clockwise.toggle()
        return arc
    }
    
    public func toMinorArc() -> Arc {
        guard angle > .pi else {
            return self
        }
        var arc = self
        arc.clockwise.toggle()
        return arc
    }
    
    private func normalizeAngle(_ angle: CGFloat) -> CGFloat {
        let cirRad = CGFloat.pi * 2
        let angle = angle.truncatingRemainder(dividingBy: cirRad)
        
        return angle >= 0
            ? angle
            : cirRad + angle
    }
    
    public func contains(_ angle: CGFloat) -> Bool {
        let target = normalizeAngle(angle)
        var start = normalizeAngle(start)
        var end = normalizeAngle(end)
        var clockwise = clockwise
        
        if start > end {
            swap(&start, &end)
            clockwise.toggle()
        }
        
        return !clockwise
            ? (start...end).contains(target)
            : target <= start || target >= end
    }
    
    public func contains(_ point: CGPoint, radius: CGFloat) -> Bool {
        let line = Line(start: center, end: point)
        
        return line.length <= radius && contains(line.angle)
    }
    
}
