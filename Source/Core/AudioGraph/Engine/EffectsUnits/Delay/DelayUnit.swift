//
//  DelayUnit.swift
//  Aural
//
//  Copyright © 2025 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import AVFoundation

///
/// An effects unit that produces an echo effect by repeatedly
/// replaying the original input signal after a configurable delay. Each replayed
/// signal decays over time, creating a repeating and decaying echo.
///
/// - SeeAlso: `DelayUnitProtocol`
///
class DelayUnit: EffectsUnit, DelayUnitProtocol {
    
    private let node: AVAudioUnitDelay = .init()
    let presets: DelayPresets = .init()
    
    init() {
        super.init(unitType: .delay)
    }
    
    override var avNodes: [AVAudioNode] {[node]}
    
    override func reset() {
        node.reset()
    }
    
    var amount: Float {
        
        get {node.wetDryMix}
        set {node.wetDryMix = newValue}
    }
    
    var time: Double {
        
        get {node.delayTime}
        set {node.delayTime = newValue}
    }
    
    var feedback: Float {
        
        get {node.feedback}
        set {node.feedback = newValue}
    }
    
    var lowPassCutoff: Float {
        
        get {node.lowPassCutoff}
        set {node.lowPassCutoff = newValue}
    }
    
    override func stateChanged() {
        
        super.stateChanged()
        node.bypass = !isActive
    }
    
    override func savePreset(named presetName: String) {
        
        let newPreset = DelayPreset(name: presetName, state: .active, amount: amount,
                                    time: time, feedback: feedback, cutoff: lowPassCutoff, systemDefined: false)
        presets.addObject(newPreset)
    }
    
    override func applyPreset(named presetName: String) {
        
        if let preset = presets.object(named: presetName) {
            applyPreset(preset)
        }
    }
    
    func applyPreset(_ preset: DelayPreset) {
        
        time = preset.time
        amount = preset.amount
        feedback = preset.feedback
        lowPassCutoff = preset.lowPassCutoff
    }
    
    var settingsAsPreset: DelayPreset {
        
        DelayPreset(name: "delaySettings", state: state, amount: amount, time: time,
                    feedback: feedback, cutoff: lowPassCutoff, systemDefined: false)
    }
    
    var persistentState: DelayUnitPersistentState {

        DelayUnitPersistentState(state: state,
                                 userPresets: presets.userDefinedObjects.map {DelayPresetPersistentState(preset: $0)},
                                 renderQuality: renderQualityPersistentState,
                                 amount: amount,
                                 time: time,
                                 feedback: feedback,
                                 lowPassCutoff: lowPassCutoff)
    }
}
