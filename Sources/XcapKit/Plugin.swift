//
//  Plugin.swift
//  
//
//  Created by scchn on 2022/11/28.
//

import Foundation
import CoreGraphics

extension Plugin {
    
    // ----- Public -----
    
    public enum PluginType {
        case overlay
        case underlay
        case interactiveOverlay
        case interactiveUnderlay
    }
    
    public enum State {
        case idle
        case began(location: CGPoint)
        case changed(location: CGPoint, lastLocation: CGPoint, initialLocation: CGPoint)
        case ended(location: CGPoint, lastLocation: CGPoint, initialLocation: CGPoint)
    }
    
}

open class Plugin: NSObject, SettingMonitor {
    
    public internal(set) weak var undoManager: UndoManager?
    
    var redrawHandler: (() -> Void)?
    
    // MARK: - Data
    
    open var pluginType: PluginType {
        .overlay
    }
    
    // MARK: - Settings
    
    @Setting open var isEnabled: Bool = true
    
    // MARK: - Life Cycle
    
    deinit {
        undoManager?.removeAllActions(withTarget: self)
    }
    
    public required override init() {
        super.init()
        
        registerSettings { [weak self] in
            self?.redrawHandler?()
        }
    }
    
    open func pluginWasInstalled(in xcapView: XcapView) {
        
    }
    
    // MARK: - Interactive plugin events
    
    open func shouldBegin(in xcapView: XcapView, location: CGPoint) -> Bool {
        false
    }
    
    open func update(in xcapView: XcapView, state: State) {
        
    }
    
    // MARK: - Drawing
    
    open func shouldDraw(in xcapView: XcapView, state: State) -> Bool {
        true
    }
    
    open func draw(in xcapView: XcapView, state: State, contentRect: CGRect, contentScaleFactor: CGPoint) {
        
    }
    
}
