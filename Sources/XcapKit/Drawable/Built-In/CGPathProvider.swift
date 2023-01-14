//
//  CGPathProvider.swift
//  
//
//  Created by 陳世爵 on 2022/12/1.
//

import Foundation
#if os(macOS)
import Quartz
#else
import QuartzCore
#endif

public protocol CGPathProvider: Drawable {
    var cgPath: CGPath { get }
}
