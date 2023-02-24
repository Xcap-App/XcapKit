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
        let properties = Mirror(reflecting: self).properties(ofType: AnySetting.self)
        
        for (_, setting) in properties {
            var setting = setting
            
            setting.valueChangeHandler = settingChangeHandler
            
            setting.undoManagerHandler = { [weak self] in
                self?.undoManager
            }
        }
    }
    
    public func observeSetting<V, T>(_ keyPath: KeyPath<Self, V>, options: SettingObservation.Options = [.initial, .new], changeHandler: @escaping (T) -> Void) -> SettingObservation where V: Variable<T> {
        self[keyPath: keyPath].observe(options: options, changeHandler: changeHandler)
    }
    
}
