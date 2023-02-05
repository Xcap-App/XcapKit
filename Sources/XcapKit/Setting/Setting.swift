//
//  Setting.swift
//  
//
//  Created by scchn on 2022/11/3.
//

import Foundation

@propertyWrapper
public final class Setting<Value>: Observable, SettingConfiguration {
    
    var valueDidUpdate: ((Observation) -> Void)?
    
    public var undoMode: UndoMode
    
    public var redrawMode: RedrawMode
    
    public var wrappedValue: Value {
        didSet {
            let observation = Observation(old: oldValue, new: wrappedValue)
            valueDidUpdate?(observation)
        }
    }
    
    public var projectedValue: SettingConfiguration {
        self
    }
    
    public init(wrappedValue: Value, undoMode: UndoMode = .enable(name: nil), redrawMode: RedrawMode = .enable) {
        self.wrappedValue = wrappedValue
        self.undoMode = undoMode
        self.redrawMode = redrawMode
    }
    
}
