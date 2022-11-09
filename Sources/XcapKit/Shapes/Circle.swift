//
//  Circle.swift
//  
//
//  Created by scchn on 2022/10/10.
//

import Foundation

public struct Circle: Equatable, Hashable, Codable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(center.x)
        hasher.combine(center.y)
        hasher.combine(radius)
    }
    
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
