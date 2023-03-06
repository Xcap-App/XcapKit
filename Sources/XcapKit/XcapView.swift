//
//  XcapView.swift
//  
//
//  Created by scchn on 2022/11/3.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

import AVFoundation.AVUtilities

public protocol XcapViewDelegate: AnyObject {
    // ----- Drawing Session -----
    func xcapView(_ xcapView: XcapView, didStartDrawingSessionWithObject object: ObjectRenderer)
    func xcapView(_ xcapView: XcapView, shouldDiscardObject object: ObjectRenderer) -> Bool
    func xcapView(_ xcapView: XcapView, didFinishDrawingSessionWithObject object: ObjectRenderer)
    func xcapViewDidCancelDrawingSession(_ xcapView: XcapView)
    // ----- Selection -----
    func xcapView(_ xcapView: XcapView, shouldSelectObject object: ObjectRenderer) -> Bool
    func xcapView(_ xcapView: XcapView, didSelectObjects objects: [ObjectRenderer])
    func xcapView(_ xcapView: XcapView, didDeselectObjects objects: [ObjectRenderer])
    // ----- Edit -----
    func xcapView(_ xcapView: XcapView, didEditObject object: ObjectRenderer, at position: ObjectLayout.Position)
    // ----- Move -----
    func xcapView(_ xcapView: XcapView, didMoveObjects objects: [ObjectRenderer])
    // ----- Menu (macOS) -----
    #if os(macOS)
    func xcapView(_ xcapView: XcapView, menuForObject object: ObjectRenderer?) -> NSMenu?
    #endif
}

extension XcapViewDelegate {
    // ----- Drawing Session -----
    public func xcapView(_ xcapView: XcapView, didStartDrawingSessionWithObject object: ObjectRenderer) {}
    public func xcapView(_ xcapView: XcapView, shouldDiscardObject object: ObjectRenderer) -> Bool { false }
    public func xcapView(_ xcapView: XcapView, didFinishDrawingSessionWithObject object: ObjectRenderer) {}
    public func xcapViewDidCancelDrawingSession(_ xcapView: XcapView) {}
    // ----- Selection -----
    public func xcapView(_ xcapView: XcapView, shouldSelectObject object: ObjectRenderer) -> Bool { true }
    public func xcapView(_ xcapView: XcapView, didSelectObjects objects: [ObjectRenderer]) {}
    public func xcapView(_ xcapView: XcapView, didDeselectObjects objects: [ObjectRenderer]) {}
    // ----- Edit -----
    public func xcapView(_ xcapView: XcapView, didEditObject object: ObjectRenderer, at position: ObjectLayout.Position) {}
    // ----- Move -----
    public func xcapView(_ xcapView: XcapView, didMoveObjects objects: [ObjectRenderer]) {}
    // ----- Menu (macOS) -----
    #if os(macOS)
    public func xcapView(_ xcapView: XcapView, menuForObject object: ObjectRenderer?) -> NSMenu? { nil }
    #endif
}

extension XcapView {
    
    // ----- Private -----
    
    private enum InternalState {
        case idle
        
        case selecting(rect: CGRect, initialSelection: [ObjectRenderer])
        
        case onItem(object: ObjectRenderer, position: ObjectLayout.Position, initialLocation: CGPoint)
        case onObject(object: ObjectRenderer, alreadySelected: Bool, initialLocation: CGPoint)
        
        case editing(object: ObjectRenderer, position: ObjectLayout.Position, lastLocation: CGPoint, initialLocation: CGPoint)
        case moving(object: ObjectRenderer, lastLocation: CGPoint, initialLocation: CGPoint)
        case drawing(object: ObjectRenderer, state: DrawingSessionState)
        case plugin(plugin: Plugin, state: Plugin.State, lastLocation: CGPoint, initialLocation: CGPoint)
    }
    
    private enum ObjectDecoration {
        case none
        case withItems(Editable, highlightedPosition: ObjectLayout.Position?)
        case withBoundingBox(ObjectRenderer, highlighted: Bool)
    }
    
    // ----- Public -----
    
    public enum DrawingSessionState {
        case idle
        case pressing
        case moving
        /// macOS Only
        case tracking
    }
    
    public enum State {
        case idle
        case selecting
        case onItem(object: ObjectRenderer, position: ObjectLayout.Position)
        case onObject(ObjectRenderer)
        case editing(object: ObjectRenderer, position: ObjectLayout.Position)
        case moving([ObjectRenderer])
        case drawing(object: ObjectRenderer, sessionState: DrawingSessionState)
        case plugin(Plugin)
    }
    
    public enum ImplicitUndoAction {
        case addObjects
        case removeObjects
        case dragging
        case editing
    }
    
}

open class XcapView: PlatformView, SettingMonitor {
    
    #if os(macOS)
    private var trackingArea: NSTrackingArea?
    #endif
    
    private var internalState = InternalState.idle {
        didSet {
            if case .drawing(let object, _) = internalState {
                if object !== currentObject {
                    currentObject = object
                }
            } else if currentObject != nil {
                currentObject = nil
            }
        }
    }
    
    private var isBidirectionalSelectionEnabled: Bool = false
    
    // MARK: - Data
    
    open private(set) var contentScaleFactors: (toContent: CGPoint, toView: CGPoint) = (.zero, .zero)
    
    @objc dynamic open private(set) var contentRect = CGRect.zero
    
    @objc dynamic open private(set) var objects: [ObjectRenderer] = []
    
    @objc dynamic open private(set) var selectedObjects: [ObjectRenderer] = []
    
    @objc dynamic open private(set) var currentObject: ObjectRenderer? = nil
    
    /// Do NOT modify object during drawing session.
    open var state: State {
        getState()
    }
    
    // MARK: - Settings
    
    open weak var delegate: XcapViewDelegate?
    
    // ----- Content Settings -----
    
    @objc dynamic open var contentSize = CGSize.zero {
        didSet { contentSizeDidChange(oldValue) }
    }
    
    @Setting open var contentBackgroundColor: PlatformColor?
    
    // ----- Selection Settings -----
    
    @Setting open var selectionRange: CGFloat = 10 {
        didSet { updateContentInfo() }
    }
    
    @Setting open var selectionRectCornerRadius: CGFloat = 0
    
    @Setting open var selectionRectBorderColor: PlatformColor = .lightGray
    
    @Setting open var selectionRectFillColor: PlatformColor = .cyan.withAlphaComponent(0.2)
    
    // ----- Drawing Session Settings -----
    
    @Setting open var drawingSessionLineWidth: CGFloat = 1
    
    @Setting open var drawingSessionStrokeColor: PlatformColor = .black
    
    @Setting open var drawingSessionFillColor: PlatformColor = .white
    
    // ----- Object Item Settings -----
    
    @Setting open var objectItemBorderColor: PlatformColor = .black
    
    @Setting open var objectItemFillColor: PlatformColor = .white
    
    @Setting open var objectItemHighlightBorderColor: PlatformColor = .black
    
    @Setting open var objectItemHighlightFillColor: PlatformColor = {
        #if os(macOS)
        return .controlAccentColor
        #else
        return .init(named: "AccentColor") ?? .systemBlue
        #endif
    }()
    
    // ----- Object Bounding Box Settings -----
    
    @Setting open var objectBoundingBoxCornerRadius: CGFloat = 4
    
    @Setting open var objectBoundingBoxBorderColor: PlatformColor = .black
    
    @Setting open var objectBoundingBoxFillColor: PlatformColor = .clear
    
    @Setting open var objectBoundingBoxHighlightBorderColor: PlatformColor = .black
    
    @Setting open var objectBoundingBoxHighlightFillColor: PlatformColor = .cyan.withAlphaComponent(0.3)
    
    // ----- Undo Settings -----
    
    open var implicitUndoActionNames: [ImplicitUndoAction: String] = [:]
    
    // ----- Plugin Settings -----
    
    open private(set) var plugins: [Plugin] = []
    
    // ----- Overrides -----
    
    #if os(macOS)
    open override var acceptsFirstResponder: Bool {
        true
    }
    #endif
    
    // MARK: - Life Cycle
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        undoManager?.removeAllActions(withTarget: self)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    public override init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        
        commonInit()
    }
    
    private func commonInit() {
        setupNotification()
        
        registerSettings { [weak self] in
            self?.redraw()
        }
    }
    
    #if os(macOS)
    open override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }
        
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeInKeyWindow, .mouseMoved],
            owner: self
        )
        
        addTrackingArea(trackingArea)
        
        self.trackingArea = trackingArea
    }
    #endif
    
    #if os(macOS)
    open override func flagsChanged(with event: NSEvent) {
        super.flagsChanged(with: event)
        
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        
        isBidirectionalSelectionEnabled = flags == .command
    }
    #endif
    
    #if !os(macOS)
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        updateContentInfo()
    }
    #endif
    
    private func contentSizeDidChange(_ oldContentSize: CGSize) {
        assertNonZeroContentSize()
        
        guard contentSize != oldContentSize else {
            return
        }
        
        let scaleFactos = calcScaleFactor(from: oldContentSize, to: contentSize)
        
        currentObject?.scale(x: scaleFactos.x, y: scaleFactos.y)
        
        for object in objects {
            object.scale(x: scaleFactos.x, y: scaleFactos.y)
        }
        
        updateContentInfo()
    }
    
    // MARK: - Notification
    
    private func setupNotification() {
        #if os(macOS)
        let center = NotificationCenter.default
        
        center.addObserver(
            self,
            selector: #selector(self.frameDidChange(_:)),
            name: NSView.frameDidChangeNotification,
            object: self
        )
        
        center.addObserver(
            self,
            selector: #selector(self.windowDidResignKey(_:)),
            name: NSWindow.didResignKeyNotification,
            object: nil
        )
        #endif
    }
    
    #if os(macOS)
    @objc private func frameDidChange(_ notification: Notification) {
        updateContentInfo()
    }
    #endif
    
    #if os(macOS)
    @objc private func windowDidResignKey(_ notification: Notification) {
        guard (notification.object as? NSWindow) == window else {
            return
        }
        isBidirectionalSelectionEnabled = false
    }
    #endif
    
    // MARK: - Utils
    
    private func getState() -> State {
        switch internalState {
        case .idle:
            return .idle
        case .selecting:
            return .selecting
        case let .onItem(object, position, _):
            return .onItem(object: object, position: position)
        case let .onObject(object, _, _):
            return .onObject(object)
        case let .editing(object, position, _, _):
            return .editing(object: object, position: position)
        case .moving:
            return .moving(selectedObjects)
        case let .drawing(object, state):
            return .drawing(object: object, sessionState: state)
        case let .plugin(plugin, _, _, _):
            return .plugin(plugin)
        }
    }
    
    private func validateContentSize() -> Bool {
        contentSize.width > 0 && contentSize.height > 0
    }
    
    private func assertNonZeroContentSize() {
        assert(validateContentSize(), "⚠️ Content size must be greater than zero.")
    }
    
    private func calcScaleFactor(from: CGSize, to: CGSize) -> CGPoint {
        CGPoint(x: to.width / from.width, y: to.height / from.height)
    }
    
    private func updateContentInfo() {
        guard validateContentSize() else {
            return
        }
        
        let newContentRect = AVMakeRect(aspectRatio: contentSize, insideRect: bounds)
        let toScaleFactor = calcScaleFactor(from: newContentRect.size, to: contentSize)
        let fromScaleFactor = CGPoint(x: 1 / toScaleFactor.x, y: 1 / toScaleFactor.y)
        
        contentRect = newContentRect
        contentScaleFactors = (toScaleFactor, fromScaleFactor)
        
        redraw()
    }
    
    private func convertLocation(fromViewToContent location: CGPoint) -> CGPoint {
        let translate = CGAffineTransform.identity
            .translatedBy(x: -contentRect.origin.x, y: -contentRect.origin.y)
        let scale = CGAffineTransform.identity
            .scaledBy(x: contentScaleFactors.toContent.x, y: contentScaleFactors.toContent.y)
        return location
            .applying(translate)
            .applying(scale)
    }
    
    // MARK: - Object Finder
    
    private func findObject(at location: CGPoint) -> ObjectRenderer? {
        let selectedObjects = selectedObjects
            .reversed()
        let others = objects
            .filter { object in
                !selectedObjects.contains(object)
            }
            .reversed()
        let allObjects = Array(selectedObjects) + Array(others)
        let convertedSelectionRange = selectionRange * contentScaleFactors.toContent.x
        
        for object in allObjects {
            if object.selectionTest(point: location, range: convertedSelectionRange) {
                return object
            }
        }
        return nil
    }
    
    private func findEditableObject(at location: CGPoint) -> (object: Editable, ObjectLayout.Position)? {
        let convertedSelectionRange = selectionRange * contentScaleFactors.toContent.x
        
        for object in selectedObjects.reversed() {
            guard let object = object as? Editable else {
                continue
            }
            
            for (i, items) in object.layout.reversed().enumerated() {
                for (j, item) in items.reversed().enumerated() {
                    let position = ObjectLayout.Position(
                        item: items.count - j - 1,
                        section: object.layout.count - i - 1
                    )
                    let rangeCircle = Circle(center: item, radius: convertedSelectionRange)
                    
                    if rangeCircle.contains(location) && object.canEditItem(at: position) {
                        return (object, position)
                    }
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Plugin Utils
    
    private func findPlugin(for priority: Plugin.PluginType, at location: CGPoint) -> Plugin? {
        plugins.reversed()
            .first { plugin in
                guard plugin.pluginType == priority, plugin.isEnabled else {
                    return false
                }
                return plugin.shouldBegin(in: self, location: location)
            }
    }
    
    /// Add plugin.
    ///
    /// - Parameters:
    ///     - plugin: Must be subclass of `Plugin`.
    open func installPlugin(_ plugin: Plugin) {
        guard !plugins.contains(plugin) else {
            return
        }
        
        plugins.append(plugin)
        
        plugin.redrawHandler = { [weak self] in
            self?.redraw()
        }
        plugin.undoManager = undoManager
        
        plugin.pluginWasInstalled(in: self)
        
        redraw()
    }
    
    /// Removes the given plugin and the related undo actions.
    open func removePlugin(_ plugin: Plugin) {
        guard let index = plugins.firstIndex(of: plugin) else {
            return
        }
        
        let plugin = plugins.remove(at: index)
        
        if let undoManager = plugin.undoManager {
            undoManager.removeAllActions(withTarget: plugin)
        }
        
        plugin.redrawHandler = nil
        plugin.undoManager = nil
        
        redraw()
    }
    
    // MARK: - Platform Touch Events
    
    #if os(macOS)
    open override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        
        let location = convert(event.locationInWindow, from: nil)
        
        pointerDidBegin(at: location)
    }
    #else
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard touches.count == 1, let location = touches.first?.location(in: self) else {
            return
        }
        
        pointerDidBegin(at: location)
    }
    #endif
    
    #if os(macOS)
    open override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        
        let location = convert(event.locationInWindow, from: nil)
        
        pointerDidMove(to: location)
    }
    #else
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        guard let location = touches.first?.location(in: self) else {
            return
        }
        
        pointerDidMove(to: location)
    }
    #endif
    
    #if os(macOS)
    open override func mouseMoved(with event: NSEvent) {
        super.mouseDragged(with: event)
        
        let location = convert(event.locationInWindow, from: nil)
        
        pointerDidTrack(location)
    }
    #endif
    
    #if os(macOS)
    open override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        
        let location = convert(event.locationInWindow, from: nil)
        
        pointerDidEnd(at: location)
    }
    #else
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        guard let location = touches.first?.location(in: self) else {
            return
        }
        
        pointerDidEnd(at: location)
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        guard let location = touches.first?.location(in: self) else {
            return
        }
        
        pointerDidEnd(at: location)
    }
    #endif
    
    #if os(macOS)
    open override func rightMouseUp(with event: NSEvent) {
        super.rightMouseUp(with: event)
        
        if event.clickCount == 1, case .drawing = internalState {
            finishDrawingSession()
        }
    }
    
    open override func menu(for event: NSEvent) -> NSMenu? {
        guard window?.isKeyWindow == true,
              event.type == .rightMouseDown,
              case .idle = internalState
        else {
            return super.menu(for: event)
        }
        
        let originalLocation = convert(event.locationInWindow, from: nil)
        
        guard contentRect.contains(originalLocation) else {
            return super.menu(for: event)
        }
        
        let convertedLocation = convertLocation(fromViewToContent: originalLocation)
        let object = findObject(at: convertedLocation)
        
        if let object = object {
            if !selectedObjects.contains(object) {
                internalSelectObjects([object])
            }
        } else {
            internalSelectObjects([])
        }
        
        redraw()
        
        return delegate?.xcapView(self, menuForObject: object) ?? super.menu(for: event)
    }
    #endif
    
    // MARK: - Add
    
    private func prepareObject(_ object: ObjectRenderer) {
        object.redrawHandler = { [weak self] in
            self?.redraw()
        }
        object.undoManager = undoManager
        object.markAsFinished()
    }
    
    /// No Redraw
    private func internalAddObjects(_ newObjects: [ObjectRenderer]) {
        for object in newObjects {
            prepareObject(object)
        }
        
        objects.append(contentsOf: newObjects)
        
        registerUndoAddObjects(newObjects)
    }
    
    open func canAddObject(_ newObject: ObjectRenderer) -> Bool {
        (newObject.isFinished || newObject.canFinish()) &&
        !newObject.layout.isEmpty &&
        !objects.contains(newObject)
    }
    
    open func addObjects(_ newObjects: [ObjectRenderer]) {
        assertNonZeroContentSize()
        
        let newObjects = newObjects.filter(canAddObject(_:))
        
        internalAddObjects(newObjects)
        
        redraw()
    }
    
    // MARK: - Remove
    
    /// No Redraw
    private func internalRemoveObjects(_ objectsToRemove: [ObjectRenderer]) {
        var newObjects = objects
        var removedSelection: [ObjectRenderer] = []
        
        registerUndoRemoveObjects(objectsToRemove, originalObjects: objects, contentSize: contentSize)
        
        for object in objectsToRemove {
            guard let index = newObjects.firstIndex(of: object) else {
                continue
            }
            
            let object = newObjects.remove(at: index)
            
            object.redrawHandler = nil
            object.undoManager = nil
            
            if let index = selectedObjects.firstIndex(of: object) {
                removedSelection += [selectedObjects.remove(at: index)]
            }
        }
        
        if !removedSelection.isEmpty {
            delegate?.xcapView(self, didDeselectObjects: removedSelection)
        }
        
        objects = newObjects
    }
    
    open func removeObjects(_ objectToRemove: [ObjectRenderer]) {
        let objectToRemove = objectToRemove
            .filter(objects.contains(_:))
        internalRemoveObjects(objectToRemove)
        redraw()
    }
    
    open func removeSelectedObjects() {
        internalRemoveObjects(selectedObjects)
        redraw()
    }
    
    open func removeAllObjects() {
        internalRemoveObjects(objects)
        redraw()
    }
    
    // MARK: - Select
    
    /// No Redraw
    private func internalSelectObjects(_ objects: [ObjectRenderer], byExtendingSelection extends: Bool = false) {
        let newSelection = objects.filter { object in
            let isSelectable = delegate?.xcapView(self, shouldSelectObject: object) ?? true
            return isSelectable && !selectedObjects.contains(object)
        }
        let removedSelection: [ObjectRenderer] = {
            guard !extends else {
                return []
            }
            return selectedObjects
                .filter { !objects.contains($0) }
        }()
        
        if !removedSelection.isEmpty {
            selectedObjects.removeAll(where: removedSelection.contains)
            
            delegate?.xcapView(self, didDeselectObjects: removedSelection)
        }
        
        if !newSelection.isEmpty {
            selectedObjects.append(contentsOf: newSelection)
            
            delegate?.xcapView(self, didSelectObjects: newSelection)
        }
    }
    
    open func selectObjects(_ objectsToSelect: [ObjectRenderer], byExtendingSelection extends: Bool = false) {
        let objectsToSelect = objectsToSelect
            .filter(objects.contains(_:))
        
        internalSelectObjects(objectsToSelect, byExtendingSelection: extends)
        redraw()
    }
    
    open func selectAllObjects() {
        selectObjects(objects)
    }
    
    open func deselectObjects(_ objectArray: [ObjectRenderer]) {
        let filteredObjects = selectedObjects
            .filter { !objectArray.contains($0) }
        
        internalSelectObjects(filteredObjects)
        redraw()
    }
    
    open func deselectAllObjects() {
        internalSelectObjects([])
        redraw()
    }
    
    // MARK: - Drawing Session
    
    /**
     Start drawing session.
     
     - Parameters:
        - type: Must be type of subclass of `ObjectRenderer`.
     */
    @discardableResult
    open func startDrawingSession<T: ObjectRenderer>(ofType type: T.Type) -> T {
        assertNonZeroContentSize()
        
        finishDrawingSession()
        selectObjects([])
        
        let object = type.init()
        
        object.lineWidth = drawingSessionLineWidth
        object.strokeColor = drawingSessionStrokeColor
        object.fillColor = drawingSessionFillColor
        
        internalState = .drawing(object: object, state: .idle)
        
        redraw()
        
        delegate?.xcapView(self, didStartDrawingSessionWithObject: object)
        
        return object
    }
    
    @discardableResult
    open func finishDrawingSession() -> ObjectRenderer? {
        guard let object = currentObject else {
            return nil
        }
        guard canAddObject(object) && !(delegate?.xcapView(self, shouldDiscardObject: object) ?? false) else {
            cancelDrawingSession()
            return nil
        }
        
        internalAddObjects([object])
        
        internalState = .idle
        
        redraw()
        
        delegate?.xcapView(self, didFinishDrawingSessionWithObject: object)
        
        return object
    }
    
    open func cancelDrawingSession() {
        guard case .drawing = internalState else {
            return
        }
        
        internalState = .idle
        
        redraw()
        
        delegate?.xcapViewDidCancelDrawingSession(self)
    }
    
    // MARK: - Drawing
    
    private func redraw() {
        #if os(macOS)
        needsDisplay = true
        #else
        setNeedsDisplay()
        #endif
    }
    
    private func drawContents(contentRect: CGRect, scaleFactor: CGPoint) {
        guard let context = CGContext.current else {
            return
        }
        
        context.clip(to: contentRect)
        
        drawPlugins(ofTypes: [.underlay, .interactiveUnderlay], contentRect: contentRect, contentScaleFactor: scaleFactor, context: context)
        drawBackground(contentRect: contentRect, context: context)
        drawObjects(contentRect: contentRect, contentScaleFactor: scaleFactor, context: context)
        drawPlugins(ofTypes: [.overlay, .interactiveOverlay], contentRect: contentRect, contentScaleFactor: scaleFactor, context: context)
        
        if case .selecting(let rect, _) = internalState {
            drawSelectionRect(rect, contentRect: contentRect, contentScaleFactor: scaleFactor, context: context)
        }
    }
    
    public func drawContents(size: CGSize) {
        let bounds = CGRect(origin: .zero, size: size)
        let contentRect = AVMakeRect(aspectRatio: contentSize, insideRect: bounds)
        let scaleFactor = calcScaleFactor(from: contentSize, to: contentRect.size)
        
        drawContents(contentRect: contentRect, scaleFactor: scaleFactor)
    }
    
    public override func draw(_ dirtyRect: CGRect) {
        drawContents(contentRect: contentRect, scaleFactor: contentScaleFactors.toView)
    }
    
    private func drawBackground(contentRect: CGRect, context: CGContext) {
        guard let contentBackgroundColor = contentBackgroundColor else {
            return
        }
        
        // Start
        context.saveGState()
        
        context.setFillColor(contentBackgroundColor.cgColor)
        context.fill(contentRect)
        
        // End
        context.restoreGState()
    }
    
    private func drawSelectionRect(_ rect: CGRect, contentRect: CGRect, contentScaleFactor: CGPoint, context: CGContext) {
        // Start
        context.saveGState()
        
        let scaling = CGAffineTransform(scaleX: contentScaleFactor.x, y: contentScaleFactor.y)
        let translation = CGAffineTransform(translationX: contentRect.origin.x, y: contentRect.origin.y)
        let origin = rect.origin
            .applying(scaling)
            .applying(translation)
        let size = rect.size
            .applying(scaling)
        let selectionRect = CGRect(origin: origin, size: size)
            .pretty()
        
        context.setFillColor(selectionRectFillColor.cgColor)
        context.setStrokeColor(selectionRectBorderColor.cgColor)
        context.addRect(selectionRect)
        context.drawPath(using: .fillStroke)
        
        // End
        context.restoreGState()
    }
    
    // MARK: Draw Object
    
    private func decoration(for object: ObjectRenderer, isSelected: Bool) -> ObjectDecoration {
        guard isSelected else {
            return .none
        }
        
        if let object = object as? Editable {
            switch internalState {
            case .editing, .moving:
                return .none
                
            case let .onItem(anObject, position, _):
                return .withItems(object, highlightedPosition: anObject == object ? position : nil)
                
            default:
                return .withItems(object, highlightedPosition: nil)
            }
        } else {
            switch internalState {
            case .editing, .moving:
                return .none
                
            case let .onObject(anObject, _, _):
                return .withBoundingBox(object, highlighted: anObject == object)
                
            default:
                return .withBoundingBox(object, highlighted: false)
            }
        }
    }
    
    private func drawObjects(contentRect: CGRect, contentScaleFactor: CGPoint, context: CGContext) {
        for object in objects where !selectedObjects.contains(object) {
            drawObject(
                object,
                isSelected: false,
                contentRect: contentRect,
                contentScaleFactor: contentScaleFactor,
                context: context
            )
        }
        
        for object in selectedObjects {
            drawObject(
                object,
                isSelected: true,
                contentRect: contentRect,
                contentScaleFactor: contentScaleFactor,
                context: context
            )
        }
        
        if let object = currentObject {
            drawObject(
                object,
                isSelected: false,
                contentRect: contentRect,
                contentScaleFactor: contentScaleFactor,
                context: context
            )
        }
    }
    
    private func drawObject(
        _ object: ObjectRenderer,
        isSelected: Bool,
        contentRect: CGRect,
        contentScaleFactor: CGPoint,
        context: CGContext
    ) {
        func drawObject() {
            // Start
            context.saveGState()
            
            context.translateBy(x: contentRect.origin.x, y: contentRect.origin.y)
            context.scaleBy(x: contentScaleFactor.x, y: contentScaleFactor.y)
            object.draw(context: context)
            
            // End
            context.restoreGState()
        }
        
        let decoration = decoration(for: object, isSelected: isSelected)
        
        switch decoration {
        case .none:
            drawObject()
            
        case let .withItems(object, position):
            drawObject()
            drawObjectItems(
                for: object,
                highlightedPosition: position,
                contentRect: contentRect,
                scaleFactor: contentScaleFactor,
                context: context
            )
            
        case let .withBoundingBox(object, highlighted):
            drawObjectBoundingBox(
                object: object,
                highlighted: highlighted,
                contentRect: contentRect,
                contentScaleFactor: contentScaleFactor,
                context: context
            )
            drawObject()
        }
    }
    
    private func drawObjectItems(
        for object: Editable,
        highlightedPosition: ObjectLayout.Position?,
        contentRect: CGRect,
        scaleFactor: CGPoint,
        context: CGContext
    ) {
        // Start
        context.saveGState()
        context.translateBy(x: contentRect.origin.x, y: contentRect.origin.y)
        
        let itemTransform = CGAffineTransform.identity
            .scaledBy(x: scaleFactor.x, y: scaleFactor.y)
        
        for (i, items) in object.layout.enumerated() {
            for (j, item) in items.enumerated() {
                let position = ObjectLayout.Position(item: j, section: i)
                
                guard object.canEditItem(at: position) else {
                    continue
                }
                
                let point = item.applying(itemTransform)
                let highlighted = highlightedPosition == position
                let strokeColor = highlighted ? objectItemHighlightBorderColor : objectItemBorderColor
                let fillColor = highlighted ? objectItemHighlightFillColor : objectItemFillColor
                
                context.addArc(center: point, radius: selectionRange, startAngle: 0, endAngle: .pi * 2, clockwise: true)
                context.setStrokeColor(strokeColor.cgColor)
                context.setFillColor(fillColor.cgColor)
                context.drawPath(using: .fillStroke)
            }
        }
        
        // End
        context.restoreGState()
    }
    
    private func drawObjectBoundingBox(
        object: ObjectRenderer,
        highlighted: Bool,
        contentRect: CGRect,
        contentScaleFactor: CGPoint,
        context: CGContext
    ) {
        guard let pathBoundingBox = object.pathOfMainGraphics?.boundingBoxOfPath else {
            return
        }
        
        // Start
        context.saveGState()
        
        let boundingBox = pathBoundingBox
            .applying(.init(scaleX: contentScaleFactor.x, y: contentScaleFactor.y))
            .applying(.init(translationX: contentRect.origin.x, y: contentRect.origin.y))
            .insetBy(dx: -selectionRange, dy: -selectionRange)
            .pretty()
        let boundingBoxPath = CGPath(
            roundedRect: boundingBox,
            cornerWidth: objectBoundingBoxCornerRadius,
            cornerHeight: objectBoundingBoxCornerRadius,
            transform: nil
        )
        let borderColor = highlighted ? objectBoundingBoxHighlightBorderColor : objectBoundingBoxBorderColor
        let fillColor = highlighted ? objectBoundingBoxHighlightFillColor : objectBoundingBoxFillColor
        
        context.setFillColor(fillColor.cgColor)
        context.setStrokeColor(borderColor.cgColor)
        context.addPath(boundingBoxPath)
        context.drawPath(using: .fillStroke)
        
        // End
        context.restoreGState()
    }
    
    // MARK: - Draw Plugin
    
    private func drawPlugins(
        ofTypes pluginTypes: [Plugin.PluginType],
        contentRect: CGRect,
        contentScaleFactor: CGPoint,
        context: CGContext
    ) {
        for plugin in plugins where pluginTypes.contains(plugin.pluginType) && plugin.isEnabled {
            let state: Plugin.State = {
                if case let .plugin(aPlugin, state, _, _) = internalState, aPlugin == plugin {
                    return state
                } else {
                    return .idle
                }
            }()
            
            if plugin.shouldDraw(in: self, state: state) {
                context.saveGState()
                
                plugin.draw(in: self, state: state, contentRect: contentRect, contentScaleFactor: contentScaleFactor)
                
                context.restoreGState()
            }
        }
    }
    
}

// MARK: - Pointer Events

extension XcapView {
    
    private func pointerDidBegin(at location: CGPoint) {
        let location = convertLocation(fromViewToContent: location)
        let validRect = CGRect(origin: .zero, size: contentSize)
        
        guard validRect.contains(location) else {
            return
        }
        
        switch internalState {
        case .idle:
            if let plugin = findPlugin(for: .interactiveOverlay, at: location) {
                beginUpdatingPlugin(plugin, location: location)
            } else if let (object, position) = findEditableObject(at: location) {
                internalSelectObjects([object])
                
                internalState = .onItem(object: object, position: position, initialLocation: location)
                
                redraw()
            } else if let object = findObject(at: location) {
                let alreadySelected = selectedObjects.contains(object)
                
                if !alreadySelected {
                    internalSelectObjects([object], byExtendingSelection: isBidirectionalSelectionEnabled)
                }
                
                internalState = .onObject(object: object, alreadySelected: alreadySelected, initialLocation: location)
                
                redraw()
            } else if let plugin = findPlugin(for: .interactiveUnderlay, at: location) {
                beginUpdatingPlugin(plugin, location: location)
            } else {
                beginSelecting(location: location)
            }
            
        case .selecting, .onItem, .onObject, .editing, .moving, .plugin:
            break
            
        case let .drawing(object, sessionState):
            beginDrawing(object, location: location, sessionState: sessionState)
        }
    }
    
    private func pointerDidMove(to location: CGPoint) {
        let location = convertLocation(fromViewToContent: location)
        
        switch internalState {
        case .idle:
            break
            
        case let .selecting(rect, initialSelection):
            continueSelecting(rect, location: location, initialSelection: initialSelection)
            
        case let .onItem(object, position, initialLocation):
            beginEditing(object, position: position, location: initialLocation)
            continueEditing(object, position: position, location: location, lastLocation: initialLocation, initialLocation: initialLocation)
            
        case let .onObject(object, _, initialLocation):
            beginMoving(object, location: initialLocation)
            continueMoving(object, location: location, lastLocation: initialLocation, initialLocation: initialLocation)
            
        case let .editing(object, position, lastLocation, initialLocation):
            continueEditing(object, position: position, location: location, lastLocation: lastLocation, initialLocation: initialLocation)
            
        case let .moving(object, lastLocation, initialLocation):
            continueMoving(object, location: location, lastLocation: lastLocation, initialLocation: initialLocation)
            
        case let .drawing(object, sessionState):
            continueDrawing(object, location: location, sessionState: sessionState)
            
        case let .plugin(plugin, _, lastLocation, initialLocation):
            continueUpdatingPlugin(plugin, location: location, lastLocation: lastLocation, initialLocation: initialLocation)
        }
    }
    
    #if os(macOS)
    private func pointerDidTrack(_ location: CGPoint) {
        let location = convertLocation(fromViewToContent: location)
        
        switch internalState {
        case .idle, .selecting, .onItem, .onObject, .editing, .moving, .plugin:
            break
            
        case let .drawing(object, sessionState):
            trackingDrawing(object, location: location, sessionState: sessionState)
        }
    }
    #endif
    
    private func pointerDidEnd(at location: CGPoint) {
        let location = convertLocation(fromViewToContent: location)
        
        switch internalState {
        case .idle:
            break
            
        case let .selecting(_, initialSelection):
            endSelecting(location: location, initialSelection: initialSelection)
            
        case .onItem:
            internalState = .idle
            redraw()
            
        case let .onObject(object, alreadySelected, _):
            if isBidirectionalSelectionEnabled {
                if alreadySelected {
                    deselectObjects([object])
                }
            } else {
                internalSelectObjects([object])
            }
            
            internalState = .idle
            
            redraw()
            
        case let .editing(object, position, _, initialLocation):
            endEditing(object, position: position, location: location, initialLocation: initialLocation)
            
        case let .moving(object, _, initialLocation):
            endMoving(object, location: location, initialLocation: initialLocation)
            
        case let .drawing(object, sessionState):
            endDrawing(object, location: location, sessionState: sessionState)
            
        case let .plugin(plugin, _, _, initialLocation):
            endUpdatingPlugin(plugin, location: location, initialLocation: initialLocation)
        }
    }
    
}

// MARK: - Editing Events

extension XcapView {
    
    private func beginEditing(_ object: ObjectRenderer, position: ObjectLayout.Position, location: CGPoint) {
        internalState = .editing(object: object, position: position, lastLocation: location, initialLocation: location)
        redraw()
    }
    
    private func continueEditing(_ object: ObjectRenderer, position: ObjectLayout.Position, location: CGPoint, lastLocation: CGPoint, initialLocation: CGPoint) {
        let dx = location.x - lastLocation.x
        let dy = location.y - lastLocation.y
        let newItem = object.layout.item(at: position)
            .applying(.init(translationX: dx, y: dy))
        
        object.update(newItem, at: position)
        
        internalState = .editing(object: object, position: position, lastLocation: location, initialLocation: initialLocation)
        
        redraw()
        
        delegate?.xcapView(self, didEditObject: object, at: position)
    }
    
    private func endEditing(_ object: ObjectRenderer, position: ObjectLayout.Position, location: CGPoint, initialLocation: CGPoint) {
        let offset = CGPoint(x: location.x - initialLocation.x, y: location.y - initialLocation.y)
        
        internalState = .idle
        
        redraw()
        registerUndoEditObject(object, at: position, offset: offset, contentSize: contentSize)
    }
    
}

// MARK: - Dragging Events

extension XcapView {
    
    private func beginMoving(_ object: ObjectRenderer, location: CGPoint) {
        internalState = .moving(object: object, lastLocation: location, initialLocation: location)
        
        redraw()
    }
    
    private func continueMoving(_ object: ObjectRenderer, location: CGPoint, lastLocation: CGPoint, initialLocation: CGPoint) {
        let dx = location.x - lastLocation.x
        let dy = location.y - lastLocation.y
        
        for object in selectedObjects {
            object.translate(x: dx, y: dy)
        }
        
        internalState = .moving(object: object, lastLocation: location, initialLocation: initialLocation)
        
        redraw()
        
        delegate?.xcapView(self, didMoveObjects: selectedObjects)
    }
    
    private func endMoving(_ object: ObjectRenderer, location: CGPoint, initialLocation: CGPoint) {
        let offset = CGPoint(x: location.x - initialLocation.x, y: location.y - initialLocation.y)

        internalState = .idle
        
        redraw()
        registerUndoDragObjects(selectedObjects, offset: offset, contentSize: contentSize)
    }
    
}

// MARK: - Selecting Events

extension XcapView {
    
    private func beginSelecting(location: CGPoint) {
        let rect = CGRect(origin: location, size: .zero)
        
        if !isBidirectionalSelectionEnabled {
            internalSelectObjects([])
        }
        
        internalState = .selecting(rect: rect, initialSelection: selectedObjects)
        
        redraw()
    }
    
    private func continueSelecting(_ rect: CGRect, location: CGPoint, initialSelection: [ObjectRenderer]) {
        let size = CGSize(
            width: location.x - rect.origin.x,
            height: location.y - rect.origin.y
        )
        let newRect = CGRect(origin: rect.origin, size: size)
        let objectsToSelect = objects
            .filter { $0.selectionTest(rect: newRect) }
        let selection = isBidirectionalSelectionEnabled
            ? Array(Set(objectsToSelect).symmetricDifference(initialSelection))
            : objectsToSelect
        
        internalSelectObjects(selection)
        
        internalState = .selecting(rect: newRect, initialSelection: initialSelection)
        
        redraw()
    }
    
    private func endSelecting(location: CGPoint, initialSelection: [ObjectRenderer]) {
        internalState = .idle
        
        redraw()
    }
    
}

// MARK: - Drawing Session Events

extension XcapView {
    
    private func beginDrawing(_ object: ObjectRenderer, location: CGPoint, sessionState: DrawingSessionState) {
        switch object.layoutAction {
        case .push:
            if sessionState != .tracking {
                object.push(location)
                internalState = .drawing(object: object, state: .pressing)
            } else {
                object.updateLast(location)
            }
            
        case .pushSection:
            if sessionState != .tracking {
                object.pushSection(location)
                internalState = .drawing(object: object, state: .pressing)
            } else {
                object.updateLast(location)
            }
            
        case .continuousPush, .continuousPushThenFinish:
            object.pushSection(location)
            internalState = .drawing(object: object, state: .pressing)
            
        case .finish:
            break
        }
        
        redraw()
    }
    
    private func continueDrawing(_ object: ObjectRenderer, location: CGPoint, sessionState: DrawingSessionState) {
        let action = object.layoutAction
        
        switch object.layoutAction {
        case .continuousPush, .continuousPushThenFinish:
            object.push(location)
            internalState = .drawing(object: object, state: .moving)
            
        case .push, .pushSection, .finish:
            if object.layout.last?.count == 1, case .push = action {
                object.push(location)
            }
            object.updateLast(location)
            internalState = .drawing(object: object, state: .moving)
        }
        
        redraw()
    }
    
    #if os(macOS)
    private func trackingDrawing(_ object: ObjectRenderer, location: CGPoint, sessionState: DrawingSessionState) {
        guard sessionState == .tracking else {
            return
        }
        
        object.updateLast(location)
        
        internalState = .drawing(object: object, state: .tracking)
        
        redraw()
    }
    #endif
    
    private func endDrawing(_ object: ObjectRenderer, location: CGPoint, sessionState: DrawingSessionState) {
        let action = object.layoutAction
        
        switch action {
        case .continuousPush:
            internalState = .drawing(object: object, state: .idle)
            
        case .continuousPushThenFinish:
            finishDrawingSession()
            
        case .push, .pushSection, .finish:
            switch sessionState {
            case .pressing:
                if object.layout.last?.count == 1, case .push = action {
                    object.push(location)
                }
                internalState = .drawing(object: object, state: .tracking)
                
            case .tracking:
                switch action {
                case .push:
                    object.push(location)
                    internalState = .drawing(object: object, state: .tracking)
                    
                case .pushSection:
                    internalState = .drawing(object: object, state: .idle)
                    
                case .finish:
                    finishDrawingSession()
                    
                case .continuousPush, .continuousPushThenFinish:
                    break
                }
                
            case .idle, .moving:
                if case .finish = action {
                    finishDrawingSession()
                } else {
                    internalState = .drawing(object: object, state: .idle)
                }
            }
        }
        
        redraw()
    }
    
}

// MARK: - Plugin Events

extension XcapView {
    
    private func beginUpdatingPlugin(_ plugin: Plugin, location: CGPoint) {
        let pluginState: Plugin.State = .began(location: location)
        
        plugin.update(in: self, state: pluginState)
        
        internalState = .plugin(plugin: plugin, state: pluginState, lastLocation: location, initialLocation: location)
        
        redraw()
    }
    
    private func continueUpdatingPlugin(_ plugin: Plugin, location: CGPoint, lastLocation: CGPoint, initialLocation: CGPoint) {
        let pluginState: Plugin.State = .changed(location: location, lastLocation: lastLocation, initialLocation: initialLocation)
        
        plugin.update(in: self, state: pluginState)
        
        internalState = .plugin(plugin: plugin, state: pluginState, lastLocation: location, initialLocation: initialLocation)
        
        redraw()
    }
    
    private func endUpdatingPlugin(_ plugin: Plugin, location: CGPoint, initialLocation: CGPoint) {
        plugin.update(in: self, state: .ended(location: location, lastLocation: location, initialLocation: initialLocation))
        plugin.update(in: self, state: .idle)
        
        internalState = .idle
        
        redraw()
    }
    
}

// MARK: - Register Undo Action

extension XcapView {
    
    private func registerUndoAction(name: String?, _ handler: @escaping (XcapView) -> Void) {
        guard let undoManager = undoManager, undoManager.isUndoRegistrationEnabled else {
            return
        }
        
        undoManager.registerUndo(withTarget: self, handler: handler)
        
        if let name = name {
            undoManager.setActionName(name)
        }
    }
    
    private func registerUndoAddObjects(_ objects: [ObjectRenderer]) {
        guard !objects.isEmpty else {
            return
        }
        
        let name = implicitUndoActionNames[.addObjects]
        
        registerUndoAction(name: name) { xcapView in
            xcapView.removeObjects(objects)
        }
    }
    
    private func registerUndoRemoveObjects(_ removedObjects: [ObjectRenderer], originalObjects: [ObjectRenderer], contentSize: CGSize) {
        guard !removedObjects.isEmpty else {
            return
        }
        
        let name = implicitUndoActionNames[.removeObjects]
        
        registerUndoAction(name: name) { xcapView in
            let scaleFactor = xcapView.calcScaleFactor(from: contentSize, to: xcapView.contentSize)
            
            for object in removedObjects {
                if scaleFactor.x != 1 || scaleFactor.y != 1 {
                    object.scale(x: scaleFactor.x, y: scaleFactor.y)
                }
                
                xcapView.prepareObject(object)
            }
            
            xcapView.objects = originalObjects
            
            xcapView.registerUndoAddObjects(removedObjects)
            
            xcapView.redraw()
        }
    }
    
    private func registerUndoDragObjects(_ objects: [ObjectRenderer], offset: CGPoint, contentSize: CGSize) {
        guard offset != .zero else {
            return
        }
        
        let name = implicitUndoActionNames[.dragging]
        
        registerUndoAction(name: name) { xcapView in
            let scaleFactor = xcapView.calcScaleFactor(from: contentSize, to: xcapView.contentSize)
            let offset = CGPoint(
                x: -offset.x * scaleFactor.x,
                y: -offset.y * scaleFactor.y
            )
            
            objects.forEach { object in
                object.translate(x: offset.x, y: offset.y)
            }
            
            xcapView.registerUndoDragObjects(objects, offset: offset, contentSize: xcapView.contentSize)
            
            xcapView.delegate?.xcapView(xcapView, didMoveObjects: objects)
        }
    }
    
    private func registerUndoEditObject(_ object: ObjectRenderer, at position: ObjectLayout.Position, offset: CGPoint, contentSize: CGSize) {
        guard offset != .zero else {
            return
        }
        
        let name = implicitUndoActionNames[.editing]
        
        registerUndoAction(name: name) { xcapView in
            let scaleFactor = xcapView.calcScaleFactor(from: contentSize, to: xcapView.contentSize)
            let offset = CGPoint(
                x: -offset.x * scaleFactor.x,
                y: -offset.y * scaleFactor.y
            )
            let transform = CGAffineTransform.identity
                .translatedBy(x: offset.x, y: offset.y)
            let point = object.layout.item(at: position)
                .applying(transform)
            
            object.update(point, at: position)
            
            xcapView.registerUndoEditObject(object, at: position, offset: offset, contentSize: xcapView.contentSize)
            
            xcapView.delegate?.xcapView(xcapView, didEditObject: object, at: position)
        }
    }
    
}
