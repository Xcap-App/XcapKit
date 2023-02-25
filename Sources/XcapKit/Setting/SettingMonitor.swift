//
//  SettingMonitor.swift
//  
//
//  Created by scchn on 2022/11/4.
//

import Foundation

public protocol SettingMonitor: AnyObject {
    var undoManager: UndoManager? { get }
}

extension SettingMonitor {
    
    public func registerSettings(_ settingChangeHandler: (() -> Void)? = nil) {
        let properties = Mirror(reflecting: self).properties(ofType: (any AnySetting).self)
        
        for (_, setting) in properties {
            let variable = setting.variable
            
            variable.valueChangeHandler = {
                settingChangeHandler?()
            }
            
            variable.undoManagerHandler = { [weak self] in
                self?.undoManager
            }
        }
    }
    
    public func observeSetting<T>(
        _ keyPath: KeyPath<Self, Variable<T>>,
        options: SettingObservation.Options = [.initial, .new],
        changeHandler: @escaping (T) -> Void
    ) -> SettingObservation {
        self[keyPath: keyPath].observe(options: options, changeHandler: changeHandler)
    }
    
}
