import Foundation

/*
    Contract for a middleman/delegate that relays all necessary playback operations to the player, and allows manipulation of the playback sequence
 */
protocol PlaybackDelegateProtocol: PlaybackInfoDelegateProtocol {
    
    /*
        Toggles between the play and pause states, as long as a file is available to play. Returns playback state information the UI can use to update itself following the operation.
    
        Throws an error if playback begins with a track that cannot be played back.
     */
    func togglePlayPause() throws -> (playbackState: PlaybackState, playingTrack: IndexedTrack?, trackChanged: Bool)
    
    /* 
        Plays the track at a given index in the player playlist. Returns complete track information for the track.
 
        Throws an error if the selected track cannot be played back.
 
        NOTE - When a single index is specified, it is implied that the playlist from which this request originated was the flat "Tracks" playlist, because this playlist locates tracks by a single absolute index. Hence, this function is intended to be called only when playback originates from the "Tracks" playlist.
     */
    func play(_ index: Int) throws -> IndexedTrack
    
    /*
        Plays the given track. Returns complete track information for the track.
        
        Throws an error if the selected track cannot be played back.
        
        NOTE - When a track is specified, it is implied that the playlist from which this request originated was a grouping/hierarchical playlist, because such a playlist does not provide a single index to locate an item. It provides either a track or a group. Hence, this function is intended to be called only when playback originates from one of the grouping/hierarchical playlists.
     */
    func play(_ track: Track) throws -> IndexedTrack
    
    /* 
        Plays the given track. Returns complete track information for the track.
        
        Throws an error if the selected track cannot be played back.
        
        NOTE - The "playlistType" argument is used to initialize the playback sequence (which is dependent on the current playlist view)
    */
    func play(_ track: Track, _ playlistType: PlaylistType) throws -> IndexedTrack
    
    /* 
        Initiates playback of (tracks within) the given group. Returns complete track information for the track that is chosen to play first.
 
        Throws an error if the track that is chosen to play first within the given group cannot be played back
     
        NOTE - When a group is specified, it is implied that the playlist from which this request originated was a grouping/hierarchical playlist, because such a playlist does not provide a single index to locate an item. It provides either a track or a group. Hence, this function is intended to be called only when playback originates from one of the grouping/hierarchical playlists.
     */
    func play(_ group: Group) throws -> IndexedTrack
    
    // Stops playback
    func stop()
    
    // Plays (and returns) the next track, if there is one. Throws an error if the next track cannot be played back
    func nextTrack() throws -> IndexedTrack?
    
    // Plays (and returns) the previous track, if there is one. Throws an error if the previous track cannot be played back
    func previousTrack() throws -> IndexedTrack?
    
    // Seeks forward a few seconds, within the current track
    func seekForward(_ actionMode: ActionMode)
    
    // Seeks backward a few seconds, within the current track
    func seekBackward(_ actionMode: ActionMode)
    
    // Seeks to a specific percentage of the track duration, within the current track
    func seekToPercentage(_ percentage: Double)
    
    // Toggles between repeat modes. See RepeatMode for more details. Returns the new repeat and shuffle mode after performing the toggle operation.
    func toggleRepeatMode() -> (repeatMode: RepeatMode, shuffleMode: ShuffleMode)
    
    // Toggles between shuffle modes. See ShuffleMode for more details. Returns the new repeat and shuffle mode after performing the toggle operation.
    func toggleShuffleMode() -> (repeatMode: RepeatMode, shuffleMode: ShuffleMode)
    
    // Sets the repeat mode to a specific value. Returns the new repeat and shuffle mode after performing the toggle operation.
    func setRepeatMode(_ repeatMode: RepeatMode) -> (repeatMode: RepeatMode, shuffleMode: ShuffleMode)
    
    // Sets the shuffle mode to a specific value. Returns the new repeat and shuffle mode after performing the toggle operation.
    func setShuffleMode(_ shuffleMode: ShuffleMode) -> (repeatMode: RepeatMode, shuffleMode: ShuffleMode)
}

// A contract for basic playback operations. Used for autoplay
protocol BasicPlaybackDelegateProtocol {

    // Plays the track with the given index, interrupting current playback if indicated by the interruptPlayback argument.
    func play(_ index: Int, _ interruptPlayback: Bool) throws -> IndexedTrack?
}
