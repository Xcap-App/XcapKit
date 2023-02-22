//
//  Circle.swift
//  
//
//  Created by scchn on 2022/10/10.
//

import Foundation

public struct Circle: Equatable, Hashable, Codable {
    
    public var center: CGPoint
    
    public var radius: CGFloat
    
    public init(center: CGPoint, radius: CGFloat) {
        self.center = center
        self.radius = radius
    }
    
    public init?(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) {
        guard let (center, radius) = makeCircle(p1, p2, p3) else {
            return nil
        }
        
        self.center = center
        self.radius = radius
    }
    
    public func contains(_ point: CGPoint) -> Bool {
        let dx = point.x - center.x
        let dy = point.y - center.y
        return dx * dx + dy * dy <= radius * radius
    }
    
    public func intersectionPoints(_ line: Line) -> [CGPoint] {
        guard line.length > 0 else {
            return []
        }
        
        let dx = line.dx
        let dy = line.dy
        let a = dx * dx + dy * dy
        let b = 2 * (dx * (line.start.x - center.x) + dy * (line.start.y - center.y))
        let c = (
            center.x * center.x +
            center.y * center.y +
            line.start.x * line.start.x +
            line.start.y * line.start.y -
            2 * (center.x * line.start.x + center.y * line.start.y) -
            radius * radius
        )
        let discriminant = b * b - 4 * a * c
        var intersections = [CGPoint]()
        
        guard discriminant >= 0 else {
            return []
        }
        
        if discriminant == 0 {
            let t = -b / (2 * a)
            let x = line.start.x + t * dx
            let y = line.start.y + t * dy
            
            intersections.append(CGPoint(x: x, y: y))
        } else {
            let t1 = (-b + sqrt(discriminant)) / (2 * a)
            let x1 = line.start.x + t1 * dx
            let y1 = line.start.y + t1 * dy
            
            intersections.append(CGPoint(x: x1, y: y1))
            
            let t2 = (-b - sqrt(discriminant)) / (2 * a)
            let x2 = line.start.x + t2 * dx
            let y2 = line.start.y + t2 * dy
            
            intersections.append(CGPoint(x: x2, y: y2))
        }
        
        intersections = intersections.filter { point in
            line.contains(point)
        }
        
        return intersections
    }
    
}

// MARK: - 3-Point Circle

private func calcA(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> CGFloat {
    let a = p1.x * (p2.y - p3.y)
    let b = p1.y * (p2.x - p3.x)
    let c = p2.x * p3.y
    let d = p3.x * p2.y
    
    return a - b + c - d
}

private func calcB(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> CGFloat{
    let a = (p1.x * p1.x + p1.y * p1.y) * (p3.y - p2.y)
    let b = (p2.x * p2.x + p2.y * p2.y) * (p1.y - p3.y)
    let c = (p3.x * p3.x + p3.y * p3.y) * (p2.y - p1.y)
    
    return a + b + c
}

private func calcC(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> CGFloat{
    let a = (p1.x * p1.x + p1.y * p1.y) * (p2.x - p3.x)
    let b = (p2.x * p2.x + p2.y * p2.y) * (p3.x - p1.x)
    let c = (p3.x * p3.x + p3.y * p3.y) * (p1.x - p2.x)
    
    return a + b + c
}

private func calcD(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> CGFloat {
    let a = (p1.x * p1.x + p1.y * p1.y) * (p3.x * p2.y - p2.x * p3.y)
    let b = (p2.x * p2.x + p2.y * p2.y) * (p1.x * p3.y - p3.x * p1.y)
    let c = (p3.x * p3.x + p3.y * p3.y) * (p2.x * p1.y - p1.x * p2.y)
    
    return a + b + c
}

private func makeCircle(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> (center: CGPoint, radius: CGFloat)? {
    let a = calcA(p1, p2, p3)
    let b = calcB(p1, p2, p3)
    let c = calcC(p1, p2, p3)
    let d = calcD(p1, p2, p3)
    
    guard a.isNormal else {
        return nil
    }
    
    let center = CGPoint(x: -b / (2 * a), y: -c / (2 * a))
    let radius = sqrt((b * b + c * c - (4 * a * d)) / (4 * a * a))
    
    return (center, radius)
}
