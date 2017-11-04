/*
    Encapsulates all CRUD logic for a playlist
 */
import Foundation
import AVFoundation

class Playlist: PlaylistCRUDProtocol {
    
    private var flatPlaylist: FlatPlaylistCRUDProtocol
    private var groupingPlaylists: [GroupType: GroupingPlaylistCRUDProtocol] = [GroupType: GroupingPlaylist]()
    
    // A map to quickly look up tracks by (absolute) file path (used when adding tracks, to avoid duplicates)
    private var tracksByFilePath: [String: Track] = [String: Track]()
    
    init(_ flatPlaylist: FlatPlaylistCRUDProtocol, _ groupingPlaylists: [GroupingPlaylistCRUDProtocol]) {
        
        self.flatPlaylist = flatPlaylist
        groupingPlaylists.forEach({self.groupingPlaylists[$0.groupType()] = $0})
    }
    
    func allTracks() -> [Track] {
        let copy = flatPlaylist.allTracks()
        return copy
    }
    
    func size() -> Int {
        return flatPlaylist.allTracks().count
    }
    
    func totalDuration() -> Double {
        
        let tracks = flatPlaylist.allTracks()
        var totalDuration: Double = 0
        
        tracks.forEach({totalDuration += $0.duration})
        
        return totalDuration
    }
    
    func summary() -> (size: Int, totalDuration: Double) {
        return (size(), totalDuration())
    }
    
    func summary(_ groupType: GroupType) -> (size: Int, totalDuration: Double, numGroups: Int) {
        return (size(), totalDuration(), groupingPlaylists[groupType]!.numberOfGroups())
    }
    
    func addTrack(_ track: Track) -> TrackAddResult? {
        
        if (!trackExists(track)) {
            
            tracksByFilePath[track.file.path] = track
            
            let index = flatPlaylist.addTrack(track)!
            
            var groupingResults = [GroupType: GroupedTrackAddResult]()
            groupingPlaylists.values.forEach({groupingResults[$0.groupType()] = $0.addTrack(track)})
            
            return TrackAddResult(flatPlaylistResult: index, groupingPlaylistResults: groupingResults)
        }
        
        return nil
    }
    
    // Checks whether or not a track with the given absolute file path already exists.
    private func trackExists(_ track: Track) -> Bool {
        return tracksByFilePath[track.file.path] != nil
    }
    
    func clear() {
        flatPlaylist.clear()
        groupingPlaylists.values.forEach({$0.clear()})
        tracksByFilePath.removeAll()
    }
    
    private func doSearch(_ query: SearchQuery, _ groupType: GroupType? = nil) -> SearchResults {
        
        // Smart search. Depending on query options, search either flat playlist or one of the grouped playlists. For ex, if searching by artist, it makes sense to search "Artists" playlist. Also, can split up the search into multiple parts, send them to different playlists, and put results together
        
        var allResults: SearchResults = SearchResults([])
        
        if (query.fields.name || query.fields.title) {
            allResults = flatPlaylist.search(query)
        }
        
        if (query.fields.artist) {
            
            let resultsByArtist = groupingPlaylists[.artist]!.search(query)
            allResults = allResults.union(resultsByArtist)
        }
        
        if (query.fields.album) {
            
            let resultsByAlbum = groupingPlaylists[.album]!.search(query)
            allResults = allResults.union(resultsByAlbum)
        }
        
        if let groupType = groupType {
            
            // Grouping playlist location
            
            for result in allResults.results {
                result.location.groupInfo = groupingInfoForTrack(groupType, result.location.track)
            }
            
            allResults = allResults.sortedByGroupAndTrackIndex()
            
        } else {
            
            // Flat playlist location
            
            for result in allResults.results {
                result.location.trackIndex = indexOfTrack(result.location.track)
            }
            
            allResults = allResults.sortedByTrackIndex()
        }
        
        return allResults
    }
    
    func search(_ query: SearchQuery, _ groupType: GroupType) -> SearchResults {
        return doSearch(query, groupType)
    }
    
    func search(_ query: SearchQuery) -> SearchResults {
        return doSearch(query)
    }
    
    func sort(_ sort: Sort) {
        doSort(sort)
    }
    
    func sort(_ sort: Sort, _ groupType: GroupType) {
        doSort(sort, groupType)
    }
    
    private func doSort(_ sort: Sort, _ groupType: GroupType? = nil) {
        
        if let groupType = groupType {
            groupingPlaylists[groupType]!.sort(sort)
        } else {
            flatPlaylist.sort(sort)
        }
    }
    
    // Returns all state for this playlist that needs to be persisted to disk
    func persistentState() -> PlaylistState {
        
        let state = PlaylistState()
        let tracks = allTracks()
        
        for track in tracks {
            state.tracks.append(track.file)
        }
        
        return state
    }
    
    func removeTracks(_ indexes: IndexSet) -> TrackRemovalResults {
        
        let removedTracks = flatPlaylist.removeTracks(indexes)
        removedTracks.forEach({tracksByFilePath.removeValue(forKey: $0.file.path)})
        
        var groupingPlaylistResults = [GroupType: [ItemRemovalResult]]()
        
        // Remove from all other playlists
        groupingPlaylists.values.forEach({
            groupingPlaylistResults[$0.groupType()] = $0.removeTracksAndGroups(removedTracks, [])
        })
        
        return TrackRemovalResults(groupingPlaylistResults: groupingPlaylistResults, flatPlaylistResults: indexes)
    }
    
    // ----------------------- FlatPlaylist protocols ----------------------------
    
    func indexOfTrack(_ track: Track) -> Int? {
        return flatPlaylist.indexOfTrack(track)
    }
    
    func moveTracksDown(_ indexes: IndexSet) -> ItemMoveResults {
        return flatPlaylist.moveTracksDown(indexes)
    }
    
    func moveTracksUp(_ indexes: IndexSet) -> ItemMoveResults {
        return flatPlaylist.moveTracksUp(indexes)
    }
    
    func trackAtIndex(_ index: Int?) -> IndexedTrack? {
        return flatPlaylist.trackAtIndex(index)
    }
    
    // ----------------------- GroupingPlaylist protocols ----------------------------
    
    func groupAtIndex(_ type: GroupType, _ index: Int) -> Group {
        return groupingPlaylists[type]!.groupAtIndex(index)
    }
    
    func groupingInfoForTrack(_ type: GroupType, _ track: Track) -> GroupedTrack {
        return groupingPlaylists[type]!.groupingInfoForTrack(track)
    }
    
    func indexOfGroup(_ group: Group) -> Int {
        return groupingPlaylists[group.type]!.indexOfGroup(group)
    }
    
    func numberOfGroups(_ type: GroupType) -> Int {
        return groupingPlaylists[type]!.numberOfGroups()
    }
    
    func removeTracksAndGroups(_ tracks: [Track], _ groups: [Group], _ groupType: GroupType) -> TrackRemovalResults {
        
        // Remove file/track mappings
        var removedTracks: [Track] = tracks
        groups.forEach({removedTracks.append(contentsOf: $0.tracks)})
        
        // Remove duplicates
        removedTracks = Array(Set(removedTracks))
        
        removedTracks.forEach({tracksByFilePath.removeValue(forKey: $0.file.path)})
        
        var groupingPlaylistResults = [GroupType: [ItemRemovalResult]]()
        
        // Remove from playlist with specified group type
        groupingPlaylistResults[groupType] = groupingPlaylists[groupType]!.removeTracksAndGroups(tracks, groups)
        
        // Remove from all other playlists
        
        groupingPlaylists.values.filter({$0.groupType() != groupType}).forEach({
            groupingPlaylistResults[$0.groupType()] = $0.removeTracksAndGroups(removedTracks, [])
        })
        
        let flatPlaylistIndexes = flatPlaylist.removeTracks(removedTracks)
        
        let results = TrackRemovalResults(groupingPlaylistResults: groupingPlaylistResults, flatPlaylistResults: flatPlaylistIndexes)
        
        return results
    }
    
    func moveTracksAndGroupsUp(_ tracks: [Track], _ groups: [Group], _ groupType: GroupType) -> ItemMoveResults {
        return groupingPlaylists[groupType]!.moveTracksAndGroupsUp(tracks, groups)
    }
    
    func moveTracksAndGroupsDown(_ tracks: [Track], _ groups: [Group], _ groupType: GroupType) -> ItemMoveResults {
        return groupingPlaylists[groupType]!.moveTracksAndGroupsDown(tracks, groups)
    }
    
    func displayNameForTrack(_ type: GroupType, _ track: Track) -> String {
        return groupingPlaylists[type]!.displayNameForTrack(track)
    }
    
    func reorderTracksAndGroups(_ reorderOperations: [GroupingPlaylistReorderOperation], _ groupType: GroupType) {
        groupingPlaylists[groupType]!.reorderTracksAndGroups(reorderOperations)
    }
    
    func dropTracks(_ sourceIndexes: IndexSet, _ dropIndex: Int, _ dropType: DropType) -> IndexSet {
        return flatPlaylist.dropTracks(sourceIndexes, dropIndex, dropType)
    }
}

struct TrackAddResult {
    
    let flatPlaylistResult: Int
    let groupingPlaylistResults: [GroupType: GroupedTrackAddResult]
}

struct GroupedTrackAddResult {
    
    let track: GroupedTrack
    let groupCreated: Bool
}

struct GroupedTrackUpdateResult {
    
    let track: GroupedTrack
    let groupCreated: Bool
    let oldGroupRemoved: Bool
}

struct TrackRemovalResults {
    
    let groupingPlaylistResults: [GroupType: [ItemRemovalResult]]
    let flatPlaylistResults: IndexSet
}

protocol ItemRemovalResult {
    var sortIndex: Int {get}
}

struct GroupRemovalResult: ItemRemovalResult {
    
    let group: Group
    let groupIndex: Int
    
    var sortIndex: Int {
        return groupIndex
    }
    
    init(_ group: Group, _ groupIndex: Int) {
        
        self.group = group
        self.groupIndex = groupIndex
    }
}

struct GroupedTracksRemovalResult: ItemRemovalResult {
    
    let trackIndexesInGroup: IndexSet
    let parentGroup: Group
    let groupIndex: Int
    
    var sortIndex: Int {
        return groupIndex
    }
    
    init(_ trackIndexesInGroup: IndexSet, _ parentGroup: Group, _ groupIndex: Int) {
        self.trackIndexesInGroup = trackIndexesInGroup
        self.parentGroup = parentGroup
        self.groupIndex = groupIndex
    }
}

struct ItemMoveResults {
    
    let results: [ItemMoveResult]
    let playlistType: PlaylistType
    
    init(_ results: [ItemMoveResult], _ playlistType: PlaylistType) {
        self.results = results
        self.playlistType = playlistType
    }
}

protocol ItemMoveResult {
    var sortIndex: Int {get}
}

struct GroupMoveResult: ItemMoveResult {
    
    let oldGroupIndex: Int
    let newGroupIndex: Int
    
    var sortIndex: Int {
        return oldGroupIndex
    }
    
    init(_ oldGroupIndex: Int, _ newGroupIndex: Int) {
        
        self.oldGroupIndex = oldGroupIndex
        self.newGroupIndex = newGroupIndex
    }
}

struct TrackMoveResult: ItemMoveResult {
    
    let oldTrackIndex: Int
    let newTrackIndex: Int
    let parentGroup: Group?
    
    var sortIndex: Int {
        return oldTrackIndex
    }
    
    init(_ oldTrackIndex: Int, _ newTrackIndex: Int, _ parentGroup: Group? = nil) {
        
        self.oldTrackIndex = oldTrackIndex
        self.newTrackIndex = newTrackIndex
        self.parentGroup = parentGroup
    }
}
