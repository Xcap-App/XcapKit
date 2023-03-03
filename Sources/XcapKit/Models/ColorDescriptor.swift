//
//  ColorDescriptor.swift
//  
//
//  Created by scchn on 2023/3/4.
//

import Foundation
import CoreImage

struct ColorDescriptor: Codable {
    
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    var alpha: CGFloat
    
#if os(macOS)
    init?(color: PlatformColor) {
        guard let ciColor = CIColor(color: color) else {
            return nil
        }
        
        red = ciColor.red
        green = ciColor.green
        blue = ciColor.blue
        alpha = ciColor.alpha
    }
#else
    init(color: PlatformColor) {
        let ciColor = CIColor(color: color)
        
        red = ciColor.red
        green = ciColor.green
        blue = ciColor.blue
        alpha = ciColor.alpha
    }
#endif
    
    var platformColor: PlatformColor {
        .init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
}
