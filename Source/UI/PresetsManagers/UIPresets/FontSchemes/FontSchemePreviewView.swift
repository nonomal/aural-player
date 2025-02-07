//
//  FontSchemePreviewView.swift
//  Aural
//
//  Copyright © 2025 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import Cocoa

/*
    View that gives the user a visual preview of what the UI would look like if a particular color scheme is applied to it.
 */
class FontSchemePreviewView: NSView {
    
    @IBOutlet weak var containerBox: NSBox!
    
    @IBOutlet weak var lblPlayerTrackTitle: NSTextField!
    @IBOutlet weak var lblPlayerArtistAlbum: NSTextField!
    
    @IBOutlet weak var lblPlaylistHeading: NSTextField!
    @IBOutlet weak var lblPlaylistIndex: NSTextField!
    @IBOutlet weak var lblPlaylistTitle: NSTextField!
    @IBOutlet weak var lblPlaylistDuration: NSTextField!
    
    @IBOutlet weak var lblFxCaption: NSTextField!
    @IBOutlet weak var lblPitchCaption: NSTextField!
    @IBOutlet weak var lblPitchValue: NSTextField!
    
    private var playlistLabels: [NSTextField] = []
    
    override func awakeFromNib() {
        playlistLabels = [lblPlaylistIndex, lblPlaylistTitle, lblPlaylistDuration]
    }
    
    // When any of the following fields is set, update the corresponding fields.
    
    var scheme: FontScheme? {
        
        didSet {
            
            if let theScheme = scheme {
               
                playerTitleFont = theScheme.prominentFont
                playerArtistAlbumFont = theScheme.normalFont
                
                playlistHeadingFont = theScheme.captionFont
                playlistTrackTextFont = theScheme.normalFont
                
                effectsCaptionFont = theScheme.captionFont
                effectsFunctionFont = theScheme.normalFont
                
                containerBox.show()
            }
        }
    }
    
    var playerTitleFont: NSFont = standardFontSet.mainFont(size: 12) {
        
        didSet {
            lblPlayerTrackTitle.font = playerTitleFont
        }
    }
    
    var playerArtistAlbumFont: NSFont = standardFontSet.mainFont(size: 12) {
        
        didSet {
            lblPlayerArtistAlbum.font = playerArtistAlbumFont
        }
    }
    
    var playlistHeadingFont: NSFont = standardFontSet.mainFont(size: 12) {
        
        didSet {
            lblPlaylistHeading.font = playlistHeadingFont
        }
    }
    
    var playlistTrackTextFont: NSFont = standardFontSet.mainFont(size: 12) {
        
        didSet {
            playlistLabels.forEach {$0.font = playlistTrackTextFont}
        }
    }
    
    var effectsCaptionFont: NSFont = standardFontSet.mainFont(size: 12) {
        
        didSet {
            lblFxCaption.font = effectsCaptionFont
        }
    }
    
    var effectsFunctionFont: NSFont = standardFontSet.mainFont(size: 12) {
        
        didSet {
            lblPitchCaption.font = effectsFunctionFont
            lblPitchValue.font = effectsFunctionFont
        }
    }
    
    func clear() {
        containerBox.hide()
    }
}
