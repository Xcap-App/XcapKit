//
//  Editable.swift
//  
//
//  Created by scchn on 2022/11/8.
//

import Foundation

public protocol Editable: ObjectRenderer {
    func canEditItem(at position: ObjectLayout.Position) -> Bool
}

extension Editable {
    
    public func canEditItem(at position: ObjectLayout.Position) -> Bool {
        true
    }
    
}
