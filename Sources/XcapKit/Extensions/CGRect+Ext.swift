//
//  CGRect+Ext.swift
//  
//
//  Created by scchn on 2023/2/6.
//

import Foundation

extension CGRect {
    
    private var corners: [CGPoint] {
        [
            CGPoint(x: minX, y: minY),
            CGPoint(x: maxX, y: minY),
            CGPoint(x: minX, y: maxY),
            CGPoint(x: maxX, y: maxY)
        ]
    }
    
    private var sides: [Line]  {
        [
            Line(start: CGPoint(x: minX, y: minY), end: CGPoint(x: minX, y: maxY)),
            Line(start: CGPoint(x: maxX, y: minY), end: CGPoint(x: maxX, y: maxY)),
            Line(start: CGPoint(x: minX, y: minY), end: CGPoint(x: maxX, y: minY)),
            Line(start: CGPoint(x: minX, y: maxY), end: CGPoint(x: maxX, y: maxY))
        ]
    }
    
    func pretty() -> CGRect {
        var rect = self
        
        rect.origin.x = rect.origin.x.rounded(.down) + 0.5
        rect.origin.y = rect.origin.y.rounded(.down) + 0.5
        rect.size.width = rect.size.width.rounded()
        rect.size.height = rect.size.height.rounded()
        
        return rect
    }
    
    // MARK: - Selection Tests
    
    public func selects(line: Line) -> Bool {
        guard !contains(line.mid) else {
            return true
        }
        
        return sides.contains { line.collides(with: $0) }
    }
    
    public func selects(linesBetween points: [CGPoint], closed: Bool) -> Bool {
        points.enumerated()
            .contains { index, point in
                guard closed || index != points.count - 1 else {
                    return false
                }
                let j = (index + 1) % points.count
                let line = Line(start: point, end: points[j])
                return selects(line: line)
            }
    }
    
    public func selects(rect anotherRect: CGRect) -> Bool {
        intersects(anotherRect) &&
        !anotherRect.contains(self)
    }
    
    public func selects(circle: Circle) -> Bool {
        guard corners.contains(where: { !circle.contains($0) }) else {
            return false
        }
        
        let x = (
            circle.center.x < minX
            ? minX
            : (circle.center.x > maxX ? maxX : circle.center.x)
        )
        let y = (
            circle.center.y < minY
            ? minY
            : (circle.center.y > maxY ? maxY : circle.center.y)
        )
        let dx = circle.center.x - x
        let dy = circle.center.y - y
        
        return dx * dx + dy * dy <= circle.radius * circle.radius
    }
    
    public func selects(arc: Arc, radius: CGFloat, closed: Bool) -> Bool {
        // 1
        if sides.contains(where: { side in
            !arc.intersectionPoints(side, radius: radius).isEmpty
        }) {
            return true
        }
        
        let startPoint = arc.center.extended(length: radius, angle: arc.start)
        let endPoint = arc.center.extended(length: radius, angle: arc.end)
        
        // 3
        guard closed else {
            return contains(startPoint) || contains(endPoint)
        }
        
        // 4
        let radiusLines = [
            Line(start: arc.center, end: startPoint),
            Line(start: arc.center, end: endPoint)
        ]
        
        return radiusLines.contains { line in
            selects(line: line)
        }
    }
    
}
