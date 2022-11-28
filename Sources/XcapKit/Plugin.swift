//
//  Plugin.swift
//  
//
//  Created by 陳世爵 on 2022/11/28.
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
open class Plugin: NSObject, RedrawAndUndoController {
    
    var undoManager: UndoManager?
    
    var redrawHandler: (() -> Void)?
    
    // MARK: - Data
    
    open var priority: Priority {
        fatalError("Must be implemented by subclasses.")
    }
    
    // MARK: - Settings
    
    @Redrawable
    open var isEnabled: Bool = false
    
    // MARK: - Life Cycle
    
    public required override init() {
        super.init()
        
        setupRedrawHandler { [weak self] in
            self?.redrawHandler?()
        }
    }
    
    // MARK: - Condition
    
    open func shouldBegin(in xcapView: XcapView, location: CGPoint) -> Bool {
        fatalError("Must be implemented by subclasses.")
    }
    
    open func update(in xcapView: XcapView, state: State) {
        
    }
    
    // MARK: - Drawing
    
    open func shouldDraw(in xcapView: XcapView, state: State) -> Bool {
        fatalError("Must be implemented by subclasses.")
    }
    
    open func draw(in xcapView: XcapView, state: State, context: CGContext) {
        
    }
    
}
