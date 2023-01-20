//
//  SelectionUtil.swift
//  
//
//  Created by scchn on 2022/11/7.
//

import Foundation

public struct SelectionUtil {
    
    public let rect: CGRect
    
    private var corners: [CGPoint] {
        [CGPoint(x: rect.minX, y: rect.minY),
         CGPoint(x: rect.maxX, y: rect.minY),
         CGPoint(x: rect.minX, y: rect.maxY),
         CGPoint(x: rect.maxX, y: rect.maxY)]
    }
    
    public init(_ rect: CGRect) {
        self.rect = rect
    }
    
    public func selects(_ point: CGPoint) -> Bool {
        rect.contains(point)
    }
    
    public func selects(_ line: Line) -> Bool {
        guard !rect.contains(line.mid) else {
            return true
        }
        let sides = [Line(start: CGPoint(x: rect.minX, y: rect.minY), end: CGPoint(x: rect.minX, y: rect.maxY)),
                     Line(start: CGPoint(x: rect.maxX, y: rect.minY), end: CGPoint(x: rect.maxX, y: rect.maxY)),
                     Line(start: CGPoint(x: rect.minX, y: rect.minY), end: CGPoint(x: rect.maxX, y: rect.minY)),
                     Line(start: CGPoint(x: rect.minX, y: rect.maxY), end: CGPoint(x: rect.maxX, y: rect.maxY))]
        return sides.contains { line.collides(with: $0) }
    }
    
    public func selects(_ anotherRect: CGRect) -> Bool {
        rect.intersects(anotherRect) && !anotherRect.contains(rect)
    }
    
    public func selects(_ circle: Circle) -> Bool {
        guard corners.contains(where: { !circle.contains($0) }) else {
            return false
        }
        let x = circle.center.x < rect.minX
            ? rect.minX
            : (circle.center.x > rect.maxX ? rect.maxX : circle.center.x)
        let y = circle.center.y < rect.minY
            ? rect.minY
            : (circle.center.y > rect.maxY ? rect.maxY : circle.center.y)
        let dx = circle.center.x - x
        let dy = circle.center.y - y
        return dx * dx + dy * dy <= circle.radius * circle.radius
    }
    
    public func selects(_ arc: Arc, radius: CGFloat) -> Bool {
        let ccount = corners
            .filter { point in
                arc.contains(point, radius: radius)
            }
            .count
        
        guard ccount == 0 else {
            return ccount != corners.count
        }
        
        let angles: [CGFloat] = [0, .pi / 2, .pi, -.pi / 2]
        let points = angles.filter(arc.contains(_:))
            .map { arc.center.extended(length: radius, angle: $0) }
        
        guard !points.contains(where: rect.contains(_:)) else {
            return true
        }
        
        let lines = [Line(start: arc.center, end: arc.center.extended(length: radius, angle: arc.start)),
                     Line(start: arc.center, end: arc.center.extended(length: radius, angle: arc.end))]
        
        guard !lines.contains(where: selects(_:)) else {
            return true
        }
        
        let lines2 = points
            .map { point in
                Line(start: arc.center, end: point)
            }
        
        return lines2.contains(where: selects(_:))
    }
    
    public func selects(linesBetween points: [CGPoint], isClosed: Bool) -> Bool {
        points.enumerated()
            .contains { index, point in
                guard isClosed || index != points.count - 1 else {
                    return false
                }
                let j = (index + 1) % points.count
                let line = Line(start: point, end: points[j])
                return selects(line)
            }
    }
    
}
