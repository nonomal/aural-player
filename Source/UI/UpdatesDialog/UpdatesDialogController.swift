//
//  UpdatesDialogController.swift
//  Aural
//
//  Copyright © 2025 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import Cocoa

class UpdatesDialogController: NSWindowController, ModalComponentProtocol {
    
    override var windowNibName: NSNib.Name? {"UpdatesDialog"}

    @IBOutlet weak var lblNoUpdates: NSTextField!
    @IBOutlet weak var lblUpdateAvailable: NSTextField!
    @IBOutlet weak var lblError: NSTextField!
    
    @IBOutlet weak var btnOK: NSButton!
    @IBOutlet weak var btnGetLatestVersion: NSButton!
    
    @IBOutlet weak var spinner: NSProgressIndicator!
    
    private lazy var workspace: NSWorkspace = NSWorkspace.shared
    private let latestReleaseURL: URL = URL(string: "https://github.com/maculateConception/aural-player/releases/latest")!
    
    override func showWindow(_ sender: Any?) {
        
        forceLoadingOfWindow()
        
        spinner?.animate()
        
        [lblNoUpdates, lblUpdateAvailable, lblError].forEach {$0?.hide()}
        
        // TODO: Move the centering logic to layouts manager so that 'mainWindow' doesn't have to be exposed.
        if let mainWindow = appModeManager.mainWindow {
            theWindow.showCentered(relativeTo: mainWindow)
        }
    }
    
    var isModal: Bool {self.window?.isVisible ?? false}
    
    @IBAction func okAction(_ sender: Any) {
        window?.close()
    }
    
    @IBAction func getLatestVersionAction(_ sender: Any) {
        
        window?.close()
        workspace.open(latestReleaseURL)
    }
    
    func noUpdatesAvailable() {
        
        spinner.dismiss()
        
        lblNoUpdates.show()
        
        lblUpdateAvailable.hide()
        lblError.hide()
        btnGetLatestVersion.hide()
    }
    
    func updateIsAvailable(version: AppVersion) {
        
        spinner.dismiss()
        
        lblNoUpdates.hide()
        lblError.hide()
        
        lblUpdateAvailable.stringValue = "Update: Version \(version.versionString) is available !"
        lblUpdateAvailable.show()
        btnGetLatestVersion.show()
    }
    
    func showError() {
        
        spinner.dismiss()
        
        lblError.show()
        
        lblNoUpdates.hide()
        lblUpdateAvailable.hide()
        btnGetLatestVersion.hide()
    }
}
