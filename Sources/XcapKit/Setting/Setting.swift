//
//  Setting.swift
//  
//
//  Created by scchn on 2023/2/24.
//

import Foundation

protocol AnySetting {
    var valueChangeHandler: (() -> Void)? { get set }
    var undoManagerHandler: (() -> UndoManager?)? { get set }
}

@propertyWrapper
public class Setting<Value>: AnySetting {
    
    private let variable: Variable<Value>
    
    var undoManagerHandler: (() -> UndoManager?)?
    
    var valueChangeHandler: (() -> Void)?
    
    public var wrappedValue: Value {
        get { variable.value }
        set { variable.value = newValue }
    }
    
    public var projectedValue: Variable<Value> {
        variable
    }
    
    public init(wrappedValue: Value, undoMode: UndoMode = .enable(name: nil)) {
        self.variable = .init(value: wrappedValue, undoMode: undoMode)
        
        self.variable.valueChangeHandler = { [weak self] in
            self?.valueChangeHandler?()
        }
        
        self.variable.undoManagerHandler = { [weak self] in
            self?.undoManagerHandler?()
        }
    }
    
}
