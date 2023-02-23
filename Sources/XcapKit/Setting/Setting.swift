//
//  Setting.swift
//  
//
//  Created by scchn on 2022/11/3.
//

import Foundation

@propertyWrapper
public final class Setting<Value>: AnySetting {
    
    // MARK: - Private
    
    private var changeHandlers: [(token: String, changeHandelr: (Value) -> Void)] = []
    
    weak var undoManager: UndoManager?
    
    var valueWillChange: (() -> Void)?
    
    var valueDidChange: (() -> Void)?
    
    // MARK: - Public
    
    public var undoMode: UndoMode
    
    public var redrawMode: RedrawMode
    
    public var wrappedValue: Value {
        willSet {
            valueWillChange?()
        }
        didSet {
            registerUndoAction(undoValue: oldValue)
            
            valueDidChange?()
            
            for changeHandler in changeHandlers.map(\.changeHandelr) {
                changeHandler(wrappedValue)
            }
        }
    }
    
    public var projectedValue: Setting {
        self
    }
    
    // MARK: - Life Cycle
    
    deinit {
        changeHandlers.removeAll()
        
        undoManager?.removeAllActions(withTarget: self)
    }
    
    public init(wrappedValue: Value, undoMode: UndoMode = .enable(name: nil), redrawMode: RedrawMode = .enable) {
        self.wrappedValue = wrappedValue
        self.undoMode = undoMode
        self.redrawMode = redrawMode
    }
    
    // MARK: - Undo
    
    private func registerUndoAction(undoValue: Value) {
        guard case let .enable(name) = undoMode, let undoManager = undoManager else {
            return
        }
        
        undoManager.registerUndo(withTarget: self) { state in
            state.wrappedValue = undoValue
        }
        
        if let name = name {
            undoManager.setActionName(name)
        }
    }
    
    // MARK: - Observation
    
    func observe(options: SettingObservation.Options, changeHandler: @escaping (Value) -> Void) -> SettingObservation {
        let token = UUID().uuidString
        let observation = SettingObservation(token: token) { [weak self] token in
            guard let self = self,
                  let index = self.changeHandlers.map(\.token).firstIndex(of: token)
            else {
                return
            }
            
            self.changeHandlers.remove(at: index)
        }
        
        changeHandlers.append((token, changeHandler))
        
        if options.contains(.initial) {
            changeHandler(wrappedValue)
        }
        
        return observation
    }
    
}
