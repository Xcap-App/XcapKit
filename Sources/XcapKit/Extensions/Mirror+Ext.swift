//
//  Mirror+Ext.swift
//  
//
//  Created by scchn on 2022/11/4.
//

import Foundation

extension Mirror {
    
    func properties<T>(ofType type: T.Type) -> [String: T] {
        var result: [String: T] = [:]
        
        for child in children {
            guard let key = child.label, let value = child.value as? T else {
                continue
            }
            result[key] = value
        }
        
        if let parent = superclassMirror {
            for (key, value) in parent.properties(ofType: T.self) {
                result[key] = value
            }
        }
        
        return result
    }
}
