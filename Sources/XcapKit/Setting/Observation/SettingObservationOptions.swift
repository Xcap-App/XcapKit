//
//  SettingObservationOptions.swift
//  
//
//  Created by 陳世爵 on 2023/2/23.
//

import Foundation

public struct SettingObservationOptions: OptionSet {
    
    public var rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let initial = SettingObservationOptions(rawValue: 1 << 0)
    public static let new     = SettingObservationOptions(rawValue: 1 << 1)
    
}
