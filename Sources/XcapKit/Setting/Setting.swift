//
//  Setting.swift
//  
//
//  Created by scchn on 2023/2/24.
//

import Foundation

protocol AnySetting: AnyObject {
    associatedtype Variable: AnyVariable
    
    var variable: Variable { get }
}

@propertyWrapper
public class Setting<Value>: AnySetting {
    
    let variable: Variable<Value>
    
    // MARK: - Public
    
    public var wrappedValue: Value {
        get { variable.value }
        set { variable.value = newValue }
    }
    
    public var projectedValue: Variable<Value> {
        variable
    }
    
    // MARK: - Life Cycle
    
    public init(wrappedValue: Value, undoMode: UndoMode = .enable(name: nil)) {
        self.variable = .init(value: wrappedValue, undoMode: undoMode)
    }
    
}
