//
//  Angle.swift
//  
//
//  Created by scchn on 2022/11/5.
//

import Foundation

public struct Angle: Equatable, Hashable, Codable {
    
    public static func ==(_ lhs: Angle, _ rhs: Angle) -> Bool {
        lhs.radians == rhs.radians
    }
    
    public let radians: CGFloat
    
    public let degrees: CGFloat
    
    public init(degrees: CGFloat) {
        self.radians = degrees * .pi / 180
        self.degrees = degrees
    }
    
    public init(radians: CGFloat) {
        self.radians = radians
        self.degrees = radians / .pi * 180
    }
    
}
