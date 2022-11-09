//
//  BasicBrush.swift
//  
//
//  Created by scchn on 2022/11/3.
//

import CoreGraphics

public class BasicBrush: Brush {
    
    private let drawingHandler: (CGContext) -> Void
    
    public init(drawingHandler: @escaping (CGContext) -> Void) {
        self.drawingHandler = drawingHandler
    }
    
    public override func draw(context: CGContext) {
        context.saveGState()
        drawingHandler(context)
        context.restoreGState()
    }
    
}
