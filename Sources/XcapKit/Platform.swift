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
public typealias PlatformBezierPath = NSBezierPath
public typealias PlatformImage      = NSImage
public typealias PlatformView       = NSView
#else
public typealias PlatformColor      = UIColor
public typealias PlatformBezierPath = UIBezierPath
public typealias PlatformImage      = UIImage
public typealias PlatformView       = UIView
#endif

func fatalErrorNoImplmentation() -> Never {
    fatalError("⚠️ Must be implemented by subclasses.")
}
