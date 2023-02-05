//
//  Observable.swift
//  
//
//  Created by scchn on 2022/11/29.
//

import Foundation

struct Observation {
    var old: Any
    var new: Any
}

protocol Observable: AnyObject {
    
    var valueDidUpdate: ((Observation) -> Void)? { get set }
    
}
