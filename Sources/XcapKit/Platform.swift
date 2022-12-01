//
//  Platform.swift
//  
//
//  Created by scchn on 2022/11/3.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

#if os(macOS)
public typealias PlatformColor      = NSColor
public typealias PlatformView       = NSView
public typealias PlatformBezierPath = NSBezierPath
#else
public typealias PlatformColor      = UIColor
public typealias PlatformView       = UIView
public typealias PlatformBezierPath = UIBezierPath
#endif

func fatalErrorNoImplmentation() -> Never {
    fatalError("Must be implemented by subclasses.")
}
