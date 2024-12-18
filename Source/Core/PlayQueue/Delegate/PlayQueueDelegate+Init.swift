//
//  PlayQueueDelegate+Init.swift
//  Aural
//
//  Copyright © 2024 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//

import Foundation

extension PlayQueueDelegate {
    
    func initialize(fromPersistentState persistentState: PlayQueuePersistentState?, appLaunchFiles: [URL]) {
        
        lazy var playQueuePreferences = preferences.playQueuePreferences
        lazy var playbackPreferences = preferences.playbackPreferences
        
        // Check if any launch parameters were specified
        if appLaunchFiles.isNonEmpty {
            
            // Launch parameters specified, override playlist saved state and add file paths in params to playlist
            loadTracks(from: appLaunchFiles, params: .init(autoplay: playbackPreferences.autoplayAfterOpeningTracks.value))
            return
        }
        
        lazy var autoplayOnStartup: Bool = playbackPreferences.autoplayOnStartup.value
        lazy var pqParmsWithAutoplayAndNoHistory: PlayQueueTrackLoadParams = .init(autoplay: autoplayOnStartup, markLoadedItemsForHistory: false)
        
        switch playQueuePreferences.playQueueOnStartup.value {
            
        case .empty:
            break
            
        case .rememberFromLastAppLaunch:
            
            if let tracks = persistentState?.tracks, tracks.isNonEmpty {
                
                // No launch parameters specified, load playlist saved state if "Remember state from last launch" preference is selected
                loadTracks(from: tracks, params: pqParmsWithAutoplayAndNoHistory)
                playQueue.eligibleToResumeShuffleSequence = true
            }
            
        case .loadPlaylistFile:
            
            if let playlistFile = playQueuePreferences.playlistFile.value {
                
                loadTracks(from: [playlistFile], params: pqParmsWithAutoplayAndNoHistory)
                playQueue.eligibleToResumeShuffleSequence = true
            }
            
        case .loadFolder:
            
            if let folder = playQueuePreferences.tracksFolder.value {
                
                loadTracks(from: [folder], params: pqParmsWithAutoplayAndNoHistory)
                playQueue.eligibleToResumeShuffleSequence = true
            }
        }
        
        initializeHistory(fromPersistentState: persistentState?.history)
    }
    
    private func initializeHistory(fromPersistentState persistentState: HistoryPersistentState?) {
        
        if let lastPlaybackPosition = persistentState?.lastPlaybackPosition {
            self.markLastPlaybackPosition(lastPlaybackPosition)
        }
        
        // Restore the history model object from persistent state.
        guard let recentItemsState = persistentState?.recentItems else {return}
        
        // Move to a background thread to unblock the main thread.
        DispatchQueue.global(qos: .utility).async {
            
            for item in recentItemsState.compactMap(self.historyItemForState) {
                self.recentItems[item.key] = item
            }
        }
    }
    
    private func historyItemForState(_ state: HistoryItemPersistentState) -> HistoryItem? {
        
        guard let itemType = state.itemType, let lastEventTime = state.lastEventTime, let eventCount = state.eventCount else {return nil}
        
        var item: HistoryItem? = nil
        
        switch itemType {
            
        case .track:
            
            guard let trackFile = state.trackFile else {return nil}
            
            let track = Track(trackFile)
            item = TrackHistoryItem(track: track, lastEventTime: lastEventTime, eventCount: eventCount)
            
            trackReader.loadPrimaryMetadataAsync(for: track, onQueue: TrackReader.mediumPriorityQueue)
            
        case .playlistFile:
            
            if let playlistFile = state.playlistFile {
                item = PlaylistFileHistoryItem(playlistFile: playlistFile, lastEventTime: lastEventTime, eventCount: eventCount)
            }
            
        case .folder:
            
            if let folder = state.folder {
                item = FolderHistoryItem(folder: folder, lastEventTime: lastEventTime, eventCount: eventCount)
            }
            
        case .group:
            
//            if let groupName = state.groupName, let groupType = state.groupType {
//                item = GroupHistoryItem(groupName: groupName, groupType: groupType, lastEventTime: lastEventTime, eventCount: eventCount)
//            }
            return nil
        }
        
        return item
    }
}
