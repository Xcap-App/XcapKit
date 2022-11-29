//
//  SettingType.swift
//  
//
//  Created by scchn on 2022/11/29.
//

import Foundation

public protocol SettingType: AnyObject {
    var undoMode: UndoMode { get set }
    var redrawMode: RedrawMode { get set }
}
