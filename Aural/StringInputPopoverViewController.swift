/*
    View controller for the popover that lets the user save an Equalizer preset
 */
import Cocoa

class StringInputPopoverViewController: NSViewController, ModalComponentProtocol {
    
    // The actual popover that is shown
    private var popover: NSPopover!
    
    // Popover positioning parameters
    private let positioningRect = NSZeroRect
    
    // Input fields
    @IBOutlet weak var lblPrompt: NSTextField!
    @IBOutlet weak var inputField: ColoredCursorTextField!
    
    // Error message fields
    @IBOutlet weak var errorBox: NSBox!
    @IBOutlet weak var lblError: NSTextField!
    
    @IBOutlet weak var saveBtn: NSButton!
    @IBOutlet weak var cancelBtn: NSButton!
    
    @IBOutlet weak var saveBtnCell: StringInputPopoverResponseButtonCell!
    @IBOutlet weak var cancelBtnCell: StringInputPopoverResponseButtonCell!
    
    // A callback object so that the string input can be validated without this class knowing the logic for doing so
    private var client: StringInputClient!
    
    override var nibName: String? {return "StringInputPopover"}
    
    static func create(_ client: StringInputClient) -> StringInputPopoverViewController {
        
        let controller = StringInputPopoverViewController()
        controller.client = client
        
        let popover = NSPopover()
        popover.behavior = .semitransient
        popover.contentViewController = controller
        
        controller.popover = popover
        controller.registerAsModalComponent()
        
        return controller
    }
    
    private func registerAsModalComponent() {
        ObjectGraph.windowManager.registerModalComponent(self)
    }
    
    var isModal: Bool {
        return isShown
    }
    
    // Shows the popover
    func show(_ relativeToView: NSView, _ preferredEdge: NSRectEdge) {
        
        if !isShown {
            
            initFields()
            popover.show(relativeTo: positioningRect, of: relativeToView, preferredEdge: preferredEdge)
            initFields()
            
            errorBox.hide()
        }
    }
    
    private func initFields() {
        
        // TODO: Resize/realign fields and popover per input text length !!!
        let textSize = client.inputFontSize
        let font = Fonts.stringInputPopoverFont(textSize)
        lblPrompt?.font = font
        inputField?.font = font
        
        saveBtnCell?.textSize = textSize
        cancelBtnCell?.textSize = textSize
        
        saveBtn?.redraw()
        cancelBtn?.redraw()
        
        lblError?.font = Fonts.stringInputPopoverErrorFont(textSize)
        
        // Initialize the fields with information from the client
        lblPrompt?.stringValue = client.inputPrompt
        inputField?.stringValue = client.defaultValue ?? ""
        inputField?.currentEditor()?.selectedRange = NSMakeRange(0, 0)
    }
    
    // Closes the popover
    func close() {
        
        if isShown {
            popover.performClose(self)
        }
    }
    
    @IBAction func saveBtnAction(_ sender: Any) {
        
        // Validate input by calling back to the client
        let validation = client.validate(inputField.stringValue)
        
        if !validation.valid {
            
            lblError.stringValue = validation.errorMsg ?? ""
            errorBox.show()
            
        } else {
            
            client.acceptInput(inputField.stringValue)
            self.close()
        }
    }
    
    @IBAction func cancelBtnAction(_ sender: Any) {
        self.close()
    }
    
    var isShown: Bool {
        return popover.isShown
    }
}
