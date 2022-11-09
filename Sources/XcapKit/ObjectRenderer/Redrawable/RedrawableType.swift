//
//  RedrawableType.swift
//  
//
//  Created by scchn on 2022/11/5.
//

import Foundation

protocol RedrawableType: AnyObject {
    var undoMode: UndoMode { get }
    var valueDidUpdate: ((Any, Any) -> Void)? { get set }
}
