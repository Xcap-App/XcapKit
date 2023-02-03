//
//  SettingValueObservable.swift
//  
//
//  Created by scchn on 2022/11/29.
//

import Foundation

struct SettingsValueObservation {
    var old: Any
    var new: Any
}

protocol SettingValueObservable: SettingType {
    
    var valueDidUpdate: ((SettingsValueObservation) -> Void)? { get set }
    
}
