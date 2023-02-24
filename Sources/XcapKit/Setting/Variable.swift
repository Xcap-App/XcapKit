//
//  Variable.swift
//  
//
//  Created by scchn on 2023/2/24.
//

import Foundation
import SwiftUI

public class Variable<Value> {
    
    private var changeHandlers: [(token: String, changeHandelr: (Value) -> Void)] = []
    
    private var undoManager: UndoManager? {
        undoManagerHandler?()
    }
    
    var valueChangeHandler: (() -> Void)?
    
    var undoManagerHandler: (() -> UndoManager?)?
    
    var value: Value {
        didSet {
            registerUndoAction(undoValue: oldValue)
            
            valueChangeHandler?()
            
            for changeHandler in changeHandlers.map(\.changeHandelr) {
                changeHandler(value)
            }
        }
    }
    
    // MARK: - Public
    
    public var undoMode: UndoMode
    
    // MARK: - Life Cycle
    
    deinit {
        changeHandlers.removeAll()
        
        undoManager?.removeAllActions(withTarget: self)
    }
    
    init(value: Value, undoMode: UndoMode = .enable(name: nil)) {
        self.value = value
        self.undoMode = undoMode
    }
    
    // MARK: - Undo
    
    private func registerUndoAction(undoValue: Value) {
        guard case let .enable(name) = undoMode, let undoManager = undoManager else {
            return
        }
        
        undoManager.registerUndo(withTarget: self) { state in
            state.value = undoValue
        }
        
        if let name = name {
            undoManager.setActionName(name)
        }
    }
    
    // MARK: - Observation
    
    func observe(options: SettingObservation.Options, changeHandler: @escaping (Value) -> Void) -> SettingObservation {
        let observation = SettingObservation { [weak self] token in
            guard let self = self,
                  let index = self.changeHandlers.map(\.token).firstIndex(of: token)
            else {
                return
            }
            
            self.changeHandlers.remove(at: index)
        }
        
        changeHandlers.append((observation.token, changeHandler))
        
        if options.contains(.initial) {
            changeHandler(value)
        }
        
        return observation
    }
    
}
