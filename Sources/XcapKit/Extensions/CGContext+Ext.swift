//
//  CGContext+Ext.swift
//  
//
//  Created by scchn on 2022/11/3.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension CGContext {
    
    static var current: CGContext? {
        #if os(macOS)
        return NSGraphicsContext.current?.cgContext
        #else
        return UIGraphicsGetCurrentContext()
        #endif
    }
    
    public func addLine(_ line: Line) {
        addLines(between: [line.start, line.end])
    }
    
    public func addArc(_ arc: Arc, radius: CGFloat) {
        let origin = arc.center.extended(length: radius, angle: arc.start)
        
        move(to: origin)
        addArc(center: arc.center, radius: radius, startAngle: arc.start, endAngle: arc.end, clockwise: arc.clockwise)
    }
    
    public func addCircle(_ circle: Circle) {
        let origin = circle.center.extended(length: circle.radius, angle: 0)
        
        move(to: origin)
        addArc(center: circle.center, radius: circle.radius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
    }
    
}
