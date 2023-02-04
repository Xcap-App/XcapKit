//
//  PathGraphicsRenderer.swift
//  
//
//  Created by scchn on 2022/11/3.
//

import Foundation
import QuartzCore

extension PathGraphicsRenderer {
    
    public enum LineCap {
        
        case butt
        case round
        case square
        
        var cgLineCap: CGLineCap {
            switch self {
            case .butt:   return .butt
            case .round:  return .round
            case .square: return .square
            }
        }
        
    }
    
    public enum LineJoin {
        
        case round
        case bevel
        case miter(limit: CGFloat)
        
        fileprivate var info: (cgLineJoin: CGLineJoin, miterLimit: CGFloat) {
            switch self {
            case .round:            return (.round, 0)
            case .bevel:            return (.bevel, 0)
            case .miter(let limit): return (.miter, limit)
            }
        }
        
    }
    
    public enum Method {
        case stroke(lineWidth: CGFloat, lineCap: LineCap = .butt, lineJoin: LineJoin = .bevel, dash: [CGFloat] = [], dashPhase: CGFloat = 0)
        case fill
    }
    
    public class Shadow {
        
        public var offset: CGSize
        public var blur: CGFloat
        public var color: PlatformColor
        
        public init(offset: CGSize, blur: CGFloat, color: PlatformColor) {
            self.offset = offset
            self.blur = blur
            self.color = color
        }
        
    }
    
}

public class PathGraphicsRenderer: Drawable {
    
    private let internalPath: CGPath
    
    public var method: Method
    
    public var color: PlatformColor
    
    public var shadow: Shadow?
    
    public var cgPath: CGPath? {
        internalPath
    }
    
    // MARK: - Life Cycle
    
    public init(method: Method, color: PlatformColor, shadow: Shadow? = nil, path: CGPath) {
        self.method = method
        self.color = color
        self.internalPath = path
        self.shadow = shadow
    }
    
    public init(method: Method, color: PlatformColor, shadow: Shadow? = nil, _ make: (CGMutablePath) -> Void) {
        let path = CGMutablePath()
        
        make(path)
        
        self.method = method
        self.color = color
        self.internalPath = path
        self.shadow = shadow
    }
    
    public convenience init(method: Method, color: PlatformColor, shadow: Shadow? = nil, path: PlatformBezierPath) {
        self.init(method: method, color: color, path: path.cgPath)
    }
    
    // MARK: - Utils
    
    public func draw(context: CGContext) {
        // Start
        context.saveGState()
        
        context.addPath(internalPath)
        context.setShadow(offset: shadow?.offset ?? .zero, blur: shadow?.blur ?? 0, color: shadow?.color.cgColor)
        
        switch method {
        case let .stroke(width, cap, join, dash, dashPhase):
            context.setLineWidth(width)
            context.setLineCap(cap.cgLineCap)
            context.setLineJoin(join.info.cgLineJoin)
            context.setMiterLimit(join.info.miterLimit)
            context.setLineDash(phase: dashPhase, lengths: dash)
            context.setStrokeColor(color.cgColor)
            context.strokePath()
            
        case .fill:
            context.setFillColor(color.cgColor)
            context.fillPath()
        }
        
        // End
        context.restoreGState()
    }
    
    public func contains(point: CGPoint, range: CGFloat = 0) -> Bool {
        switch method {
        case let .stroke(lineWidth, cap, join, _, _):
            let width = max(lineWidth, range * 2)
            let path = internalPath.copy(
                strokingWithWidth: width,
                lineCap: cap.cgLineCap,
                lineJoin: join.info.cgLineJoin,
                miterLimit: join.info.miterLimit
            )
            return path.contains(point)
            
        case .fill:
            return internalPath.contains(point, using: .evenOdd)
        }
    }
    
}
