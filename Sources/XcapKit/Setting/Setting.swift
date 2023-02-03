//
//  Setting.swift
//  
//
//  Created by scchn on 2022/11/3.
//

import Foundation

@propertyWrapper
public final class Setting<Value>: SettingValueObservable {
    
    var valueDidUpdate: ((SettingsValueObservation) -> Void)?
    
    public var undoMode: UndoMode
    
    public var redrawMode: RedrawMode
    
    public var wrappedValue: Value {
        didSet {
            let observation = SettingsValueObservation(old: oldValue, new: wrappedValue)
            valueDidUpdate?(observation)
        }
    }
    
    public var projectedValue: SettingType {
        self
    }
    
    public init(wrappedValue: Value, undoMode: UndoMode = .enable(name: nil), redrawMode: RedrawMode = .enable) {
        self.wrappedValue = wrappedValue
        self.undoMode = undoMode
        self.redrawMode = redrawMode
    }
    
}
