//
//  FFmpegSampleConverter.swift
//  Aural
//
//  Copyright © 2021 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import AVFoundation
import Accelerate

fileprivate let bytesInAFloat: Int = MemoryLayout<Float>.size / MemoryLayout<UInt8>.size

///
/// Performs conversion of PCM audio samples to the standard format suitable for playback in an **AVAudioEngine**,
/// i.e. 32-bit floating point non-interleaved (aka planar).
///
/// Uses **libswresample** to do the actual conversion.
///
extension FFmpegDecoder {
    
    ///
    /// Transfer the decoded samples into an audio buffer that the audio engine can schedule for playback.
    ///
    func transferSamplesToPCMBuffer(from frameBuffer: FFmpegFrameBuffer, outputFormat: AVAudioFormat) -> AVAudioPCMBuffer? {
        
        // Transfer the decoded samples into an audio buffer that the audio engine can schedule for playback.
        guard let playbackBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat,
                                                    frameCapacity: AVAudioFrameCount(frameBuffer.sampleCount)) else {return nil}
        
        // The audio buffer will always be filled to capacity.
        playbackBuffer.frameLength = AVAudioFrameCount(frameBuffer.sampleCount)
        
        if frameBuffer.needsFormatConversion {
            convert(samplesIn: frameBuffer, andCopyTo: playbackBuffer)
            
        } else {
            copy(samplesIn: frameBuffer, into: playbackBuffer)
        }
        
        return playbackBuffer
    }
    
    func copy(samplesIn frameBuffer: FFmpegFrameBuffer, into audioBuffer: AVAudioPCMBuffer) {
        
        guard let floatChannelData = audioBuffer.floatChannelData else {return}
        
        let channelCount: Int = Int(frameBuffer.audioFormat.channelCount)
        
        // Keeps track of how many samples have been copied over so far.
        // This will be used as an offset when performing each copy operation.
        var sampleCountSoFar: Int = 0
        
        for frame in frameBuffer.frames {
            
            guard let srcData = frame.dataPointers else {return}
            let firstSampleIndex: Int = Int(frame.firstSampleIndex)
            
            // NOTE - The following copy operation assumes a non-interleaved output format (i.e. the standard Core Audio format).
            
            // Temporarily bind the input sample buffers as floating point numbers, and perform the copy.
            srcData.withMemoryRebound(to: UnsafeMutablePointer<Float>.self, capacity: channelCount) {srcPointers in
                
                // Iterate through all the channels.
                for channelIndex in 0..<channelCount {
                    
                    // Use Accelerate to perform the copy optimally, starting at the given offset.
                    cblas_scopy(frame.sampleCount,
                                srcPointers[channelIndex].advanced(by: firstSampleIndex), 1,
                                floatChannelData[channelIndex].advanced(by: sampleCountSoFar), 1)
                }
            }
            
            sampleCountSoFar += frame.intSampleCount
        }
    }
    
    func convert(samplesIn frameBuffer: FFmpegFrameBuffer, andCopyTo audioBuffer: AVAudioPCMBuffer) {
        
        guard let resampleCtx = self.resampleCtx, let floatChannelData = audioBuffer.floatChannelData else {return}
        
        var sampleCountSoFar: Int = 0
        let channelCount: Int = Int(frameBuffer.audioFormat.channelCount)
        let outputData: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>! = .allocate(capacity: channelCount)
        defer {outputData.deallocate()}
        
        floatChannelData.withMemoryRebound(to: UnsafeMutablePointer<UInt8>.self, capacity: channelCount) {outChannelPointers in
            
            // Convert one frame at a time.
            for frame in frameBuffer.frames {
                
                for ch in 0..<channelCount {
                    outputData[ch] = outChannelPointers[ch].advanced(by: sampleCountSoFar * bytesInAFloat)
                }
                
                resampleCtx.convertFrame(frame, andStoreIn: outputData)
                sampleCountSoFar += frame.intSampleCount
            }
        }
    }
}
