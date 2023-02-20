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
    
    func pretty() -> CGRect {
        var rect = self
        
        rect.origin.x = rect.origin.x.rounded(.down) + 0.5
        rect.origin.y = rect.origin.y.rounded(.down) + 0.5
        rect.size.width = rect.size.width.rounded()
        rect.size.height = rect.size.height.rounded()
        
        return rect
    }
    
    // MARK: - Selection Tests
    
    public func selects(_ line: Line) -> Bool {
        guard !contains(line.mid) else {
            return true
        }
        
        let sides = [
            Line(start: CGPoint(x: minX, y: minY), end: CGPoint(x: minX, y: maxY)),
            Line(start: CGPoint(x: maxX, y: minY), end: CGPoint(x: maxX, y: maxY)),
            Line(start: CGPoint(x: minX, y: minY), end: CGPoint(x: maxX, y: minY)),
            Line(start: CGPoint(x: minX, y: maxY), end: CGPoint(x: maxX, y: maxY))
        ]
        
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
                return selects(line)
            }
    }
    
    public func selects(_ anotherRect: CGRect) -> Bool {
        intersects(anotherRect) &&
        !anotherRect.contains(self)
    }
    
    public func selects(_ circle: Circle) -> Bool {
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
    
    public func selects(_ arc: Arc, radius: CGFloat) -> Bool {
        // 1
        
        let numberOfCornersInPie = corners
            .filter { point in
                arc.contains(point, radius: radius)
            }
            .count
        
        guard numberOfCornersInPie == 0 else {
            return numberOfCornersInPie != corners.count
        }
        
        // 2
        
        let vertexAngles: [CGFloat] = [0, .pi / 2, .pi, -.pi / 2]
        let vertices = vertexAngles.compactMap { angle -> CGPoint? in
            guard arc.contains(angle) else {
                return nil
            }
            return arc.center.extended(length: radius, angle: angle)
        }
        let isAnyVertexSelected = vertices.contains { vertex in
            contains(vertex)
        }
        
        guard !isAnyVertexSelected else {
            return true
        }
        
        //3
        
        let radiusLines = [
            Line(start: arc.center, end: arc.center.extended(length: radius, angle: arc.start)),
            Line(start: arc.center, end: arc.center.extended(length: radius, angle: arc.end))
        ]
        let isAnyRadiusSelected = radiusLines.contains { line in
            selects(line)
        }
        
        guard !isAnyRadiusSelected else {
            return true
        }
        
        // 4
        
        let vertexRadiusLines = vertices
            .map { point in
                Line(start: arc.center, end: point)
            }
        
        return vertexRadiusLines.contains { line in
            selects(line)
        }
    }
    
}
