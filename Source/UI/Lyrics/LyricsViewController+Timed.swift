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

extension LyricsViewController {
    
    var fileOpenDialog: NSOpenPanel {DialogsAndAlerts.openLyricsFileDialog}
    
    func showTimedLyricsView() {
        
        tabView.selectTabViewItem(at: 1)
        
        curLine = nil
        curSegment = nil
        tableView.reloadData()
        
        track != nil ? timer.startOrResume() : timer.pause()
        
        messenger.subscribeAsync(to: .Player.playbackStateChanged, handler: playbackStateChanged)
        messenger.subscribeAsync(to: .Player.seekPerformed, handler: seekPerformed)
    }
    
    @IBAction func loadLyricsButtonAction(_ sender: NSButton) {
        
        if fileOpenDialog.runModal() == .OK, let lyricsFile = fileOpenDialog.url {
            loadLyrics(fromFile: lyricsFile)
        }
    }
    
    @IBAction func searchForLyricsOnlineButtonAction(_ sender: NSButton) {
        
        // TODO:
    }
    
    func loadLyrics(fromFile lyricsFile: URL) {
        
        guard let track, trackReader.loadTimedLyricsFromFile(at: lyricsFile, for: track) else {
            
            NSAlert.showError(withTitle: "Lyrics not loaded", andText: "Failed to load synced lyrics from file: '\(lyricsFile.lastPathComponent)'")
            return
        }
        
        self.timedLyrics = track.externalTimedLyrics
        
        showTimedLyricsView()
    }
    
    func updateTimedLyricsText() {
        tableView.reloadData()
    }
    
    func dismissTimedLyricsView() {
        
        timer.pause()
        messenger.unsubscribe(from: .Player.playbackStateChanged)
        messenger.unsubscribe(from: .Player.seekPerformed)
    }
    
    private var isAutoScrollEnabled: Bool {
        preferences.metadataPreferences.lyrics.enableAutoScroll.value
    }
    
    func highlightCurrentLine() {
        
        guard let timedLyrics else {return}
        
        let seekPos = playbackInfoDelegate.seekPosition.timeElapsed
        
        if let curLine {
            
            let line = timedLyrics.lines[curLine]
            
            if line.isCurrent(atPosition: seekPos) {
                
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
        player.state == .playing ? timer.startOrResume() : timer.pause()
    }

    func seekPerformed() {
        highlightCurrentLine()
    }
}

extension LyricsViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {timedLyrics?.lines.count ?? 0}
}

extension LyricsViewController: NSTableViewDelegate {
    
    private static let rowHeight: CGFloat = 30
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        Self.rowHeight
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        
        // Seek to clicked line.
        if let timedLyrics, timedLyrics.lines.indices.contains(row) {
            messenger.publish(.Player.jumpToTime, payload: max(0, timedLyrics.lines[row].position))
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
        
        if isCurrentLine, line.segments.isNonEmpty {
            
            if let curSegment {
                
                var mutStr: NSMutableAttributedString = .init(string: "")
                
                let segment = line.segments[curSegment]
                let segmentLoc = segment.range.location
                
                if segmentLoc > 1 {
                    
                    let preSegmentRange = NSMakeRange(0, segmentLoc)

                    let subString = line.content.substring(range: preSegmentRange.intRange)
                    let attrStr =  subString.attributed(font: systemFontScheme.lyricsHighlightFont, color: systemColorScheme.primarySelectedTextColor)
                    mutStr = mutStr + attrStr
                }
                
                let subString = line.content.substring(range: segment.range.intRange)
                mutStr = mutStr + subString.attributed(font: systemFontScheme.lyricsHighlightFont, color: systemColorScheme.activeControlColor)
                
                let segmentLen = segment.range.length
                let segmentEnd = segmentLoc + segmentLen
                let contentLength = line.contentLength
                
                if segmentEnd < contentLength {
                    
                    let postSegmentRange = NSMakeRange(segmentEnd, contentLength - segmentEnd)
                    
                    let subString = line.content.substring(range: postSegmentRange.intRange)
                    let attrStr = subString.attributed(font: systemFontScheme.lyricsHighlightFont, color: systemColorScheme.primarySelectedTextColor)
                    mutStr = mutStr + attrStr
                }
                
                cell.attributedText = mutStr
                
            } else {
                
                // No cur segment
                
                cell.text = line.content
                cell.textFont = systemFontScheme.lyricsHighlightFont
                cell.textColor = systemColorScheme.primarySelectedTextColor
            }
            
        } else {
            
            cell.text = line.content
            cell.textFont = isCurrentLine ? systemFontScheme.lyricsHighlightFont : systemFontScheme.prominentFont
            cell.textColor = isCurrentLine ? systemColorScheme.activeControlColor : systemColorScheme.secondaryTextColor
        }
        
        cell.textField?.show()
        cell.textField?.lineBreakMode = .byTruncatingTail
        
        return cell
    }
}
