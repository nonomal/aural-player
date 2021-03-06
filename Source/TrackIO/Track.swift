import Cocoa
import AVFoundation

/*
    Encapsulates all information about a single track
 */
class Track: Hashable, PlayableItem, PlaylistItem {
    
    let file: URL
    let fileExtension: String
    
    let isNativelySupported: Bool
    
    var playbackContext: PlaybackContextProtocol?
    
    var isPlayable: Bool = true
    var validationError: DisplayableError?
    
    var hasPlaylistMetadata: Bool = false
    
    let defaultDisplayName: String
    
    var displayName: String {
        artistTitleString ?? defaultDisplayName
    }
    
    var duration: Double = 0

    var title: String?
    
    var theArtist: String?
    
    var artist: String? {
        theArtist ?? albumArtist ?? performer
    }
    
    var artistTitleString: String? {
        
        if let theArtist = artist, let theTitle = title {
            return "\(theArtist) - \(theTitle)"
        }
        
        return title
    }
    
    var albumArtist: String?
    var album: String?
    var genre: String?
    
    var composer: String?
    var conductor: String?
    var performer: String?
    var lyricist: String?
    
    var art: CoverArt? {
        didSet {artLoaded = true}
    }
    
    var trackNumber: Int?
    var totalTracks: Int?
    
    var discNumber: Int?
    var totalDiscs: Int?
    
    var year: Int?
    
    var bpm: Int?
    
    var lyrics: String?
    
    // Generic metadata
    var genericMetadata: [String: MetadataEntry] = [:]
    
    var chapters: [Chapter] = []
    var hasChapters: Bool {!chapters.isEmpty}
    
    var fileSystemInfo: FileSystemInfo
    var audioInfo: AudioInfo?
    
    init(_ file: URL, fileMetadata: FileMetadata? = nil) {

        self.file = file
        self.fileExtension = file.pathExtension.lowercased()
        self.fileSystemInfo = FileSystemInfo(file)
        
        self.defaultDisplayName = file.deletingPathExtension().lastPathComponent
        
        self.isNativelySupported = AppConstants.SupportedTypes.nativeAudioExtensions.contains(fileExtension)
        
        if let theFileMetadata = fileMetadata {
            setPlaylistMetadata(from: theFileMetadata)
        }
    }
    
    func setPlaylistMetadata(from allMetadata: FileMetadata) {
        
        self.isPlayable = allMetadata.isPlayable
        self.validationError = allMetadata.validationError
        
        guard let metadata: PlaylistMetadata = allMetadata.playlist else {return}
        
        self.title = metadata.title
        
        self.theArtist = metadata.artist
        self.albumArtist = metadata.albumArtist
        self.performer = metadata.performer
        
        self.album = metadata.album
        self.genre = metadata.genre

        self.trackNumber = metadata.trackNumber
        self.totalTracks = metadata.totalTracks
        
        self.discNumber = metadata.discNumber
        self.totalDiscs = metadata.totalDiscs
        
        self.duration = metadata.duration
        
        self.chapters = metadata.chapters
    }
    
    func setAuxiliaryMetadata(_ metadata: AuxiliaryMetadata) {
        
        self.composer = metadata.composer
        self.conductor = metadata.conductor
        self.lyricist = metadata.lyricist
        
        self.bpm = metadata.bpm
        self.year = metadata.year

        self.lyrics = metadata.lyrics
        self.genericMetadata = metadata.genericMetadata
        
        self.fileSystemInfo = metadata.fileSystemInfo ?? self.fileSystemInfo
        self.audioInfo = metadata.audioInfo
        
        self.auxMetadataLoaded = true
        
        if !self.artLoaded {
            self.art = metadata.art
        }
    }
    
    var artLoaded: Bool = false
    var auxMetadataLoaded: Bool = false
    
    static func == (lhs: Track, rhs: Track) -> Bool {
        return lhs.file == rhs.file
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(file.path)
    }
}

//class LazyLoadingInfo {
//
//    // Whether or not the track is ready for playback
//    var validated: Bool = false
//    var preparedForPlayback: Bool = false
//
//    var primaryInfoLoaded: Bool = false
//    var secondaryInfoLoaded: Bool = false
//
//    var artLoaded: Bool = false
//
//    // Whether or not optional track metadata and audio/filesystem info has been loaded
//    var detailedInfoLoaded: Bool = false
//
//    // Error info if track prep fails
//    var preparationFailed: Bool = false
//    var preparationError: InvalidTrackError?
//
//    func preparationFailed(_ error: InvalidTrackError?) {
//
//        preparationFailed = true
//        preparationError = error
//    }
//}

// Wrapper around Track that includes its location within a group in a hierarchical playlist
struct GroupedTrack {
    
    let track: Track
    let group: Group
    
    let trackIndex: Int
    let groupIndex: Int
    
    init(_ track: Track, _ group: Group, _ trackIndex: Int, _ groupIndex: Int) {
        
        self.track = track
        self.group = group
        self.trackIndex = trackIndex
        self.groupIndex = groupIndex
    }
}
