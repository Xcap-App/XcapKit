//
//  SettingObservable.swift
//  
//
//  Created by scchn on 2022/11/29.
//

import Foundation

protocol SettingObservable: SettingType {
    
    var valueDidUpdate: ((Any, Any) -> Void)? { get set }
    
}
