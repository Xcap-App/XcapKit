//
//  SettingObservation.swift
//  
//
//  Created by 陳世爵 on 2023/2/23.
//

import Foundation

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
