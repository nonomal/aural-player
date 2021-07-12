//
//  MenuBarAppModeController.swift
//  Aural
//
//  Copyright © 2021 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import Cocoa

class MenuBarAppModeController: NSObject, AppModeController, NSMenuDelegate {

    var mode: AppMode {.menuBar}

    private var statusItem: NSStatusItem?
    private var controller: MenuBarPlayerViewController!
    
    private lazy var appIcon: NSImage = NSImage(named: "AppIcon-MenuBar")!
    
    func presentMode(transitioningFromMode previousMode: AppMode) {
        
        controller = MenuBarPlayerViewController()

        // Make app run in menu bar and make it active.
        NSApp.setActivationPolicy(.accessory)
        NSApp.activate(ignoringOtherApps: true)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.image = appIcon
        
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString", String.self] {
            statusItem?.button?.toolTip = "Aural Player v\(appVersion)"
        } else {
            statusItem?.button?.toolTip = "Aural Player"
        }
        
        let menu = NSMenu()
        
        let menuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        menuItem.view = controller.view
        
        menu.addItem(menuItem)
        menu.delegate = self
        
        statusItem?.menu = menu
    }
    
    func menuDidClose(_ menu: NSMenu) {
        controller?.menuBarMenuClosed()
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        controller.menuBarMenuOpened()
    }
    
    func dismissMode() {
        
        controller?.destroy()
     
        if let statusItem = self.statusItem {
            
            statusItem.menu?.cancelTracking()
            statusItem.menu = nil
            
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
        
        controller = nil
    }
}
