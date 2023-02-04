//
//  Drawable.swift
//  
//
//  Created by scchn on 2022/11/8.
//

import Foundation
import CoreGraphics

public protocol Drawable {
    
    var cgPath: CGPath? { get }
    
    func draw(context: CGContext)
    
}

extension Drawable {
    
    public var cgPath: CGPath? {
        nil
    }
    
}
