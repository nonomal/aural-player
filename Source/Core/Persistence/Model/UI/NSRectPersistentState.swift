//
//  NSRectPersistentState.swift
//  Aural
//
//  Copyright © 2024 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//  
import Foundation

///
/// A persistent representation of an **NSRect** object.
///
struct NSRectPersistentState: Codable {
    

    let origin: NSPointPersistentState?
    let size: NSSizePersistentState?
    
    init(origin: NSPointPersistentState? = nil, size: NSSizePersistentState? = nil) {
        
        self.origin = origin
        self.size = size
    }
    
    init(rect: NSRect) {
        
        self.origin = NSPointPersistentState(point: rect.origin)
        self.size = NSSizePersistentState(size: rect.size)
    }
    
    func toNSRect() -> NSRect? {
    
        guard let origin = self.origin?.toNSPoint(), let size = self.size?.toNSSize() else {return nil}
        return NSRect(origin: origin, size: size)
    }
}
