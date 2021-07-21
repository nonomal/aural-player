//
//  EffectsUnitDelegate.swift
//  Aural
//
//  Copyright © 2021 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import Foundation

///
/// An abstract delegate representing an effects unit.
///
/// Acts as a middleman between the Effects UI and an effects unit,
/// providing a simplified interface / facade for the UI layer to control an effects unit.
///
/// No instances of this type are to be used directly, as this class is only intended to be used as a base
/// class for concrete effects units delegates.
///
/// - SeeAlso: `EffectsUnitDelegateProtocol`
/// - SeeAlso: `EffectsUnit`
///
class EffectsUnitDelegate<T: EffectsUnit>: EffectsUnitDelegateProtocol {
    
    var unit: T
    
    init(_ unit: T) {
        self.unit = unit
    }
    
    var state: EffectsUnitState {unit.state}
    
    var stateFunction: EffectsUnitStateFunction {unit.stateFunction}
    
    var isActive: Bool {unit.isActive}
    
    func toggleState() -> EffectsUnitState {
        unit.toggleState()
    }
    
    func ensureActive() {
        unit.ensureActive()
    }
    
    func savePreset(_ presetName: String) {
        unit.savePreset(presetName)
    }
    
    // FIXME: Ensure unit active.
    func applyPreset(_ presetName: String) {
        
        unit.applyPreset(presetName)
        unit.ensureActive()
    }
}
