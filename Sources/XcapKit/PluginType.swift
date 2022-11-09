//
//  PluginType.swift
//  
//
//  Created by scchn on 2022/11/9.
//

import CoreGraphics

public enum PluginPriority {
    case high
    case low
}

public enum PluginState {
    case idle
    case began(location: CGPoint)
    case dragged(location: CGPoint, initialLocation: CGPoint, lastLocation: CGPoint)
    case ended(location: CGPoint, initialLocation: CGPoint, lastLocation: CGPoint)
}

public protocol PluginType: AnyObject {
    
    var priority: PluginPriority { get }
    
    func shouldBegin(in xcapView: XcapView, location: CGPoint) -> Bool
    
    func update(in xcapView: XcapView, state: PluginState)
    
    func shouldDraw(in xcapView: XcapView, state: PluginState) -> Bool
    
    func draw(in xcapView: XcapView, state: PluginState, context: CGContext)
    
}

extension PluginType {
    public func update(in xcapView: XcapView, state: PluginState) {}
    public func draw(in xcapView: XcapView, state: PluginState, context: CGContext) {}
}
