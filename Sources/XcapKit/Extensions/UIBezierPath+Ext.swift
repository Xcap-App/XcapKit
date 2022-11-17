//
//  File.swift
//  
//
//  Created by scchn on 2022/11/17.
//

#if !os(macOS)

import UIKit

extension UIBezierPath {
    
    public func addLine(_ line: Line) {
        move(to: line.start)
        addLine(to: line.end)
    }
    
    public func addArc(_ arc: Arc) {
        let origin = arc.center.extended(length: arc.radius, angle: arc.start)
        
        move(to: origin)
        addArc(withCenter: arc.center, radius: arc.radius, startAngle: arc.start, endAngle: arc.end, clockwise: arc.clockwise)
    }
    
    public func addCircle(_ circle: Circle) {
        let origin = circle.center.extended(length: circle.radius, angle: 0)
        
        move(to: origin)
        addArc(withCenter: circle.center, radius: circle.radius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
    }
    
}

#endif
