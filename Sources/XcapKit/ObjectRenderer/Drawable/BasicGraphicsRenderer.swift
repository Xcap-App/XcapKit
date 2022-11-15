//
//  BasicGraphicsRenderer.swift
//  
//
//  Created by scchn on 2022/11/3.
//

import CoreGraphics
import UIKit

public class BasicGraphicsRenderer: Drawable {
    
    private let drawingHandler: (CGContext) -> Void
    
    public init(drawingHandler: @escaping (CGContext) -> Void) {
        self.drawingHandler = drawingHandler
    }
    
    public func draw(context: CGContext) {
        context.saveGState()
        drawingHandler(context)
        context.restoreGState()
    }
    
}
