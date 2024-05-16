//
//  UnifiedPlayerWindowController.swift
//  Aural
//
//  Copyright © 2024 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//  

import Cocoa

class UnifiedPlayerWindowController: NSWindowController {
    
    override var windowNibName: NSNib.Name? {"UnifiedPlayerWindow"}
    
    @IBOutlet weak var logoImage: TintedImageView!
    @IBOutlet weak var rootContainerBox: NSBox!
    
    @IBOutlet weak var btnQuit: TintedImageButton!
    @IBOutlet weak var btnMinimize: TintedImageButton!
    @IBOutlet weak var btnToggleSidebar: TintedImageButton!
    @IBOutlet weak var presentationModeMenuItem: TintedIconMenuItem!
    @IBOutlet weak var settingsMenuIconItem: TintedIconMenuItem!
    
    @IBOutlet weak var rootSplitView: NSSplitView!
    @IBOutlet weak var browserSplitView: NSSplitView!
    
    // The tab group that switches between the 4 playlist views
    @IBOutlet weak var tabGroup: NSTabView!
    
    @IBOutlet weak var mainMenu: NSMenu!
    
    lazy var buttonColorChangeReceivers: [ColorSchemePropertyChangeReceiver] = [btnQuit, btnMinimize, presentationModeMenuItem, btnToggleSidebar, settingsMenuIconItem]
    
    lazy var playerController: UnifiedPlayerViewController = UnifiedPlayerViewController()
    private lazy var effectsSheetViewController: EffectsSheetViewController = .init()
    
    private lazy var sidebarController: UnifiedPlayerSidebarViewController = UnifiedPlayerSidebarViewController()
    
    private lazy var playQueueController: PlayQueueContainerViewController = .init()
    private lazy var chaptersListController: ChaptersListViewController = .init()
    
//    private lazy var libraryTracksController: LibraryTracksViewController = LibraryTracksViewController()
//    private lazy var libraryArtistsController: LibraryArtistsViewController = LibraryArtistsViewController()
//    private lazy var libraryAlbumsController: LibraryAlbumsViewController = LibraryAlbumsViewController()
//    private lazy var libraryGenresController: LibraryGenresViewController = LibraryGenresViewController()
//    private lazy var libraryDecadesController: LibraryDecadesViewController = LibraryDecadesViewController()
//    
//    private lazy var tuneBrowserViewController: TuneBrowserViewController = TuneBrowserViewController()
//    
//    private lazy var playlistsViewController: PlaylistsViewController = PlaylistsViewController()
    
    lazy var messenger: Messenger = Messenger(for: self)
    
    var eventMonitor: EventMonitor! = EventMonitor()
    
    var gesturesPreferences: GesturesControlsPreferences {preferences.controlsPreferences.gestures}
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        NSApp.mainMenu = self.mainMenu
    }
    
    // One-time setup
    override func windowDidLoad() {
        
        // TODO: Clean this up
        theWindow.setIsVisible(false)
        initWindow()
        theWindow.setIsVisible(false)
        
        theWindow.delegate = self
        
        setUpEventHandling()
        initSubscriptions()
        
        super.windowDidLoad()
        
        messenger.subscribe(to: .UnifiedPlayer.showModule, handler: showModule(forItem:))
        messenger.subscribe(to: .UnifiedPlayer.hideModule, handler: hideModule(forItem:))
        
        messenger.subscribe(to: .PlayQueue.viewChaptersList, handler: viewChaptersList)
        messenger.subscribe(to: .Player.trackTransitioned, handler: trackTransitioned(_:))
        
        messenger.subscribe(to: .Application.willExit, handler: preApplicationExit)
        
        colorSchemesManager.registerSchemeObserver(self)
        colorSchemesManager.registerPropertyObserver(self, forProperty: \.captionTextColor, changeReceiver: logoImage)
        colorSchemesManager.registerPropertyObserver(self, forProperty: \.backgroundColor, changeReceiver: rootContainerBox)
        colorSchemesManager.registerPropertyObserver(self, forProperty: \.buttonColor, changeReceivers: buttonColorChangeReceivers)
    }
    
    // Set window properties
    private func initWindow() {
        
        theWindow.makeKeyAndOrderFront(self)
        
        changeWindowCornerRadius(playerUIState.cornerRadius)
        playerController.forceLoadingOfView()
        
        rootSplitView.addAndAnchorSubView(playerController.view, underArrangedSubviewAt: 0)
        browserSplitView.addAndAnchorSubView(sidebarController.view, underArrangedSubviewAt: 0)
        browserSplitView.delegate = self
        browserSplitView.subviews.first?.showIf(unifiedPlayerUIState.isSidebarShown)
        
        tabGroup.addAndAnchorSubView(forController: playQueueController)
//        tabGroup.addAndAnchorSubView(forController: libraryTracksController)
//        tabGroup.addAndAnchorSubView(forController: libraryArtistsController)
//        tabGroup.addAndAnchorSubView(forController: libraryAlbumsController)
//        tabGroup.addAndAnchorSubView(forController: libraryGenresController)
//        tabGroup.addAndAnchorSubView(forController: libraryDecadesController)
//
//        tabGroup.addAndAnchorSubView(forController: tuneBrowserViewController)
//
//        tabGroup.addAndAnchorSubView(forController: playlistsViewController)
        
        tabGroup.selectTabViewItem(at: 0)
    }
    
    private func initSubscriptions() {
        messenger.subscribe(to: .Player.UI.changeCornerRadius, handler: changeWindowCornerRadius(_:))
    }
    
    override func destroy() {
        
        close()
        
        eventMonitor.stopMonitoring()
        eventMonitor = nil
        
//        [playerController, sidebarController, playQueueController, libraryTracksController, libraryArtistsController, libraryAlbumsController, libraryGenresController, libraryDecadesController, tuneBrowserViewController, playlistsViewController].forEach {$0.destroy()}
        
        [playerController, sidebarController, playQueueController].forEach {$0.destroy()}
        
        messenger.unsubscribeFromAll()
    }
    
    // MARK: Actions -----------------------------------------------------------
    
    // Quits the app
    @IBAction func quitAction(_ sender: AnyObject) {
        
        preApplicationExit()
        NSApp.terminate(self)
    }
    
    private func preApplicationExit() {
        unifiedPlayerUIState.windowFrame = theWindow.frame
    }
    
    // Minimizes the window (and any child windows)
    @IBAction func minimizeAction(_ sender: AnyObject) {
        theWindow.miniaturize(self)
    }
    
    @IBAction func modularModeAction(_ sender: AnyObject) {
        appModeManager.presentMode(.modular)
    }
    
    @IBAction func compactModeAction(_ sender: AnyObject) {
        appModeManager.presentMode(.compact)
    }
    
    @IBAction func menuBarModeAction(_ sender: AnyObject) {
        appModeManager.presentMode(.menuBar)
    }
    
    @IBAction func widgetModeAction(_ sender: AnyObject) {
        appModeManager.presentMode(.widget)
    }
    
    @IBAction func showEffectsPanelAction(_ sender: AnyObject) {
        playerController.presentAsSheet(effectsSheetViewController)
    }
    
    @IBAction func toggleSidebarAction(_ sender: AnyObject) {
        
        unifiedPlayerUIState.isSidebarShown.toggle()
        browserSplitView.subviews.first?.showIf(unifiedPlayerUIState.isSidebarShown)
    }
    
    // MARK: Message handling -----------------------------------------------------------
    
    func changeWindowCornerRadius(_ radius: CGFloat) {
        rootContainerBox.cornerRadius = radius
    }
    
    private func showModule(forItem item: UnifiedPlayerSidebarItem) {
        
////        if tab == .playlists {
////            messenger.publish(.playlists_showPlaylist, payload: item.displayName)
////            
////        } else if tab == .fileSystem,
////                  let folder = item.tuneBrowserFolder, let tree = item.tuneBrowserTree {
////                       
////                   tuneBrowserViewController.showFolder(folder, inTree: tree, updateHistory: true)
////               }

        switch item.module {
            
        case .playQueue:
            
            tabGroup.selectTabViewItem(at: 0)
            
        case .chaptersList:
            
            tabGroup.selectLastTabViewItem(self)
            
        default:
            
            return
        }
    }
    
    private func hideModule(forItem item: UnifiedPlayerSidebarItem) {
        
        switch item.module {
            
        case .chaptersList:
            
            closeChaptersList()
            
        default:
            
            return
        }
    }
    
    private func viewChaptersList() {
        
        if tabGroup.tabViewItems.count == 1 {
            tabGroup.addAndAnchorSubView(forController: chaptersListController)
        }
        
        tabGroup.selectLastTabViewItem(self)
    }
    
    private func closeChaptersList() {
        
        if tabGroup.tabViewItems.count > 1 {
            tabGroup.tabViewItems.removeLast()
        }
    }
    
    func trackTransitioned(_ notif: TrackTransitionNotification) {
        
        if let newTrack = notif.endTrack {
            
            if newTrack.hasChapters, preferences.playQueuePreferences.showChaptersList.value {
                viewChaptersList()
                
            } else {
                closeChaptersList()
            }
            
        } else {
            closeChaptersList()
        }
    }
}

extension UnifiedPlayerWindowController: NSSplitViewDelegate {
    
    func splitView(_ splitView: NSSplitView, shouldHideDividerAt dividerIndex: Int) -> Bool {
        !unifiedPlayerUIState.isSidebarShown
    }
}

extension UnifiedPlayerWindowController: ColorSchemeObserver {
    
    func colorSchemeChanged() {
        
        logoImage.colorChanged(systemColorScheme.captionTextColor)
        
        rootContainerBox.fillColor = systemColorScheme.backgroundColor
        
        buttonColorChangeReceivers.forEach {
            $0.colorChanged(systemColorScheme.buttonColor)
        }
    }
}

extension UnifiedPlayerWindowController: NSWindowDelegate {
    
    func windowDidResize(_ notification: Notification) {
        playerController.windowResized()
    }
}
