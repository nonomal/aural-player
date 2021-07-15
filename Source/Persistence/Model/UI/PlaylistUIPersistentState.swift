//
//  PlaylistUIPersistentState.swift
//  Aural
//
//  Copyright © 2021 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import Foundation

typealias PlaylistTypeString = String

///
/// Persistent state for the Playlist UI.
///
/// - SeeAlso: `PlaylistViewState`
///
struct PlaylistUIPersistentState: Codable {
    
    let view: PlaylistTypeString?
}
