//
//  FFmpegMetadataReader.swift
//  Aural
//
//  Copyright © 2025 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import Foundation

///
/// Reads metadata from an **AVDictionary**.
///
class FFmpegMetadataReader {

    ///
    /// Reads key / value pairs from a pointer to an **AVDictionary** and returns them in a Swift String-typed Dictionary.
    ///
    /// - Parameter pointer: Pointer to the source **AVDictionary** from which key / value pairs are to be read.
    ///
    static func read(from pointer: OpaquePointer!) -> [String: String] {
        
        var metadata: [String: String] = [:]
        var tagPtr: UnsafeMutablePointer<AVDictionaryEntry>?
        
        while let tag = av_dict_get(pointer, "", tagPtr, AV_DICT_IGNORE_SUFFIX) {
            
            let entry = tag.pointee
            metadata[entry.keyString] = entry.valueString
            tagPtr = tag
        }
        
        return metadata
    }
}

extension AVDictionaryEntry {
    
    var keyString: String {
        String(cString: key)
    }
    
    var valueString: String {
        String(cString: value)
    }
}
