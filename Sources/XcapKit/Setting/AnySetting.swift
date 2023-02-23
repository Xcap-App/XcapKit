//
//  AnySetting.swift
//  
//
//  Created by 陳世爵 on 2023/2/23.
//

import Foundation

public enum RedrawMode {
    case disable
    case enable
}

public enum UndoMode {
    case disable
    case enable(name: String?)
}

protocol AnySetting: AnyObject {
    
    var undoManager: UndoManager? { get set }
    var redrawMode: RedrawMode { get set }
    var undoMode: UndoMode { get set }
    
    var valueWillChange: (() -> Void)? { get set }
    var valueDidChange: (() -> Void)? { get set }
}
