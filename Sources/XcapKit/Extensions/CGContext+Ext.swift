//
//  CGContext+Ext.swift
//  
//
//  Created by scchn on 2022/11/3.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension CGContext {
    
    static var current: CGContext? {
        #if os(macOS)
        return NSGraphicsContext.current?.cgContext
        #else
        return UIGraphicsGetCurrentContext()
        #endif
    }
    
}
