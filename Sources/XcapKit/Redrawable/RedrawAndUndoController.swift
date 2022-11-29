//
//  RedrawAndUndoController.swift
//  
//
//  Created by scchn on 2022/11/4.
//

import Foundation

private var kUndoManagerAssociation: UInt8 = 0

protocol RedrawAndUndoController: NSObject {
    
}

extension RedrawAndUndoController {
    
    var undoManager: UndoManager? {
        get { objc_getAssociatedObject(self, &kUndoManagerAssociation) as? UndoManager }
        set { objc_setAssociatedObject(self, &kUndoManagerAssociation, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    func setupRedrawHandler(_ redrawHandler: @escaping () -> Void) {
        let properties = Mirror(reflecting: self).properties(ofType: RedrawableType.self)
        
        for (key, value) in properties {
            value.valueDidUpdate = { [weak self, weak value] (new: Any, old: Any) in
                guard let self = self, let value = value else {
                    return
                }
                
                redrawHandler()
                
                if case .enable(let name) = value.undoMode {
                    let keyPath = String(key.dropFirst())
                    self.registerUndo(named: name, keyPath: keyPath, value: old)
                }
            }
        }
    }
    
    private func registerUndo(named name: String?, keyPath: String, value: Any) {
        guard let undoManager = undoManager, undoManager.isUndoRegistrationEnabled else {
            return
        }
        
        undoManager.registerUndo(withTarget: self) { target in
            // Redo
            if let currentValue = target.value(forKey: keyPath) {
                target.registerUndo(named: name, keyPath: keyPath, value: currentValue)
            }
            
            // Undo
            target.undoManager?.disableUndoRegistration()
            target.setValue(value, forKey: keyPath)
            target.undoManager?.enableUndoRegistration()
        }
        
        if let name = name {
            undoManager.setActionName(name)
        }
    }
    
}
