//
//  SettingsInspector.swift
//  
//
//  Created by scchn on 2022/11/4.
//

import Foundation

protocol SettingsInspector: NSObject {
    var undoManager: UndoManager? { get }
}

private var kUndoManagerAssociation: UInt8 = 0

extension SettingsInspector {
    
    func registerSettings(redrawHandler: @escaping () -> Void) {
        let properties = Mirror(reflecting: self).properties(ofType: SettingValueObservable.self)
        
        for (key, value) in properties {
            value.valueDidUpdate = { [weak self, weak value] (new: Any, old: Any) in
                guard let self = self, let value = value else {
                    return
                }
                
                if value.redrawMode == .enable {
                    redrawHandler()
                }
                
                if case .enable(let name) = value.undoMode {
                    let keyPath = String(key.dropFirst())
                    self.registerUndoAction(named: name, keyPath: keyPath, value: old)
                }
            }
        }
    }
    
    private func registerUndoAction(named name: String?, keyPath: String, value: Any) {
        guard let undoManager = undoManager, undoManager.isUndoRegistrationEnabled else {
            return
        }
        
        undoManager.registerUndo(withTarget: self) { target in
            // Redo
            if let currentValue = target.value(forKey: keyPath) {
                target.registerUndoAction(named: name, keyPath: keyPath, value: currentValue)
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
