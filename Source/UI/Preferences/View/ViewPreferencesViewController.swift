//
//  ViewPreferencesViewController.swift
//  Aural
//
//  Copyright © 2024 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import Cocoa

class ViewPreferencesViewController: NSViewController, PreferencesViewProtocol {
    
    override var nibName: NSNib.Name? {"ViewPreferences"}
    
    @IBOutlet weak var btnWindowMagnetism: CheckBox!
    
    @IBOutlet weak var btnSnapToWindows: CheckBox!
    
    @IBOutlet weak var lblWindowGapCaption: NSTextField!
    @IBOutlet weak var lblWindowGap: NSTextField!
    @IBOutlet weak var gapStepper: NSStepper!
    
    @IBOutlet weak var btnSnapToScreen: CheckBox!
    
    private static let disabledControlTooltip: String = "<This preference is only applicable to the \"Modular\" app mode>"
    
    var preferencesView: NSView {self.view}
    
    let viewPrefs = preferences.viewPreferences
    
    func resetFields() {
        
        btnWindowMagnetism.onIf(viewPrefs.windowMagnetism.value)
        
        btnSnapToWindows.onIf(viewPrefs.snapToWindows.value)
        gapStepper.floatValue = viewPrefs.windowGap.value
        lblWindowGap.stringValue = ValueFormatter.formatPixels(gapStepper.floatValue)
        [lblWindowGap, gapStepper].forEach {$0!.enableIf(btnSnapToWindows.isOn)}
        
        btnSnapToScreen.onIf(viewPrefs.snapToScreen.value)
        
        if appModeManager.currentMode != .modular {
            disableIrrelevantControls()
        }
    }
    
    private func disableIrrelevantControls() {
        
        [btnSnapToWindows, gapStepper].forEach {
            
            $0?.toolTip = Self.disabledControlTooltip
            $0?.disable()
        }
        
        [lblWindowGapCaption, lblWindowGap].forEach {
            
            $0?.toolTip = Self.disabledControlTooltip
            $0?.textColor = .disabledControlTextColor
        }
    }
    
    @IBAction func snapToWindowsAction(_ sender: Any) {
        [lblWindowGap, gapStepper].forEach {$0!.enableIf(btnSnapToWindows.isOn)}
    }
    
    @IBAction func gapStepperAction(_ sender: Any) {
        lblWindowGap.stringValue = ValueFormatter.formatPixels(gapStepper.floatValue)
    }

    func save() throws {
        
        let oldMagnetismValue = viewPrefs.windowMagnetism.value
        viewPrefs.windowMagnetism.value = btnWindowMagnetism.isOn
        
        if viewPrefs.windowMagnetism.value != oldMagnetismValue {
            appModeManager.windowMagnetism = viewPrefs.windowMagnetism.value
        }
        
        viewPrefs.snapToWindows.value = btnSnapToWindows.isOn

        let oldWindowGap = viewPrefs.windowGap.value
        viewPrefs.windowGap.value = gapStepper.floatValue

        // Check if window gap was changed
        if gapStepper.floatValue != oldWindowGap {

            // Recompute system-defined layouts based on new gap between windows
            windowLayoutsManager.recomputeSystemDefinedLayouts()
        }
        
        viewPrefs.snapToScreen.value = btnSnapToScreen.isOn
    }
}
