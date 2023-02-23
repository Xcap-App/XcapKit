//
//  SettingsMonitor.swift
//  
//
//  Created by scchn on 2022/11/4.
//

import Foundation

public protocol SettingsMonitor: AnyObject {
    var undoManager: UndoManager? { get }
}

extension SettingsMonitor {
    
    public func registerSettings(_ settingDidChange: @escaping () -> Void) {
        let properties = Mirror(reflecting: self).properties(ofType: AnySetting.self)
        
        for (_, value) in properties {
            value.valueWillChange = { [weak self, weak value] in
                guard let self = self, let value = value else {
                    return
                }
                
                value.undoManager = self.undoManager
            }
            
            value.valueDidChange = { [weak value] in
                guard let value = value, value.redrawMode == .enable else {
                    return
                }
                
                settingDidChange()
            }
        }
    }
    
    public func observeSetting<T>(_ keyPath: KeyPath<Self, Setting<T>>, options: SettingObservation.Options = [.initial, .new], changeHandler: @escaping (T) -> Void) -> SettingObservation {
        self[keyPath: keyPath].observe(options: options, changeHandler: changeHandler)
    }
    
}
