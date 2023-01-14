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
    }
    
    public enum State {
        case idle
        case began(location: CGPoint)
        case moved(location: CGPoint, initialLocation: CGPoint, lastLocation: CGPoint)
        case ended(location: CGPoint, initialLocation: CGPoint, lastLocation: CGPoint)
    }
    
}

@objcMembers
open class Plugin: NSObject, SettingsInspector {
    
    var undoManager: UndoManager?
    
    var redrawHandler: (() -> Void)?
    
    // MARK: - Data
    
    open var priority: Priority {
        fatalErrorNoImplmentation()
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
        fatalErrorNoImplmentation()
    }
    
    open func shouldDraw(in xcapView: XcapView, state: State) -> Bool {
        fatalErrorNoImplmentation()
    }
    
    // MARK: - Observer
    
    open func pluginDidAdd(to xcapView: XcapView) {
        
    }
    
    open func remove(from xcapView: XcapView) {
        
    }
    
    open func update(in xcapView: XcapView, state: State) {
        
    }
    
    // MARK: - Drawing
    
    open func draw(in xcapView: XcapView, state: State, context: CGContext) {
        
    }
    
}
