//
//  SettingObservation.swift
//  
//
//  Created by scchn on 2023/2/23.
//

import Foundation

extension SettingObservation {
    
    public struct Options: OptionSet {
        
        public var rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let initial = Options(rawValue: 1 << 0)
        public static let new     = Options(rawValue: 1 << 1)
        
    }
    
}

public class SettingObservation {
    
    private let token: String
    private let invalidationHandler: (String) -> Void
    
    deinit {
        invalidationHandler(token)
    }
    
    init(token: String, invalidationHandler: @escaping (String) -> Void) {
        self.token = token
        self.invalidationHandler = invalidationHandler
    }
    
    public func invalidate() {
        invalidationHandler(token)
    }
    
}
