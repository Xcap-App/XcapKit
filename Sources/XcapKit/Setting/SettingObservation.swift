//
//  SettingObservation.swift
//  
//
//  Created by scchn on 2023/2/23.
//

import Foundation

extension SettingObservation {
    
    public struct Options: OptionSet {
        
        public var rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let initial = Options(rawValue: 1 << 0)
        public static let new     = Options(rawValue: 1 << 1)
        
    }
    
}

public class SettingObservation {
    
    private let invalidationHandler: (String) -> Void
    
    let token: String
    
    deinit {
        invalidationHandler(token)
    }
    
    init(invalidationHandler: @escaping (String) -> Void) {
        self.invalidationHandler = invalidationHandler
        self.token = UUID().uuidString
    }
    
    public func invalidate() {
        invalidationHandler(token)
    }
    
}

extension SettingObservation: Equatable, Hashable {
    
    public static func == (lhs: SettingObservation, rhs: SettingObservation) -> Bool {
        lhs.token == rhs.token
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(token)
    }
    
}

extension SettingObservation {
    
    public func store<C>(in collection: inout C) where C : RangeReplaceableCollection, C.Element == SettingObservation {
        guard !collection.contains(self) else {
            return
        }
        
        collection.append(self)
    }
    
    public func store(in set: inout Set<SettingObservation>) {
        set.update(with: self)
    }
    
}
