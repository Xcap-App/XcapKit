//
//  Undoable.swift
//  
//
//  Created by scchn on 2022/11/5.
//

import Foundation

public enum UndoMode {
    case disable
    case enable(name: String?)
}

public protocol Undoable: AnyObject {
    var undoMode: UndoMode { get set }
}
