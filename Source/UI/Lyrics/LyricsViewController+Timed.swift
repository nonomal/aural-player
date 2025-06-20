//
// LyricsViewController+Timed.swift
// Aural
// 
// Copyright © 2025 Kartik Venugopal. All rights reserved.
// 
// This software is licensed under the MIT software license.
// See the file "LICENSE" in the project root directory for license terms.
//

import AppKit

fileprivate var isKaraokeModeEnabled: Bool {
    preferences.metadataPreferences.lyrics.enableKaraokeMode
}

extension LyricsViewController {
    
    var fileOpenDialog: NSOpenPanel {DialogsAndAlerts.openLyricsFileDialog}
    
    func showTimedLyricsView() {
        
        tabView.selectTabViewItem(at: 1)
        
        curLine = nil
        curSegment = nil
        
        tableView.reloadData()
        highlightCurrentLine()
        
        track != nil && player.isPlaying ? timer.startOrResume() : timer.pause()
        
        messenger.subscribeAsync(to: .Player.playbackStateChanged, handler: playbackStateChanged)
        messenger.subscribeAsync(to: .Player.seekPerformed, handler: seekPerformed)
        messenger.subscribeAsync(to: .Lyrics.karaokeModePreferenceUpdated, handler: karaokeModePreferenceUpdated)
        
        searchSpinner.stopAnimation(nil)
    }
    
    func dismissTimedLyricsView() {
        
        timer.pause()
        
        messenger.unsubscribe(from: .Player.playbackStateChanged,
                              .Player.seekPerformed,
                              .Lyrics.karaokeModePreferenceUpdated)
    }
    
    @IBAction func loadLyricsButtonAction(_ sender: NSButton) {
        
        if fileOpenDialog.runModal() == .OK, let lyricsFile = fileOpenDialog.url {
            loadLyrics(fromFile: lyricsFile)
        }
    }
    
    func loadLyrics(fromFile lyricsFile: URL) {
        
        guard let track, trackReader.loadTimedLyricsFromFile(at: lyricsFile, for: track) else {
            
            NSAlert.showError(withTitle: "Lyrics not loaded", andText: "Failed to load synced lyrics from file: '\(lyricsFile.lastPathComponent)'")
            return
        }
        
        self.timedLyrics = track.externalTimedLyrics
        showTimedLyricsView()
    }
    
    @IBAction func searchForLyricsOnlineButtonAction(_ sender: NSButton) {
        searchForLyricsOnline()
    }
    
    func searchForLyricsOnline() {
        
        guard let track else {return}
        
        guard track.title != nil || track.artist != nil else {
            
            NSAlert.showError(withTitle: "Online lyrics search not possible", andText: "The playing track does not have artist/title metadata.")
            return
        }
        
        tabView.selectTabViewItem(at: 4)
        searchSpinner.startAnimation(nil)
        
        let uiUpdateBlock = {(timedLyrics: TimedLyrics?) in
            
            guard let timedLyrics else {
                
                self.tabView.selectTabViewItem(at: 2)
                self.searchSpinner.stopAnimation(nil)
                return
            }
            
            if player.playingTrack == track {
                
                self.timedLyrics = timedLyrics
                self.doUpdate()
            }
        }
        
        Task.detached(priority: .userInitiated) {
            await trackReader.searchForLyricsOnline(for: track, uiUpdateBlock: uiUpdateBlock)
        }
    }
    
    func updateTimedLyricsText() {
        tableView.reloadData()
    }
    
    private var isAutoScrollEnabled: Bool {
        preferences.metadataPreferences.lyrics.enableAutoScroll
    }
    
    func highlightCurrentLine() {
        
        guard let timedLyrics else {return}
        
        let seekPos = player.seekPosition.timeElapsed
        
        if let curLine {
            
            let line = timedLyrics.lines[curLine]
            
            if line.isCurrent(atPosition: seekPos) {
                
                if !isKaraokeModeEnabled {return}
                
                // Current line is still current. Find the current segment, if required.
                
                if line.segments.isEmpty {return}
                
                if let curSegment, line.segments[curSegment].isCurrent(atPosition: seekPos) {return}
                
                // No current segment or segment no longer current, find the new current one.
                let newCurSegment = line.findCurrentSegment(at: seekPos)
                
                if self.curSegment != newCurSegment {
                    
                    self.curSegment = newCurSegment
                    tableView.reloadRows([curLine])
                }
                
                return
            }
        }
        
        let newCurLine = timedLyrics.currentLine(at: seekPos)
        
        if newCurLine != self.curLine {
            
            // Try curLine + 1 (in most cases, playback proceeds sequentially, so this is the most likely line to match)
            let refreshIndices = [self.curLine, newCurLine].compactMap {$0}
            
            self.curLine = newCurLine
            self.curSegment = nil
            
            tableView.reloadRows(refreshIndices)
            
            if isAutoScrollEnabled, let curLine {
                tableView.scrollRowToVisible(curLine)
            }
        }
    }
    
    func playbackStateChanged() {
        player.isPlaying ? timer.startOrResume() : timer.pause()
    }

    func seekPerformed() {
        highlightCurrentLine()
    }
    
    func karaokeModePreferenceUpdated() {
        
        self.curSegment = nil
        
        if isKaraokeModeEnabled {
            highlightCurrentLine()
            
        } else if let curLine {
            tableView.reloadRows([curLine])
        }
    }
    
    func lyricsLoaded(notif: TrackInfoUpdatedNotification) {
        
        if player.playingTrack == notif.updatedTrack, appModeManager.isShowingLyrics {
            updateForTrack(notif.updatedTrack)
        }
    }
}

// MARK: TableViewDelegate ---------------------------------------------------------------------------------


extension LyricsViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {timedLyrics?.lines.count ?? 0}
}

extension LyricsViewController: NSTableViewDelegate {
    
    private static let rowHeight: CGFloat = 30
    
    @objc var lineBreakMode: NSLineBreakMode {.byTruncatingTail}
    
    var paragraphStyle: NSMutableParagraphStyle {
        lineBreakMode == .byTruncatingTail ? .byTruncatingTail : .byWordWrapping
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        Self.rowHeight
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        
        // Seek to clicked line.
        if let timedLyrics, timedLyrics.lines.indices.contains(row) {
            playbackOrch.seekTo(position: max(0, timedLyrics.lines[row].position))
        }
        
        return false
    }
    
    // Returns a view for a single column
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        guard let timedLyrics,
              let cell = tableView.makeView(withIdentifier: .cid_lyricsLine, owner: nil) as? AuralTableCellView
        else {return nil}
        
        let isCurrentLine = row == self.curLine
        let line = timedLyrics.lines[row]

        if isCurrentLine, isKaraokeModeEnabled, line.segments.isNonEmpty {
            updateCurrentLineCellInKaraokeMode(cell, line: line)
        } else {
            updateCellWithDefaultAppearance(cell, line: line, isCurrentLine: isCurrentLine)
        }
        
        cell.textField?.show()
        cell.textField?.lineBreakMode = self.lineBreakMode
        
        return cell
    }
    
    private func updateCurrentLineCellInKaraokeMode(_ cell: AuralTableCellView, line: TimedLyricsLine) {
        
        guard let curSegment else {
            
            // No current segment (eg. between words)
            
            cell.text = line.content
            cell.textFont = systemFontScheme.lyricsHighlightFont
            cell.textColor = systemColorScheme.primarySelectedTextColor
            
            return
        }
        
        var mutStr: NSMutableAttributedString = .init(string: "")
        
        let segment = line.segments[curSegment]
        
        if !String.isEmpty(segment.preSegmentContent) {
            mutStr = mutStr + segment.preSegmentContent.attributed(font: systemFontScheme.lyricsHighlightFont, color: systemColorScheme.primarySelectedTextColor)
        }
            
        mutStr = mutStr + segment.content.attributed(font: systemFontScheme.lyricsHighlightFont, color: systemColorScheme.activeControlColor)
        
        if !String.isEmpty(segment.postSegmentContent) {
            mutStr = mutStr + segment.postSegmentContent.attributed(font: systemFontScheme.lyricsHighlightFont, color: systemColorScheme.primarySelectedTextColor)
        }
        
        mutStr.addAttribute(.paragraphStyle, value: self.paragraphStyle, range: NSMakeRange(0, mutStr.length))
        
        cell.attributedText = mutStr
    }
    
    private func updateCellWithDefaultAppearance(_ cell: AuralTableCellView, line: TimedLyricsLine, isCurrentLine: Bool) {
        
        cell.text = line.content
        cell.textFont = isCurrentLine ? systemFontScheme.lyricsHighlightFont : systemFontScheme.prominentFont
        cell.textColor = isCurrentLine ? systemColorScheme.activeControlColor : systemColorScheme.secondaryTextColor
    }
}
