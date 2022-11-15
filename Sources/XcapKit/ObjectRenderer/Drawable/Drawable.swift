//
//  Drawable.swift
//  
//
//  Created by scchn on 2022/11/8.
//

import Foundation
import CoreGraphics

public protocol Drawable {
    func draw(context: CGContext)
}
