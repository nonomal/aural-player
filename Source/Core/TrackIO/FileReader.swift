//
//  FileReader.swift
//  Aural
//
//  Copyright © 2025 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//  
import Foundation

///
/// A facade for loading metadata for a file.
/// 
/// Delegates to either **AVFoundation** or **FFmpeg** depending on whether or not
/// the file is natively supported.
///
class FileReader: FileReaderProtocol {
    
    ///
    /// The actual file reader for natively supported tracks. Uses AVFoundation.
    ///
    let avfReader: AVFFileReader = AVFFileReader()
    
    ///
    /// The actual file reader for non-native tracks. Uses FFmpeg.
    ///
    let ffmpegReader: FFmpegFileReader = FFmpegFileReader()
    
    func getPrimaryMetadata(for file: URL) throws -> PrimaryMetadata {
        
        let metadata = file.isNativelySupported ?
            try avfReader.getPrimaryMetadata(for: file) :
            try ffmpegReader.getPrimaryMetadata(for: file)
        
        return metadata
    }
    
    func computeAccurateDuration(for file: URL) -> Double? {
        
        return file.isNativelySupported ?
            avfReader.computeAccurateDuration(for: file) :
            ffmpegReader.computeAccurateDuration(for: file)
    }
    
    func getPlaybackMetadata(for file: URL) throws -> PlaybackContextProtocol {
        
        return file.isNativelySupported ?
            try avfReader.getPlaybackMetadata(for: file) :
            try ffmpegReader.getPlaybackMetadata(for: file)
    }
    
    func getArt(for file: URL) -> CoverArt? {
        
        // Try retrieving cover art from the cache.
//        if let cachedArt = CoverArtCache.forFile(file) {
//            return cachedArt.art
//        }
        
        // Cover art was not found in the cache, load it from the appropriate file reader.
        let art: CoverArt? = file.isNativelySupported ?
            avfReader.getArt(for: file) :
            ffmpegReader.getArt(for: file)
        
        // Update the cache with the newly loaded cover art.
//        CoverArtCache.addEntry(file, art)
        
        return art
    }
}
