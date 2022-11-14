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
    func xcapView(_ xcapView: XcapView, didFinishDrawingSessionWithObject object: ObjectRenderer)
    func xcapViewDidCancelDrawingSession(_ xcapView: XcapView)
    func xcapView(_ xcapView: XcapView, shouldDiscardObject object: ObjectRenderer) -> Bool
    // ----- Selection -----
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
    public func xcapView(_ xcapView: XcapView, didFinishDrawingSessionWithObject object: ObjectRenderer) {}
    public func xcapViewDidCancelDrawingSession(_ xcapView: XcapView) {}
    public func xcapView(_ xcapView: XcapView, shouldDiscardObject object: ObjectRenderer) -> Bool { false }
    // ----- Selection -----
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
    
    private enum DrawingSessionState {
        case idle
        case pressing
        case moving
        /// macOS Only
        case tracking
    }
    
    private enum InternalState {
        case idle
        
        case selecting(initialSelection: [ObjectRenderer], originalRect: CGRect, convertedRect: CGRect)
        
        case onItem(object: ObjectRenderer, position: ObjectLayout.Position, initialLocation: CGPoint)
        case onObject(object: ObjectRenderer, alreadySelected: Bool, initialLocation: CGPoint)
        
        case editing(object: ObjectRenderer, position: ObjectLayout.Position, initialLocation: CGPoint, lastLocation: CGPoint)
        case moving(object: ObjectRenderer, initialLocation: CGPoint, lastLocation: CGPoint)
        case drawing(object: ObjectRenderer, state: DrawingSessionState)
        case plugin(plugin: PluginType, state: PluginState, initialLocation: CGPoint, lastLocation: CGPoint)
    }
    
    private enum ObjectDecoration {
        case none
        case items(ObjectLayout.Position?)
        case boundingBox(Bool)
    }
    
    // ----- Public -----
    
    public typealias ScaleFactor = CGPoint
    
    public enum State {
        case idle
        case selecting
        case onItem(object: ObjectRenderer, position: ObjectLayout.Position)
        case onObject(ObjectRenderer)
        case editing(object: ObjectRenderer, position: ObjectLayout.Position)
        case moving([ObjectRenderer])
        case drawing(ObjectRenderer)
        case plugin(PluginType)
    }
    
    public enum UndoAction {
        case addObjects
        case removeObject
        case draging
        case editing
    }
    
}

@objcMembers
open class XcapView: PlatformView, RedrawAndUndoController {
    
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
    
    /// Do NOT modify object during drawing session.
    open var state: State {
        getState()
    }
    
    open private(set) var contentScaleFactors: (toContent: ScaleFactor, toView: ScaleFactor) = (.zero, .zero)
    
    dynamic open private(set) var contentRect = CGRect.zero
    
    dynamic open private(set) var objects: [ObjectRenderer] = []
    
    dynamic open private(set) var selectedObjects: [ObjectRenderer] = []
    
    dynamic open private(set) var currentObject: ObjectRenderer?
    
    // MARK: - Settings
    
    open weak var delegate: XcapViewDelegate?
    
    // ----- Content Settings -----
    
    @objc dynamic open var contentSize = CGSize.zero {
        didSet { contentSizeDidChange(oldValue) }
    }
    
    @Redrawable
    dynamic open var contentBackgroundColor: PlatformColor = .white
    
    // ----- Selection Settings -----
    
    @Redrawable
    dynamic open var selectionRange: CGFloat = 10 {
        didSet { updateContentInfo() }
    }
    
    @Redrawable
    dynamic open var selectionRectBorderColor: PlatformColor = .lightGray
    
    @Redrawable
    dynamic open var selectionRectFillColor: PlatformColor = .cyan.withAlphaComponent(0.2)
    
    // ----- Drawing Session Settings -----
    
    @Redrawable
    dynamic open var drawingSessionLineWidth: CGFloat = 1
    
    @Redrawable
    dynamic open var drawingSessionStrokeColor: PlatformColor = .black
    
    @Redrawable
    dynamic open var drawingSessionFillColor: PlatformColor = .white
    
    // ----- Object Item Settings -----
    
    @Redrawable
    dynamic open var objectItemBorderColor: PlatformColor = .black
    
    @Redrawable
    dynamic open var objectItemFillColor: PlatformColor = .white
    
    @Redrawable
    dynamic open var objectItemHighlightBorderColor: PlatformColor = .black
    
    @Redrawable
    dynamic open var objectItemHighlightFillColor: PlatformColor = {
        #if os(macOS)
        return .controlAccentColor
        #else
        return .systemBlue
        #endif
    }()
    
    // ----- Object Bounding Box Settings -----
    
    @Redrawable
    dynamic open var objectBoundingBoxBorderColor: PlatformColor = .black
    
    @Redrawable
    dynamic open var objectBoundingBoxFillColor: PlatformColor = .clear
    
    @Redrawable
    dynamic open var objectBoundingBoxHighlightBorderColor: PlatformColor = .black
    
    @Redrawable
    dynamic open var objectBoundingBoxHighlightFillColor: PlatformColor = .cyan.withAlphaComponent(0.3)
    
    // ----- Undo Settings -----
    
    open var implicitUndoActionNames: [UndoAction: String] = [:]
    
    // ----- Plugin Settings -----
    
    open var plugins: [PluginType] = [] {
        didSet {
            redraw()
        }
    }
    
    // ----- Overrides -----
    
    #if os(macOS)
    open override var acceptsFirstResponder: Bool {
        true
    }
    #endif
    
    // MARK: - Life Cycle
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
        
        setupRedrawHandler { [weak self] in
            self?.redraw()
        }
    }
    
    #if os(macOS)
    open override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }
        
        let trackingArea = NSTrackingArea(rect: bounds,
                                          options: [.activeInKeyWindow, .mouseMoved],
                                          owner: self)
        
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
        
        center.addObserver(self,
                           selector: #selector(self.frameDidChange(_:)),
                           name: NSView.frameDidChangeNotification,
                           object: self)
        
        center.addObserver(self,
                           selector: #selector(self.windowDidResignKey(_:)),
                           name: NSWindow.didResignKeyNotification,
                           object: nil)
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
        case let .drawing(object, _):
            return .drawing(object)
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
    
    private func calcScaleFactor(from: CGSize, to: CGSize) -> ScaleFactor {
        ScaleFactor(x: to.width / from.width, y: to.height / from.height)
    }
    
    private func updateContentInfo() {
        guard validateContentSize() else {
            return
        }
        
        let newContentRect = AVMakeRect(aspectRatio: contentSize, insideRect: bounds)
        let toScaleFactor = calcScaleFactor(from: newContentRect.size, to: contentSize)
        let fromScaleFactor = ScaleFactor(x: 1 / toScaleFactor.x, y: 1 / toScaleFactor.y)
        
        contentRect = newContentRect
        contentScaleFactors = (toScaleFactor, fromScaleFactor)
        
        redraw()
    }
    
    open func convertLocation(fromContentToView location: CGPoint) -> CGPoint {
        let scale = CGAffineTransform.identity
            .scaledBy(x: contentScaleFactors.toView.x, y: contentScaleFactors.toView.y)
        let translate = CGAffineTransform.identity
            .translatedBy(x: contentRect.origin.x, y: contentRect.origin.y)
        return location
            .applying(scale)
            .applying(translate)
    }
    
    open func convertLocation(fromViewToContent location: CGPoint) -> CGPoint {
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
                    let rangeCircle = Circle(center: item, radius: convertedSelectionRange)
                    let position = ObjectLayout.Position(item: items.count - j - 1,
                                                         section: object.layout.count - i - 1)
                    
                    if rangeCircle.contains(location) && object.canEditItem(at: position) {
                        return (object, position)
                    }
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Plugin Utils
    
    private func findPlugin(for priority: PluginPriority, at location: CGPoint) -> PluginType? {
        return plugins.first { plugin in
            guard plugin.priority == priority else {
                return false
            }
            return plugin.shouldBegin(in: self, location: location)
        }
    }
    
    // MARK: - Platform Touch Events
    
    #if os(macOS)
    open override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        
        let location = convert(event.locationInWindow, from: nil)
        
        touchBegan(at: location)
    }
    #else
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard let location = touches.first?.location(in: self) else {
            return
        }
        
        touchBegan(at: location)
    }
    #endif
    
    #if os(macOS)
    open override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        
        let location = convert(event.locationInWindow, from: nil)
        
        touchMoved(to: location)
    }
    #else
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        guard let location = touches.first?.location(in: self) else {
            return
        }
        
        touchMoved(to: location)
    }
    #endif
    
    #if os(macOS)
    open override func mouseMoved(with event: NSEvent) {
        super.mouseDragged(with: event)
        
        let location = convert(event.locationInWindow, from: nil)
        
        touchTracked(at: location)
    }
    #endif
    
    #if os(macOS)
    open override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        
        let location = convert(event.locationInWindow, from: nil)
        
        touchEnded(at: location)
    }
    #else
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        guard let location = touches.first?.location(in: self) else {
            return
        }
        
        touchEnded(at: location)
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        guard let location = touches.first?.location(in: self) else {
            return
        }
        
        touchEnded(at: location)
    }
    #endif
    
    #if os(macOS)
    open override func menu(for event: NSEvent) -> NSMenu? {
        guard window?.isKeyWindow == true,
              event.type == .rightMouseDown,
              case .idle = state
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
    
    /// No Redraw
    private func internalAddObjects(_ newObjects: [ObjectRenderer]) {
        for object in newObjects {
            object.redrawHandler = { [weak self] in
                self?.redraw()
            }
            object.undoManager = undoManager
            object.markAsFinished()
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
        
        registerUndoRemoveObjects(objectsToRemove, contextSize: contentSize)
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
        let newSelection = objects.filter {
            !selectedObjects.contains($0)
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
        guard let object = currentObject, canAddObject(object) else {
            return nil
        }
        guard !(delegate?.xcapView(self, shouldDiscardObject: object) ?? false) else {
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
    
    public override func draw(_ dirtyRect: CGRect) {
        guard let context = CGContext.current else {
            return
        }
        
        drawBackground(context: context)
        drawObjects(context: context)
        drawPlugins(context: context)
        
        if case .selecting(_, let rect, _) = internalState {
            drawSelectionRect(rect, context: context)
        }
    }
    
    private func drawBackground(context: CGContext) {
        // Start
        context.saveGState()
        
        context.setFillColor(contentBackgroundColor.cgColor)
        context.fill(contentRect)
        
        // End
        context.restoreGState()
        context.clip(to: contentRect)
    }
    
    private func decoration(for object: ObjectRenderer, isSelected: Bool) -> ObjectDecoration {
        guard isSelected else {
            return .none
        }
        
        if object is Editable {
            switch internalState {
            case .editing, .moving:
                return .none
            case let .onItem(anObject, position, _):
                return .items(anObject == object ? position : nil)
            default:
                return .items(nil)
            }
        } else {
            switch internalState {
            case .editing, .moving:
                return .none
            case let .onObject(anObject, _, _):
                return .boundingBox(anObject == object)
            default:
                return .boundingBox(false)
            }
        }
    }
    
    private func drawObjects(context: CGContext) {
        for object in objects where !selectedObjects.contains(object) {
            drawObject(object, context: context)
        }
        
        for object in selectedObjects {
            let decoration = decoration(for: object, isSelected: true)
            
            switch decoration {
            case .none:
                drawObject(object, context: context)
            case let .items(position):
                drawObject(object, context: context)
                drawItems(for: object, highlightAt: position, context: context)
            case let .boundingBox(highlight):
                drawBoundingBox(for: object, highlight: highlight, context: context)
                drawObject(object, context: context)
            }
        }
        
        if let object = currentObject {
            drawObject(object, context: context)
        }
    }
    
    private func drawObject(_ object: ObjectRenderer, context: CGContext) {
        // Start
        context.saveGState()
        
        context.translateBy(x: contentRect.origin.x, y: contentRect.origin.y)
        context.scaleBy(x: contentScaleFactors.toView.x, y: contentScaleFactors.toView.y)
        
        object.draw(context: context)
        
        // End
        context.restoreGState()
    }
    
    private func drawBoundingBox(for object: ObjectRenderer, highlight: Bool, context: CGContext) {
        guard let boundingBox = object.boundingBox else {
            return
        }
        
        // Start
        context.saveGState()
        
        context.translateBy(x: contentRect.origin.x, y: contentRect.origin.y)
        
        let transform = CGAffineTransform.identity
            .scaledBy(x: contentScaleFactors.toView.x, y: contentScaleFactors.toView.y)
        let convertedBoundingBox = boundingBox
            .applying(transform)
            .insetBy(dx: -selectionRange, dy: -selectionRange)
        let borderColor = highlight ? objectBoundingBoxHighlightBorderColor : objectBoundingBoxBorderColor
        let fillColor = highlight ? objectBoundingBoxHighlightFillColor : objectBoundingBoxFillColor
        
        context.setFillColor(fillColor.cgColor)
        context.setStrokeColor(borderColor.cgColor)
        context.addRect(convertedBoundingBox)
        context.drawPath(using: .fillStroke)
        
        // End
        context.restoreGState()
    }
    
    private func drawItems(for object: ObjectRenderer, highlightAt highlightedPosition: ObjectLayout.Position?, context: CGContext) {
        // Start
        context.saveGState()
        
        context.translateBy(x: contentRect.origin.x, y: contentRect.origin.y)
        
        let itemTransform = CGAffineTransform.identity
            .scaledBy(x: contentScaleFactors.toView.x,
                      y: contentScaleFactors.toView.y)
        
        for (i, items) in object.layout.enumerated() {
            for (j, item) in items.enumerated() {
                let item = item.applying(itemTransform)
                let shouldHighlight = highlightedPosition?.section == i && highlightedPosition?.item == j
                let strokeColor = shouldHighlight ? objectItemHighlightBorderColor : objectItemBorderColor
                let fillColor = shouldHighlight ? objectItemHighlightFillColor : objectItemFillColor
                
                context.setStrokeColor(strokeColor.cgColor)
                context.setFillColor(fillColor.cgColor)
                
                context.addArc(center: item, radius: selectionRange, startAngle: 0, endAngle: .pi * 2, clockwise: true)
                context.drawPath(using: .fillStroke)
            }
        }
        
        // End
        context.restoreGState()
    }
    
    private func drawPlugins(context: CGContext) {
        for plugin in plugins {
            let pluginState: PluginState = {
                if case let .plugin(aPlugin, state, _, _) = internalState, aPlugin === plugin {
                    return state
                } else {
                    return .idle
                }
            }()
            
            if plugin.shouldDraw(in: self, state: pluginState) {
                context.saveGState()
                plugin.draw(in: self, state: pluginState, context: context)
                context.restoreGState()
            }
        }
    }
    
    private func drawSelectionRect(_ rect: CGRect, context: CGContext) {
        // Start
        context.saveGState()
        
        context.setFillColor(selectionRectFillColor.cgColor)
        context.setStrokeColor(selectionRectBorderColor.cgColor)
        context.addRect(rect)
        context.drawPath(using: .fillStroke)
        
        // End
        context.restoreGState()
    }
    
}

// MARK: - Shared Touch Events

extension XcapView {
    
    private func touchBegan(at location: CGPoint) {
        switch internalState {
        case .idle:
            let convertedLocation = convertLocation(fromViewToContent: location)
            
            if let plugin = findPlugin(for: .high, at: location) {
                updatePlugin(plugin, didBeginAt: location)
            } else if let (object, position) = findEditableObject(at: convertedLocation) {
                internalSelectObjects([object])
                
                internalState = .onItem(object: object, position: position, initialLocation: convertedLocation)
                
                redraw()
            } else if let object = findObject(at: convertedLocation) {
                let alreadySelected = selectedObjects.contains(object)
                
                if !alreadySelected {
                    internalSelectObjects([object], byExtendingSelection: isBidirectionalSelectionEnabled)
                }
                
                internalState = .onObject(object: object, alreadySelected: alreadySelected, initialLocation: convertedLocation)
                
                redraw()
            } else if let plugin = findPlugin(for: .low, at: location) {
                updatePlugin(plugin, didBeginAt: location)
            } else {
                selectingDidBegin(at: location)
            }
            
        case .selecting, .onItem, .onObject, .editing, .moving, .plugin:
            break
            
        case let .drawing(object, sessionState):
            drawing(object, didBeginAt: location, sessionState: sessionState)
        }
    }
    
    private func touchMoved(to location: CGPoint) {
        switch internalState {
        case .idle:
            break
            
        case let .selecting(initialSelection, originalRect, convertedRect):
            selectingDidMove(to: location, initialSelection: initialSelection, originalRect: originalRect, convertedRect: convertedRect)
            
        case let .onItem(object, position, initialLocation):
            editing(object, didBeginAt: initialLocation, position: position)
            editing(object, didMoveTo: location, position: position, initialLocation: initialLocation, lastLocation: initialLocation)
            
        case let .onObject(object, _, initialLocation):
            moving(object, didBeginAt: initialLocation)
            moving(object, didMoveTo: location, initialLocation: initialLocation, lastLocation: initialLocation)
            
        case let .editing(object, position, initialLocation, lastLocation):
            editing(object, didMoveTo: location, position: position, initialLocation: initialLocation, lastLocation: lastLocation)
            
        case let .moving(object, initialLocation, lastLocation):
            moving(object, didMoveTo: location, initialLocation: initialLocation, lastLocation: lastLocation)
            
        case let .drawing(object, sessionState):
            drawing(object, didMoveTo: location, sessionState: sessionState)
            
        case let .plugin(plugin, _, initialLocation, lastLocation):
            updatePlugin(plugin, didMoveTo: location, initialLocation: initialLocation, lastLocation: lastLocation)
        }
    }
    
    private func touchTracked(at location: CGPoint) {
        switch internalState {
        case .idle, .selecting, .onItem, .onObject, .editing, .moving, .plugin:
            break
            
        case let .drawing(object, sessionState):
            drawing(object, didTrackAt: location, sessionState: sessionState)
        }
    }
    
    private func touchEnded(at location: CGPoint) {
        switch internalState {
        case .idle:
            break
            
        case let .selecting(initialSelection, originalRect, convertedRect):
            selectingDidEnd(at: location, initialSelection: initialSelection, originalRect: originalRect, convertedRect: convertedRect)
            
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
            
        case let .editing(object, position, initialLocation, lastLocation):
            editing(object, didEndAt: location, position: position, initialLocation: initialLocation, lastLocation: lastLocation)
            
        case let .moving(object, initialLocation, lastLocation):
            moving(object, didEndAt: location, initialLocation: initialLocation, lastLocation: lastLocation)
            
        case let .drawing(object, sessionState):
            drawing(object, didEndAt: location, sessionState: sessionState)
            
        case let .plugin(plugin, _, initialLocation, lastLocation):
            updatePlugin(plugin, didEndAt: location, initialLocation: initialLocation, lastLocation: lastLocation)
        }
    }
    
}

// MARK: Editing Events

extension XcapView {
    
    private func editing(_ object: ObjectRenderer, didBeginAt location: CGPoint, position: ObjectLayout.Position) {
        let location = convertLocation(fromViewToContent: location)
        internalState = .editing(object: object, position: position, initialLocation: location, lastLocation: location)
        redraw()
    }
    
    private func editing(_ object: ObjectRenderer,
                         didMoveTo location: CGPoint,
                         position: ObjectLayout.Position,
                         initialLocation: CGPoint,
                         lastLocation: CGPoint)
    {
        let location = convertLocation(fromViewToContent: location)
        let dx = location.x - lastLocation.x
        let dy = location.y - lastLocation.y
        let newItem = object.layout[position: position]
            .applying(.init(translationX: dx, y: dy))
        
        object.update(newItem, at: position)
        
        internalState = .editing(object: object, position: position, initialLocation: initialLocation, lastLocation: location)
        
        redraw()
        
        delegate?.xcapView(self, didEditObject: object, at: position)
    }
    
    private func editing(_ object: ObjectRenderer,
                         didEndAt location: CGPoint,
                         position: ObjectLayout.Position,
                         initialLocation: CGPoint,
                         lastLocation: CGPoint)
    {
        let location = convertLocation(fromViewToContent: location)
        let offset = CGPoint(x: location.x - initialLocation.x, y: location.y - initialLocation.y)
        
        internalState = .idle
        
        redraw()
        registerUndoEditObject(object, at: position, offset: offset, contentSize: contentSize)
    }
    
}

// MARK: Dragging Events

extension XcapView {
    
    private func moving(_ object: ObjectRenderer, didBeginAt location: CGPoint) {
        internalState = .moving(object: object, initialLocation: location, lastLocation: location)
        
        redraw()
    }
    
    private func moving(_ object: ObjectRenderer, didMoveTo location: CGPoint, initialLocation: CGPoint, lastLocation: CGPoint) {
        let location = convertLocation(fromViewToContent: location)
        let dx = location.x - lastLocation.x
        let dy = location.y - lastLocation.y
        
        for object in selectedObjects {
            object.translate(x: dx, y: dy)
        }
        
        internalState = .moving(object: object, initialLocation: initialLocation, lastLocation: location)
        
        redraw()
        
        delegate?.xcapView(self, didMoveObjects: selectedObjects)
    }
    
    private func moving(_ object: ObjectRenderer, didEndAt location: CGPoint, initialLocation: CGPoint, lastLocation: CGPoint) {
        let location = convertLocation(fromViewToContent: location)
        let offset = CGPoint(x: location.x - initialLocation.x, y: location.y - initialLocation.y)

        internalState = .idle
        
        redraw()
        registerUndoDragObjects(selectedObjects, offset: offset, contentSize: contentSize)
    }
    
}

// MARK: Selecting Events

extension XcapView {
    
    private func selectingDidBegin(at location: CGPoint) {
        let location = CGPoint(x: location.x.rounded() + 0.5, y: location.y.rounded() + 0.5)
        let originalRect = CGRect(origin: location, size: .zero)
        let convertedLocation = convertLocation(fromViewToContent: location)
        let convertedRect = CGRect(origin: convertedLocation, size: .zero)
        
        if !isBidirectionalSelectionEnabled {
            internalSelectObjects([])
        }
        
        internalState = .selecting(initialSelection: selectedObjects, originalRect: originalRect, convertedRect: convertedRect)
        
        redraw()
    }
    
    private func selectingDidMove(to location: CGPoint, initialSelection: [ObjectRenderer], originalRect: CGRect, convertedRect: CGRect) {
        let originalSize = CGSize(width: (location.x - originalRect.origin.x).rounded(),
                                  height: (location.y - originalRect.origin.y).rounded())
        let originalRect = CGRect(origin: originalRect.origin, size: originalSize)
        let convertedSize = originalSize
            .applying(.init(scaleX: contentScaleFactors.toContent.x, y: contentScaleFactors.toContent.y))
        let convertedRect = CGRect(origin: convertedRect.origin, size: convertedSize)
        let objectsToSelect = objects
            .filter { $0.selectionTest(rect: convertedRect) }
        let selection = isBidirectionalSelectionEnabled
            ? Array(Set(objectsToSelect).symmetricDifference(initialSelection))
            : objectsToSelect
        
        internalSelectObjects(selection)
        
        internalState = .selecting(initialSelection: initialSelection, originalRect: originalRect, convertedRect: convertedRect)
        
        redraw()
    }
    
    private func selectingDidEnd(at location: CGPoint, initialSelection: [ObjectRenderer], originalRect: CGRect, convertedRect: CGRect) {
        internalState = .idle
        
        redraw()
    }
    
}

// MARK: Drawing Session Events

extension XcapView {
    
    private func drawing(_ object: ObjectRenderer, didBeginAt location: CGPoint, sessionState: DrawingSessionState) {
        let location = convertLocation(fromViewToContent: location)
        
        switch object.layoutAction {
        case .push:
            if sessionState != .tracking {
                object.push(location)
                object.push(location)
                internalState = .drawing(object: object, state: .pressing)
            } else {
                object.updateLast(location)
            }
            
        case .pushSection:
            if sessionState != .tracking {
                object.pushSection(location)
                object.push(location)
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
    
    private func drawing(_ object: ObjectRenderer, didMoveTo location: CGPoint, sessionState: DrawingSessionState) {
        let location = convertLocation(fromViewToContent: location)
        
        switch object.layoutAction {
        case .continuousPush, .continuousPushThenFinish:
            object.push(location)
            internalState = .drawing(object: object, state: .moving)
            
        case .push, .pushSection, .finish:
            object.updateLast(location)
            internalState = .drawing(object: object, state: .moving)
        }
        
        redraw()
    }
    
    private func drawing(_ object: ObjectRenderer, didTrackAt location: CGPoint, sessionState: DrawingSessionState) {
        guard sessionState == .tracking else {
            return
        }
        
        let location = convertLocation(fromViewToContent: location)
        
        object.updateLast(location)
        
        internalState = .drawing(object: object, state: .tracking)
        
        redraw()
    }
    
    private func drawing(_ object: ObjectRenderer, didEndAt location: CGPoint, sessionState: DrawingSessionState) {
        let location = convertLocation(fromViewToContent: location)
        let action = object.layoutAction
        
        switch action {
        case .continuousPush:
            internalState = .drawing(object: object, state: .idle)
            
        case .continuousPushThenFinish:
            finishDrawingSession()
            
        case .push, .pushSection, .finish:
            switch sessionState {
            case .pressing:
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
    
    private func updatePlugin(_ plugin: PluginType, didBeginAt location: CGPoint) {
        let pluginState: PluginState = .began(location: location)
        
        plugin.update(in: self, state: pluginState)
        
        internalState = .plugin(plugin: plugin, state: pluginState, initialLocation: location, lastLocation: location)
        
        redraw()
    }
    
    private func updatePlugin(_ plugin: PluginType, didMoveTo location: CGPoint, initialLocation: CGPoint, lastLocation: CGPoint) {
        let pluginState: PluginState = .dragged(location: location, initialLocation: initialLocation, lastLocation: lastLocation)
        
        plugin.update(in: self, state: pluginState)
        
        internalState = .plugin(plugin: plugin, state: pluginState, initialLocation: initialLocation, lastLocation: location)
        
        redraw()
    }
    
    private func updatePlugin(_ plugin: PluginType, didEndAt location: CGPoint, initialLocation: CGPoint, lastLocation: CGPoint) {
        plugin.update(in: self, state: .ended(location: location, initialLocation: initialLocation, lastLocation: location))
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
    
    private func registerUndoRemoveObjects(_ objects: [ObjectRenderer], contextSize: CGSize) {
        guard !objects.isEmpty else {
            return
        }
        
        let name = implicitUndoActionNames[.removeObject]
        
        registerUndoAction(name: name) { xcapView in
            let scaleFactor = xcapView.calcScaleFactor(from: contextSize, to: xcapView.contentSize)
            
            for object in objects {
                object.scale(x: scaleFactor.x, y: scaleFactor.y)
            }
            
            xcapView.addObjects(objects)
        }
    }
    
    private func registerUndoDragObjects(_ objects: [ObjectRenderer], offset: CGPoint, contentSize: CGSize) {
        guard offset != .zero else {
            return
        }
        
        let name = implicitUndoActionNames[.draging]
        
        registerUndoAction(name: name) { xcapView in
            let scaleFactor = xcapView.calcScaleFactor(from: contentSize, to: xcapView.contentSize)
            let offset = CGPoint(x: -offset.x * scaleFactor.x,
                                 y: -offset.y * scaleFactor.y)
            
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
            let offset = CGPoint(x: -offset.x * scaleFactor.x,
                                 y: -offset.y * scaleFactor.y)
            let transform = CGAffineTransform.identity
                .translatedBy(x: offset.x, y: offset.y)
            let point = object.layout[position: position]
                .applying(transform)
            
            object.update(point, at: position)
            
            xcapView.registerUndoEditObject(object, at: position, offset: offset, contentSize: xcapView.contentSize)
            
            xcapView.delegate?.xcapView(xcapView, didEditObject: object, at: position)
        }
    }
    
}
