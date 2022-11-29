//
//  Redrawable.swift
//  
//
//  Created by scchn on 2022/11/3.
//

import Foundation

public enum UndoMode {
    case disable
    case enable(name: String?)
}

public protocol Undoable: AnyObject {
    var undoMode: UndoMode { get set }
}

/// `Value` must be Objective-C compatible.
@propertyWrapper
public class Redrawable<Value>: RedrawableType, Undoable {
    
    var valueDidUpdate: ((Any, Any) -> Void)?
    
    public var undoMode: UndoMode
    
    public var wrappedValue: Value {
        didSet {
            valueDidUpdate?(wrappedValue, oldValue)
        }
    }
    
    public var projectedValue: Undoable {
        self
    }
    
    public init(wrappedValue: Value, undoMode: UndoMode = .enable(name: nil)) {
        self.wrappedValue = wrappedValue
        self.undoMode = undoMode
    }
    
}
