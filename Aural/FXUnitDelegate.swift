import Foundation

class FXUnitDelegate<T: FXUnit>: FXUnitDelegateProtocol {
    
    var unit: T
    
    init(_ unit: T) {
        self.unit = unit
    }
    
    var state: EffectsUnitState {
        return unit.state
    }
    
    func toggleState() -> EffectsUnitState {
        return unit.toggleState()
    }
    
    func ensureActive() {
        unit.ensureActive()
    }
    
    func savePreset(_ presetName: String) {
        unit.savePreset(presetName)
    }
    
    func applyPreset(_ presetName: String) {
        unit.applyPreset(presetName)
    }
}
