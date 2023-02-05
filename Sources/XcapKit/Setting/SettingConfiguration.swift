//
//  SettingConfiguration.swift
//  
//
//  Created by scchn on 2022/11/29.
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

public protocol SettingConfiguration: AnyObject {
    var redrawMode: RedrawMode { get set }
    var undoMode: UndoMode { get set }
}
