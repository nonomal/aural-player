//
//  AudioUnitsViewController+TableViewDelegate.swift
//  Aural
//
//  Copyright © 2025 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import Cocoa

// ------------------------------------------------------------------------

// MARK: NSTableViewDataSource

extension AudioUnitsViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {soundOrch.audioUnits.count}
}

// ------------------------------------------------------------------------

// MARK: NSTableViewDelegate

extension AudioUnitsViewController: NSTableViewDelegate {
    
    private static let tableRowHeight: CGFloat = 24
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {Self.tableRowHeight}
    
    // Returns a view for a single row
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {AudioUnitsTableRowView()}
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        guard let colID = tableColumn?.identifier else {return nil}
        
        switch colID {
        
        case .cid_audioUnitSwitch:
            
            return createSwitchCell(tableView, colID, row)
            
        case .cid_audioUnitName:
            
            return createNameCell(tableView, colID, row)
            
        case .cid_audioUnitEdit:
            
            return createEditCell(tableView, colID, row)
            
        default:
            
            return nil
        }
    }
    
    private func createSwitchCell(_ tableView: NSTableView, _ id: NSUserInterfaceItemIdentifier, _ row: Int) -> AudioUnitSwitchCellView? {
     
        guard let cell = tableView.makeView(withIdentifier: id, owner: nil) as? AudioUnitSwitchCellView else {return nil}
        
        let audioUnit = soundOrch.audioUnits[row] as! HostedAudioUnit
        
        fxUnitStateObserverRegistry.registerObserver(cell.btnSwitch, forFXUnit: audioUnit)

        cell.btnSwitch.offStateTooltip = "Activate this Audio Unit"
        cell.btnSwitch.onStateTooltip = "Deactivate this Audio Unit"
        
        cell.action = {[weak self, weak audioUnit] in
            
            if let audioUnit {
                self?.toggleAudioUnitState(audioUnit: audioUnit)
            }
        }
        
        return cell
    }
    
    private func createNameCell(_ tableView: NSTableView, _ id: NSUserInterfaceItemIdentifier, _ row: Int) -> AudioUnitNameCellView? {
        
        guard let cell = tableView.makeView(withIdentifier: id, owner: nil) as? AudioUnitNameCellView else {return nil}
        
        let audioUnit = soundOrch.audioUnits[row]
        
        cell.text = "\(audioUnit.name) v\(audioUnit.version) by \(audioUnit.manufacturerName)"
        cell.textFont = systemFontScheme.normalFont
        cell.rowSelectionStateFunction = {tableView.isRowSelected(row)}
        cell.realignText(yOffset: systemFontScheme.tableYOffset)
        
        return cell
    }
    
    private func createEditCell(_ tableView: NSTableView, _ id: NSUserInterfaceItemIdentifier, _ row: Int) -> AudioUnitEditCellView? {
        
        guard let cell = tableView.makeView(withIdentifier: id, owner: nil) as? AudioUnitEditCellView else {return nil}
        
        let audioUnit = soundOrch.audioUnits[row] as! HostedAudioUnit
        cell.btnEdit.contentTintColor = systemColorScheme.buttonColor
        
        cell.action = {[weak self, weak audioUnit] in
            
            if let audioUnit {
                self?.doEditAudioUnit(audioUnit)
            }
        }
        
        return cell
    }
}

// ------------------------------------------------------------------------

// MARK: Table column identifiers

extension NSUserInterfaceItemIdentifier {
    
    static let cid_audioUnitSwitch = NSUserInterfaceItemIdentifier("cid_AudioUnitSwitch")
    static let cid_audioUnitName = NSUserInterfaceItemIdentifier("cid_AudioUnitName")
    static let cid_audioUnitEdit = NSUserInterfaceItemIdentifier("cid_AudioUnitEdit")
}
