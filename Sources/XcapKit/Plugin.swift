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
    
    public enum Priority {
        case overlay
        case underlay
        case high
        case low
    }
    
    public enum State {
        case idle
        case began(location: CGPoint)
        case changed(location: CGPoint, lastLocation: CGPoint, initialLocation: CGPoint)
        case ended(location: CGPoint, lastLocation: CGPoint, initialLocation: CGPoint)
    }
    
}

open class Plugin: NSObject, SettingsMonitor {
    
    public internal(set) weak var undoManager: UndoManager?
    
    var redrawHandler: (() -> Void)?
    
    // MARK: - Data
    
    open var priority: Priority {
        .overlay
    }
    
    // MARK: - Settings
    
    @Setting open var isEnabled: Bool = true
    
    // MARK: - Life Cycle
    
    public required override init() {
        super.init()
        
        registerSettings { [weak self] in
            self?.redrawHandler?()
        }
    }
    
    // MARK: - Observer
    
    open func pluginDidInstall(in xcapView: XcapView) {
        
    }
    
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
