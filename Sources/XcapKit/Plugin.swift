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
        case high
        case low
        case overlay
    }
    
    public enum State {
        case idle
        case began(location: CGPoint)
        case moved(location: CGPoint, lastLocation: CGPoint, initialLocation: CGPoint)
        case ended(location: CGPoint, lastLocation: CGPoint, initialLocation: CGPoint)
    }
    
}

@objcMembers
open class Plugin: NSObject, SettingsInspector {
    
    var undoManager: UndoManager?
    
    var redrawHandler: (() -> Void)?
    
    // MARK: - Data
    
    open var priority: Priority {
        .high
    }
    
    // MARK: - Settings
    
    @Setting
    open var isEnabled: Bool = false
    
    // MARK: - Life Cycle
    
    public required override init() {
        super.init()
        
        registerSettings { [weak self] in
            self?.redrawHandler?()
        }
    }
    
    // MARK: - Condition
    
    open func shouldBegin(in xcapView: XcapView, location: CGPoint) -> Bool {
        false
    }
    
    open func shouldDraw(in xcapView: XcapView, state: State) -> Bool {
        true
    }
    
    // MARK: - Observer
    
    open func pluginDidAdd(to xcapView: XcapView) {
        
    }
    
    open func remove(from xcapView: XcapView) {
        
    }
    
    open func update(in xcapView: XcapView, state: State) {
        
    }
    
    // MARK: - Drawing
    
    open func draw(in xcapView: XcapView, state: State, contentRect: CGRect, contentScaleFactor: CGPoint) {
        
    }
    
}
