//
//  FFmpegImageStream.swift
//  Aural
//
//  Copyright © 2025 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import Foundation

///
/// Encapsulates an ffmpeg **AVStream** struct that represents a single image (video) stream,
/// and provides convenient Swift-style access to its functions and member variables.
///
/// Instantiates and provides the codec corresponding to the stream, and a codec context.
///
class FFmpegImageStream: FFmpegStreamProtocol {
    
    ///
    /// A pointer to the encapsulated AVStream object.
    ///
    private var pointer: UnsafeMutablePointer<AVStream>
    
    ///
    /// The encapsulated AVStream object.
    ///
    var avStream: AVStream {pointer.pointee}
    
    ///
    /// The media type of data contained within this stream (e.g. audio, video, etc)
    ///
    let mediaType: AVMediaType = AVMEDIA_TYPE_VIDEO
    
    ///
    /// The index of this stream within its container.
    ///
    let index: Int32
    
    ///
    /// The packet (optionally) containing an attached picture.
    /// This can be used to read cover art.
    ///
    private(set) lazy var attachedPic: FFmpegPacket = FFmpegPacket(encapsulatingPointeeOf: &pointer.pointee.attached_pic)
    
    ///
    /// All metadata key / value pairs available for this stream.
    ///
    private(set) lazy var metadata: [String: String] = FFmpegMetadataReader.read(from: avStream.metadata)
    
    ///
    /// Instantiates this stream object and its associated codec and codec context.
    ///
    /// - Parameter pointer: Pointer to the underlying AVStream.
    ///
    /// - Parameter mediaType: The media type of this stream (e.g. audio / video, etc)
    ///
    init(encapsulatingPointeeOf pointer: UnsafeMutablePointer<AVStream>) {
        
        self.pointer = pointer
        self.index = pointer.pointee.index
    }
}
