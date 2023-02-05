//
//  CGRect+Ext.swift
//  
//
//  Created by scchn on 2023/2/6.
//

import Foundation

extension CGRect {
    
    func pretty() -> CGRect {
        var rect = self
        
        rect.origin.x = rect.origin.x.rounded(.down) + 0.5
        rect.origin.y = rect.origin.y.rounded(.down) + 0.5
        rect.size.width = rect.size.width.rounded()
        rect.size.height = rect.size.height.rounded()
        
        return rect
    }
    
}
