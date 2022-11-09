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
}

#endif
