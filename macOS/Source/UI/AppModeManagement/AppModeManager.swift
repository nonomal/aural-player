//
//  AppModeManager.swift
//  Aural
//
//  Copyright © 2024 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import Cocoa

///
/// Switches between application user interface modes.
///
class AppModeManager {
    
    var currentMode: AppMode? = nil
    
    var mainWindow: NSWindow? {
        modeController?.mainWindow
    }
    
    private var modeController: AppModeController? {
        
        guard let currentMode = self.currentMode else {return nil}
        
        switch currentMode {
        
        case .modular:
            return modularMode
            
        case .unified:
            return unifiedMode
        
        case .menuBar:
            return menuBarMode
            
        case .widget:
            return widgetMode
            
        case .compact:
            return compactMode
        }
    }
    
    private lazy var modularMode: ModularAppModeController = ModularAppModeController()
    
    private lazy var unifiedMode: UnifiedAppModeController = UnifiedAppModeController()
    
    private lazy var menuBarMode: MenuBarAppModeController = MenuBarAppModeController()
    
    private lazy var widgetMode: WidgetAppModeController = WidgetAppModeController()
    
    private lazy var compactMode: CompactAppModeController = CompactAppModeController()
    
    private let preferences: ViewPreferences
    private let lastPresentedAppMode: AppMode?
    
    private lazy var messenger = Messenger(for: self)
    
    init(persistentState: UIPersistentState?, preferences: ViewPreferences) {
        
        self.lastPresentedAppMode = persistentState?.appMode
        self.preferences = preferences
    }
    
    func presentApp() {
        
//        if appSetup.setupCompleted {
//            presentMode(appSetup.presentationMode)
//            
//        } else {
//
//            // Remember app mode from last app launch.
//            presentMode(lastPresentedAppMode ?? .defaultMode)
//        }
        
        presentMode(.unified)
//        presentMode(.modular)
//        presentMode(.compact)
    }
    
    func presentMode(_ newMode: AppMode) {
        
        dismissCurrentMode()
        currentMode = newMode
        modeController?.presentMode(transitioningFromMode: currentMode)
    }
    
    private func dismissCurrentMode() {
        
        guard let _ = self.currentMode else {return}
        
        modeController?.dismissMode()
        colorSchemesManager.stopObserving()
        fontSchemesManager.stopObserving()
    }
}
