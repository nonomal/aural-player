import Cocoa

/*
    Controller for the color scheme editor panel that allows the current system color scheme to be edited.
 */
class FontSetsWindowController: NSWindowController, ModalDialogDelegate {
    
    @IBOutlet weak var tabView: AuralTabView!
    
    @IBOutlet weak var btnSave: NSButton!
    
    private lazy var generalView: FontSetsViewProtocol = GeneralFontSetViewController()
    private lazy var playerView: FontSetsViewProtocol = PlayerFontSetViewController()
    private lazy var playlistView: FontSetsViewProtocol = PlaylistFontSetViewController()
    private lazy var effectsView: FontSetsViewProtocol = EffectsFontSetViewController()
    
    private var subViews: [FontSetsViewProtocol] = []
    
    override var windowNibName: NSNib.Name? {return "FontSets"}
    
    var isModal: Bool {
        return self.window?.isVisible ?? false
    }
    
    override func windowDidLoad() {

        self.window?.isMovableByWindowBackground = true

        // Add the subviews to the tab group
        subViews = [generalView, playerView, playlistView, effectsView]
        tabView.addViewsForTabs(subViews.map {$0.fontSetsView})

        // Register self as a modal component
        WindowManager.registerModalComponent(self)
    }
    
    func showDialog() -> ModalDialogResponse {
        
        // Force loading of the window if it hasn't been loaded yet (only once)
        if !self.isWindowLoaded {
            _ = self.window!
        }
        
        subViews.forEach {$0.resetFields(FontSets.systemFontSet)}
        
        // Reset the subviews according to the current system color scheme, and show the first tab
        tabView.selectTabViewItem(at: 0)
        
        UIUtils.showDialog(self.window!)
        
        return .ok
    }
    
    @IBAction func applyChangesAction(_ sender: Any) {
        
        let context = FontSetChangeContext()
        generalView.applyFontSet(context, to: FontSets.systemFontSet)
        
        [playerView, playlistView, effectsView].forEach {$0.applyFontSet(context, to: FontSets.systemFontSet)}
        Messenger.publish(.applyFontSet, payload: FontSets.systemFontSet)
    }
    
    // Dismisses the panel when the user is done making changes
    @IBAction func doneAction(_ sender: Any) {
        
        // Close the system color chooser panel.
        NSColorPanel.shared.close()
        UIUtils.dismissDialog(self.window!)
    }
}

/*
    Contract for all subviews that alter the color scheme, to facilitate communication between the window controller and subviews.
 */
protocol FontSetsViewProtocol {
    
    // The view containing the color editing UI components
    var fontSetsView: NSView {get}
    
    // Reset all UI controls every time the dialog is shown or a new color scheme is applied.
    // NOTE - the history and clipboard are shared across all views
    func resetFields(_ fontSet: FontSet)
    
    func applyFontSet(_ context: FontSetChangeContext, to fontSet: FontSet)
}
