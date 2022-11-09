//
//  ObjectRendererBrush.swift
//  
//
//  Created by scchn on 2022/11/8.
//

import Foundation
import CoreGraphics

public class ObjectRendererBrush: Brush {
    
    public let renderer: ObjectRenderer
    
    public init(renderer: ObjectRenderer) {
        self.renderer = renderer
    }
    
    public override func draw(context: CGContext) {
        renderer.draw(context: context)
    }
    
}
