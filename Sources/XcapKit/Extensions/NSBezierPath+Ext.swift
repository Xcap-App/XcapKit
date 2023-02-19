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
        var points = [CGPoint](repeating: .zero, count: 3)
        
        for i in 0..<elementCount {
            let type = element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath:
                path.closeSubpath()
            @unknown default:
                print("Unknown NSBezierPath element type")
            }
        }
        
        return path
    }
    
    public func addLine(_ line: Line) {
        var points = [line.start, line.end]
        appendPoints(&points, count: 2)
    }
    
    public func addArc(_ arc: Arc, radius: CGFloat) {
        let origin = arc.center.extended(length: radius, angle: arc.start)
        
        move(to: origin)
        appendArc(withCenter: arc.center, radius: radius, startAngle: arc.start, endAngle: arc.end, clockwise: arc.clockwise)
    }
    
    public func addCircle(_ circle: Circle) {
        let origin = circle.center.extended(length: circle.radius, angle: 0)
        
        move(to: origin)
        appendArc(withCenter: circle.center, radius: circle.radius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
    }
    
}

#endif
