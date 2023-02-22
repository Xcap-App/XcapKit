//
//  ObjectLayout.swift
//  
//
//  Created by scchn on 2022/11/3.
//

import Foundation

extension ObjectLayout {
    
    public struct Position: Equatable, Hashable, Codable {
        
        public var item: Int
        
        public var section: Int
        
        public static let zero  = Position(item: 0, section: 0)
        
        public init(item: Int, section: Int) {
            self.item = item
            self.section = section
        }
        
    }
    
}

public struct ObjectLayout: Equatable, Hashable, Codable {
    
    private(set) var data: [[CGPoint]]
    
    // MARK: - Life Cycle
    
    public init(_ data: [[CGPoint]] = []) {
        self.data = data
    }
    
    // MARK: - Utils
    
    public func item(at position: Position) -> CGPoint {
        self[position.section][position.item]
    }
    
    // MARK: - Push
    
    public mutating func push(_ item: CGPoint) {
        if data.isEmpty {
            data.append([item])
        } else {
            let index = data.endIndex - 1
            data[index] += [item]
        }
    }
    
    public mutating func pushSection(_ item: CGPoint) {
        data.append([item])
    }
    
    // MARK: - Update
    
    public mutating func update(_ item: CGPoint, at position: Position) {
        data[position.section][position.item] = item
    }
    
    // MARK: - Pop
    
    @discardableResult
    public mutating func pop() -> CGPoint? {
        guard !data.isEmpty else {
            return nil
        }
        
        let last = data[data.endIndex - 1].removeLast()
        
        if let section = data.last, section.isEmpty {
            data.removeLast()
        }
        
        return last
    }
    
    @discardableResult
    public mutating func popSection() -> [CGPoint]? {
        guard !data.isEmpty else {
            return nil
        }
        
        return data.removeLast()
    }
    
}

extension ObjectLayout: BidirectionalCollection {
    
    public var startIndex: Int {
        data.startIndex
    }
    
    public var endIndex: Int {
        data.endIndex
    }
    
    public subscript(section: Int) -> [CGPoint] {
        data[section]
    }
    
    public func index(before section: Int) -> Int {
        data.index(before: section)
    }
    
    public func index(after section: Int) -> Int {
        data.index(after: section)
    }
    
}
