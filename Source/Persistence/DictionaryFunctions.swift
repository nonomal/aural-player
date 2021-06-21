import Foundation

extension Dictionary where Key == AnyHashable, Value == Any {
    
    subscript<T>(_ key: String, type: T.Type) -> T? where T: Any {
        
        get {self[key] as? T}
        set {}
    }
}

extension Dictionary where Key == String, Value == Any {
    
    subscript<T>(_ key: String, type: T.Type) -> T? where T: Any {
        
        get {self[key] as? T}
        set {}
    }
    
    func nonEmptyStringValue(forKey key: String) -> String? {
        
        if let string = self[key] as? String {
            return string.isEmptyAfterTrimming ? nil : string
        }
        
        return nil
    }
    
    func enumValue<T: RawRepresentable>(forKey key: String, ofType: T.Type) -> T? where T.RawValue == String {
        
        if let string = self[key] as? String {
            return T(rawValue: string)
        }
        
        return nil
    }
    
    func urlValue(forKey key: String) -> URL? {
        
        if let string = self[key] as? String {
            return URL(fileURLWithPath: string)
        }
        
        return nil
    }
}

extension NSDictionary {
    
    subscript<T>(_ key: String, type: T.Type) -> T? where T: Any {
        
        get {self[key] as? T}
        set {}
    }
    
    func cgFloatValue(forKey key: String) -> CGFloat? {
        
        if let floatValue = self[key] as? Float {
            return CGFloat(floatValue)
        }
        
        return nil
    }
    
    func nonEmptyStringValue(forKey key: String) -> String? {
        
        if let string = self[key] as? String {
            return string.isEmptyAfterTrimming ? nil : string
        }
        
        return nil
    }
    
    func persistentObjectValue<T: PersistentStateProtocol>(forKey key: String, ofType: T.Type) -> T? {
        
        if let dict = self[key] as? NSDictionary {
            return T.init(dict)
        }
        
        return nil
    }
    
    func persistentFactoryObjectValue<T: PersistentStateFactoryProtocol, U: PersistentStateProtocol>(forKey key: String, ofType: T.Type) -> U? {
        
        if let dict = self[key] as? NSDictionary {
            return T.deserialize(dict) as? U
        }
        
        return nil
    }
    
    func persistentObjectArrayValue<T: PersistentStateProtocol>(forKey key: String, ofType: T.Type) -> [T]? {
        
        if let array = self[key] as? [NSDictionary] {
            return array.compactMap {T.init($0)}
        }
        
        return nil
    }
    
    func enumValue<T: RawRepresentable>(forKey key: String, ofType: T.Type) -> T? where T.RawValue == String {
        
        if let string = self[key] as? String {
            return T(rawValue: string)
        }
        
        return nil
    }
    
    func urlValue(forKey key: String) -> URL? {
        
        if let string = self[key] as? String {
            return URL(fileURLWithPath: string)
        }
        
        return nil
    }
    
    func urlArrayValue(forKey key: String) -> [URL]? {
        (self[key] as? [String])?.map {URL(fileURLWithPath: $0)}
    }
    
    func dateValue(forKey key: String) -> Date? {
        
        if let string = self[key] as? String {
            return Date.fromString(string)
        }
        
        return nil
    }
    
    func nsPointValue(forKey key: String) -> NSPoint? {
        
        if let dict = self[key] as? NSDictionary,
           let px = dict.cgFloatValue(forKey: "x"),
           let py = dict.cgFloatValue(forKey: "y") {
            
            return NSPoint(x: px, y: py)
        }
        
        return nil
    }
    
    func nsSizeValue(forKey key: String) -> NSSize? {
        
        if let dict = self[key] as? NSDictionary,
           let width = dict.cgFloatValue(forKey: "width"),
           let height = dict.cgFloatValue(forKey: "height") {
            
            return NSSize(width: width, height: height)
        }
        
        return nil
    }
    
    func nsRectValue(forKey key: String) -> NSRect? {
        
        if let dict = self[key] as? NSDictionary,
           let origin = dict.nsPointValue(forKey: "origin"),
           let size = dict.nsSizeValue(forKey: "size") {
            
            return NSRect(origin: origin, size: size)
        }
        
        return nil
    }
    
    func persistentColorValue(forKey key: String) -> ColorPersistentState? {
        
        if let dict = self[key] as? NSDictionary {
            return ColorPersistentState.deserialize(dict)
        }
        
        return nil
    }
}
