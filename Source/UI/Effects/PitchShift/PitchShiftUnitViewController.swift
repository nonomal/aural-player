//
//  PitchShiftUnitViewController.swift
//  Aural
//
//  Copyright © 2025 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import Cocoa

/*
    View controller for the Pitch effects unit
 */
class PitchShiftUnitViewController: EffectsUnitViewController {
    
    override var nibName: NSNib.Name? {"PitchShiftUnit"}
    
    // ------------------------------------------------------------------------
    
    // MARK: UI fields
    
    @IBOutlet weak var pitchShiftUnitView: PitchShiftUnitView!
    
    // ------------------------------------------------------------------------
    
    // MARK: Services, utilities, helpers, and properties
    
    private var pitchShiftUnit: PitchShiftUnitDelegateProtocol = audioGraphDelegate.pitchShiftUnit
    
    // ------------------------------------------------------------------------
    
    // MARK: UI initialization / life-cycle
 
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        effectsUnit = pitchShiftUnit
        presetsWrapper = PresetsWrapper<PitchShiftPreset, PitchShiftPresets>(pitchShiftUnit.presets)
    }
    
    override func initControls() {
        
        super.initControls()
        pitchShiftUnitView.pitch = pitchShiftUnit.pitch
    }
    
    // ------------------------------------------------------------------------
    
    // MARK: Actions
    
    // Updates the pitch
    @IBAction func pitchAction(_ sender: AnyObject) {
        pitchShiftUnit.pitch = pitchShiftUnitView.pitchUpdated()
    }
    
    @IBAction func increasePitchByOctaveAction(_ sender: AnyObject) {
        pitchShiftUnitView.pitch = pitchShiftUnit.increasePitchOneOctave()
    }
    
    @IBAction func increasePitchBySemitoneAction(_ sender: AnyObject) {
        pitchShiftUnitView.pitch = pitchShiftUnit.increasePitchOneSemitone()
    }
    
    @IBAction func increasePitchByCentAction(_ sender: AnyObject) {
        pitchShiftUnitView.pitch = pitchShiftUnit.increasePitchOneCent()
    }
    
    @IBAction func decreasePitchByOctaveAction(_ sender: AnyObject) {
        pitchShiftUnitView.pitch = pitchShiftUnit.decreasePitchOneOctave()
    }
    
    @IBAction func decreasePitchBySemitoneAction(_ sender: AnyObject) {
        pitchShiftUnitView.pitch = pitchShiftUnit.decreasePitchOneSemitone()
    }
    
    @IBAction func decreasePitchByCentAction(_ sender: AnyObject) {
        pitchShiftUnitView.pitch = pitchShiftUnit.decreasePitchOneCent()
    }
    
    // ------------------------------------------------------------------------
    
    // MARK: Message handling
    
    override func initSubscriptions() {
        
        super.initSubscriptions()
        messenger.subscribe(to: .Effects.PitchShiftUnit.pitchUpdated, handler: pitchUpdated)
    }

    // Changes the pitch to a specified value
    private func pitchUpdated() {
        
        messenger.publish(.Effects.unitStateChanged)
        
        pitchShiftUnitView.pitch = pitchShiftUnit.pitch
        
        // Show the Pitch tab if the Effects panel is shown
        showThisTab()
    }
}
