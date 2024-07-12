//
//  AVFScheduler.swift
//  Aural
//
//  Copyright © 2024 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import AVFoundation

///
/// Manages scheduling and initiating playback for native tracks (supported by **AVFoundation**).
///
/// - SeeAlso: `PlaybackSchedulerProtocol`
///
class AVFScheduler: PlaybackSchedulerProtocol {
    
    // Player node used for actual playback
    var playerNode: AuralPlayerNode
    
    let completionHandlerQueue: DispatchQueue = .global(qos: .userInteractive)

    // Indicates whether or not a track completed while the player was paused.
    // This is required because, in rare cases, some file segments may complete when they've reached close to the end, even if the last frame has not played yet.
    var trackCompletedWhilePaused: Bool = false

    // Caches a previously computed/scheduled playback segment, when a segment loop is defined, in order to prevent redundant computations.
    var loopingSegment: PlaybackSegment?
    
    lazy var messenger = Messenger(for: self)
    
    init(_ playerNode: AuralPlayerNode) {
        
        self.playerNode = playerNode
        playerNode.completionCallbackType = .dataPlayedBack
        playerNode.completionCallbackQueue = completionHandlerQueue
    }
    
    // Retrieves the current seek position, in seconds
//    var seekPosition: Double {
//
//        guard let session = PlaybackSession.currentSession else {return 0}
//        
//        // Prevent seekPosition from overruning the track duration (or loop start/end times)
//        // to prevent weird incorrect UI displays of seek time
//            
//        // Check for loop
//        if let loop = session.loop {
//            
//            if let loopEndTime = loop.endTime {
//                return min(max(loop.startTime, playerNode.seekPosition), loopEndTime)
//                
//            } else {
//                // Incomplete loop (start time only)
//                return min(max(loop.startTime, playerNode.seekPosition), session.track.duration)
//            }
//            
//        } else {    // No loop
//            return min(max(0, playerNode.seekPosition), session.track.duration)
//        }
//    }
    
    // MARK: Track scheduling, playback, and seeking functions -------------------------------------------------------------------------------------------
    
    // Start track playback from a given position expressed in seconds
    func playTrack(_ session: PlaybackSession, _ startPosition: Double) {
        seekToTime(session, startPosition, true)
    }

    // Seeks to a certain position (seconds) in the specified track. Returns the calculated start frame.
    func seekToTime(_ session: PlaybackSession, _ startTime: Double, _ beginPlayback: Bool) {
        
        // If a complete loop is defined (i.e. seeking within a loop), call playLoop() instead.
        if session.hasCompleteLoop() {
            
            playLoop(session, startTime, beginPlayback)
            return
        }
        
        // Halt current playback
        stop()
        
        guard let playbackCtx = session.track.playbackContext as? AVFPlaybackContext,
              let audioFile = playbackCtx.audioFile else {
            return
        }
        
        _ = playerNode.scheduleSegment(session: session, completionHandler: segmentCompletionHandler(session),
                                       startTime: startTime, playingFile: audioFile)

        // Don't start playing if player is paused
        if beginPlayback {
            playerNode.play()
        }
    }
    
    func pause() {
        playerNode.pause()
    }

    func resume() {
        
        // Check if track completion occurred while paused.
        if trackCompletedWhilePaused, let curSession = PlaybackSession.currentSession {

            // Reset the flag and signal completion.
            trackCompletedWhilePaused = false
            trackCompleted(curSession)
            
        } else {
            playerNode.play()
        }
    }

    // Clears any previously scheduled segments and stops playback, in response to a request to stop playback, change a track, or when seeking to a new position. Marks the end of a "playback session".
    func stop() {

        playerNode.stop()
        trackCompletedWhilePaused = false
    }
    
    // MARK: Completion handler functions -------------------------------------------------------

    // Signal track playback completion
    func trackCompleted(_ session: PlaybackSession) {
        messenger.publish(.Player.trackPlaybackCompleted, payload: session)
    }
    
    // Computes a segment completion handler closure, given a playback session.
    func segmentCompletionHandler(_ session: PlaybackSession) -> SessionCompletionHandler {
        
        return {(_ session: PlaybackSession) -> Void in
            
            // If the segment-associated session is not the same as the current session
            // (possible if stop() was called, eg. old segments that complete when seeking), don't do anything
            guard PlaybackSession.isCurrent(session) else {return}
            
            if self.playerNode.isPlaying {
                self.trackCompleted(session)
                
            } else {
                // Player is paused
                self.trackCompletedWhilePaused = true
            }
        }
    }
}
