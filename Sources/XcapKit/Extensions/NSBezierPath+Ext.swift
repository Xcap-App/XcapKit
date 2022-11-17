//
//  NSBezierPath+Ext.swift
//  
//
//  Created by scchn on 2022/11/8.
//

#if os(macOS)

import AppKit

extension NSBezierPath {
    
    var cgPath: CGPath {
        let path = CGMutablePath()
        let points = UnsafeMutablePointer<NSPoint>.allocate(capacity: 3)
        
        if elementCount > 0 {
            var didClosePath = true
            
            for index in 0..<elementCount {
                let pathType = element(at: index, associatedPoints: points)
                
                switch pathType {
                case .moveTo:
                    path.move(to: points[0])
                case .lineTo:
                    path.addLine(to: points[0])
                    didClosePath = false
                case .curveTo:
                    path.addCurve(to: points[2], control1: points[0], control2: points[1])
                    didClosePath = false
                case .closePath:
                    path.closeSubpath()
                    didClosePath = true
                @unknown default:
                    break
                }
            }
            
            if !didClosePath {
                path.closeSubpath()
            }
        }
        
        points.deallocate()
        
        return path
    }
    
    public func addLine(_ line: Line) {
        var points = [line.start, line.end]
        appendPoints(&points, count: 2)
    }
    
    public func addArc(_ arc: Arc) {
        let origin = arc.center.extended(length: arc.radius, angle: arc.start)
        
        move(to: origin)
        appendArc(withCenter: arc.center, radius: arc.radius, startAngle: arc.start, endAngle: arc.end, clockwise: arc.clockwise)
    }
    
    public func addCircle(_ circle: Circle) {
        let origin = circle.center.extended(length: circle.radius, angle: 0)
        
        move(to: origin)
        appendArc(withCenter: circle.center, radius: circle.radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
    }
    
}

#endif
