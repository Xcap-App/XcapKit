//
//  CGMutablePath.swift
//  
//
//  Created by scchn on 2022/11/17.
//

import Foundation
import CoreGraphics

extension CGMutablePath {
    
    public func addLine(_ line: Line) {
        addLines(between: [line.start, line.end])
    }
    
    public func addArc(_ arc: Arc) {
        let origin = arc.center.extended(length: arc.radius, angle: arc.start)
        
        move(to: origin)
        addArc(center: arc.center, radius: arc.radius, startAngle: arc.start, endAngle: arc.end, clockwise: arc.clockwise)
    }
    
    public func addCircle(_ circle: Circle) {
        let origin = circle.center.extended(length: circle.radius, angle: 0)
        
        move(to: origin)
        addArc(center: circle.center, radius: circle.radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
    }
    
}
