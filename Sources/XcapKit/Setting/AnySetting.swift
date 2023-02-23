//
//  AnySetting.swift
//  
//
//  Created by scchn on 2023/2/23.
//

import Foundation

protocol AnySetting: AnyObject {
    
    var undoManager: UndoManager? { get set }
    var redrawMode: RedrawMode { get set }
    var undoMode: UndoMode { get set }
    
    var valueWillChange: (() -> Void)? { get set }
    var valueDidChange: (() -> Void)? { get set }
}
