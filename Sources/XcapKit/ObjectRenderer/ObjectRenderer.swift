//
//  ObjectRenderer.swift
//  
//
//  Created by scchn on 2022/11/3.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension ObjectRenderer {
    
    // ----- Private -----
    
    private struct Color: Codable {
        
        var red: CGFloat
        var green: CGFloat
        var blue: CGFloat
        var alpha: CGFloat
        
        #if os(macOS)
        init?(color: PlatformColor) {
            guard let ciColor = CIColor(color: color) else {
                return nil
            }
            
            red = ciColor.red
            green = ciColor.green
            blue = ciColor.blue
            alpha = ciColor.alpha
        }
        #else
        init(color: PlatformColor) {
            let ciColor = CIColor(color: color)
            
            red = ciColor.red
            green = ciColor.green
            blue = ciColor.blue
            alpha = ciColor.alpha
        }
        #endif
        
        var platformColor: PlatformColor {
            .init(red: red, green: green, blue: blue, alpha: alpha)
        }
        
    }
    
    // ----- Public -----
    
    public enum LayoutAction: Equatable {
        
        case push(finishable: Bool)
        case pushSection(finishable: Bool)
        case continuousPush(finishable: Bool)
        case continuousPushThenFinish
        case finish
        
        public var isFinishable: Bool {
            switch self {
            case .push(let finishable):
                fallthrough
            case .pushSection(let finishable):
                fallthrough
            case .continuousPush(let finishable):
                return finishable
            case .continuousPushThenFinish, .finish:
                return true
            }
        }
        
        public static func singleSection(items: Int, for layout: ObjectLayout) -> LayoutAction {
            assert(items > 0, "⚠️ `items` must greater than 0.")
            
            return layout.first?.count != items ? .push(finishable: false) : .finish
        }
        
        public static func singleContinuousSection(for layout: ObjectLayout) -> LayoutAction {
            layout.isEmpty ? .push(finishable: false) : .continuousPushThenFinish
        }
        
        public static func multipleSections(_ sections: [Int], for layout: ObjectLayout) -> LayoutAction {
            assert(!sections.isEmpty, "⚠️ `sections` must not be empty.")
            assert(!sections.contains(where: { $0 <= 0 }), "⚠️ elements in `sections` must be greater than 0.")
            
            if sections == layout.map(\.count) {
                return .finish
            } else if layout.isEmpty || layout.last?.count == sections[layout.count - 1] {
                return .pushSection(finishable: false)
            } else {
                return .push(finishable: false)
            }
        }
        
    }
    
    public struct DrawingStrategy: OptionSet {
        
        public var rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let beforeFinishable  = DrawingStrategy(rawValue: 1 << 0)
        public static let whenFinishable    = DrawingStrategy(rawValue: 1 << 1)
        public static let whenFinished      = DrawingStrategy(rawValue: 1 << 2)
        public static let always            = DrawingStrategy([.whenFinished, .whenFinishable, .beforeFinishable])
        
    }
    
    public struct ItemBinding {
        
        public var position: ObjectLayout.Position
        public var offset: CGPoint
        
        public init(position: ObjectLayout.Position, offset: CGPoint) {
            self.position = position
            self.offset = offset
        }
        
    }
    
    public enum PointDescriptor: Equatable, Hashable, Codable {
        case item(ObjectLayout.Position)
        case fixed(CGPoint)
    }
    
}

@objcMembers
open class ObjectRenderer: NSObject, Codable, Drawable, SettingsInspector {
    
    private var preliminaryGraphics: [Drawable] = []
    
    private var mainGraphics: [Drawable] = []
    
    var undoManager: UndoManager?
    
    // MARK: - Data
    
    open private(set) var layout = ObjectLayout() {
        didSet {
            layoutDidUpdate()
            update()
        }
    }
    
    open private(set) var isFinished = false
    
    open private(set) var pathOfMainGraphics: CGPath?
    
    // MARK: - Layout Control
    
    open var layoutAction: LayoutAction {
        .singleContinuousSection(for: layout)
    }
    
    open var preliminaryGraphicsDrawingStrategy: DrawingStrategy {
        [.beforeFinishable, .whenFinishable]
    }
    
    open var mainGraphicsDrawingStrategy: DrawingStrategy {
        [.whenFinishable, .whenFinished]
    }
    
    open var itemBindings: [ObjectLayout.Position: [ItemBinding]] {
        [:]
    }
    
    // MARK: - Settings
    
    /// Default = `nil`
    ///
    /// Setter: ``setRotationCenter(_:)``
    open private(set) var rotationCenter: PointDescriptor?
    
    /// Default = 0 Degrees
    ///
    /// Setter: ``rotate(angle:)``
    open private(set) var rotationAngle = Angle.radians(0)
    
    /// Default = Black
    @Setting dynamic open var strokeColor: PlatformColor = .black
    
    /// Default = White
    @Setting dynamic open var fillColor: PlatformColor = .white
    
    /// Default = 1
    @Setting dynamic open var lineWidth: CGFloat = 1
    
    // MARK: - Events
    
    var redrawHandler: (() -> Void)?
    
    // MARK: - Life Cycle
    
    public required override init() {
        super.init()
        
        commonInit()
    }
    
    private func commonInit() {
        registerSettings { [weak self] in
            self?.update()
        }
    }
    
    open func layoutDidUpdate() {
        
    }
    
    // MARK: - Utils
    
    open func point(with pointDescriptor: PointDescriptor) -> CGPoint {
        switch pointDescriptor {
        case .item(let position):   return layout.item(at: position)
        case .fixed(let point):     return point
        }
    }
    
    // MARK: - Push
    
    open func canPush() -> Bool {
        guard !isFinished else {
            return false
        }
        
        switch layoutAction {
        case .push, .continuousPush, .continuousPushThenFinish:
            return true
        case .pushSection, .finish:
            return false
        }
    }
    
    open func push(_ item: CGPoint) {
        guard canPush() else {
            return
        }
        layout.push(item)
    }
    
    // MARK: - Push New Section
    
    open func canPushSection() -> Bool {
        guard !isFinished else {
            return false
        }
        
        switch layoutAction {
        case .pushSection, .continuousPush:
            return true
        case .push, .continuousPushThenFinish, .finish:
            return false
        }
    }
    
    open func pushSection(_ item: CGPoint) {
        guard canPushSection() else {
            return
        }
        layout.pushSection(item)
    }
    
    // MARK: - Modify
    
    open func update(_ item: CGPoint, at position: ObjectLayout.Position) {
        guard isFinished || layoutAction.isFinishable, let bindings = itemBindings[position] else {
            layout.update(item, at: position)
            return
        }
        
        let currentPoint = layout.item(at: position)
        let rotation = rotationAngle.radians
        var newLayout = layout
        
        newLayout.update(item, at: position)
        
        if let rotationCenter = rotationCenter, rotation != 0 {
            let center = point(with: rotationCenter)
            let line = Line(start: currentPoint.rotated(origin: center, angle: -rotation),
                            end: item.rotated(origin: center, angle: -rotation))
            
            for binding in bindings {
                let position = binding.position
                let dx = line.dx * binding.offset.x
                let dy = line.dy * binding.offset.y
                let point = newLayout.item(at: position)
                    .rotated(origin: center, angle: -rotation)
                    .applying(.init(translationX: dx, y: dy))
                    .rotated(origin: center, angle: rotation)
                newLayout.update(point, at: position)
            }
        } else {
            let line = Line(start: currentPoint, end: item)
            
            for binding in bindings {
                let position = binding.position
                let dx = line.dx * binding.offset.x
                let dy = line.dy * binding.offset.y
                let point = newLayout.item(at: position)
                    .applying(.init(translationX: dx, y: dy))
                newLayout.update(point, at: position)
            }
        }
        
        layout = newLayout
    }
    
    @discardableResult
    open func updateLast(_ item: CGPoint) -> Bool {
        guard !layout.isEmpty else {
            return false
        }
        
        let nSection = layout.count - 1
        let nItem = layout[nSection].endIndex - 1
        let position = ObjectLayout.Position(item: nItem, section: nSection)
        
        update(item, at: position)
        
        return true
    }
    
    // MARK: - Rotate
    
    @discardableResult
    open func setRotationCenter(_ center: PointDescriptor?) -> Bool {
        guard isFinished || layoutAction.isFinishable else {
            return false
        }
        
        rotationCenter = center
        
        update()
        
        return true
    }
    
    @discardableResult
    open func rotate(angle: Angle) -> Bool {
        guard isFinished || layoutAction.isFinishable else {
            return false
        }
        guard let centerDescriptor = rotationCenter else {
            return false
        }
        
        let center = point(with: centerDescriptor)
        let dRotation = angle.radians - rotationAngle.radians
        var newLayout = layout
        
        for (section, points) in layout.enumerated() {
            for (item, point) in points.enumerated() {
                let position = ObjectLayout.Position(item: item, section: section)
                let point = point
                    .rotated(origin: center, angle: dRotation)
                newLayout.update(point, at: position)
            }
        }
        
        rotationAngle = angle
        layout = newLayout
        
        return true
    }
    
    // MARK: - Transform
    
    @discardableResult
    open func translate(x: CGFloat, y: CGFloat) -> Bool {
        guard isFinished || layoutAction.isFinishable else {
            return false
        }
        
        var translatedLayout = layout
        
        for (section, points) in translatedLayout.enumerated() {
            for (item, point) in points.enumerated() {
                let newPoint = CGPoint(x: point.x + x, y: point.y + y)
                let position = ObjectLayout.Position(item: item, section: section)
                translatedLayout.update(newPoint, at: position)
            }
        }
        
        layout = translatedLayout
        
        return true
    }
    
    @discardableResult
    open func scale(x sx: CGFloat, y sy: CGFloat) -> Bool {
        guard isFinished || layoutAction.isFinishable else {
            return false
        }
        
        var scaledLayout = layout
        
        for (section, points) in layout.enumerated() {
            for (item, point) in points.enumerated() {
                let point = point.applying(.init(scaleX: sx, y: sy))
                scaledLayout.update(point, at: .init(item: item, section: section))
            }
        }
        
        if case let .fixed(center) = rotationCenter {
            let scaledCenter = center
                .applying(.init(scaleX: sx, y: sy))
            rotationCenter = .fixed(scaledCenter)
        }
        
        layout = scaledLayout
        
        return true
    }
    
    // MARK: - Finish
    
    open func canFinish() -> Bool {
        guard !isFinished else {
            return false
        }
        return layoutAction.isFinishable
    }
    
    open func markAsFinished() {
        guard layoutAction.isFinishable else {
            return
        }
        
        isFinished = true
        
        layoutDidUpdate()
        update()
    }
    
    // MARK: - Selection
    
    open func selectionTest(point: CGPoint, range: CGFloat) -> Bool {
        mainGraphics.contains { drawable in
            guard let pathRenderer = drawable as? PathGraphicsRenderer else {
                return false
            }
            return pathRenderer.contains(point: point, range: range)
        }
    }
    
    open func selectionTest(rect: CGRect) -> Bool {
        let selectionUtil = SelectionUtil(rect)
        
        return layout.contains { items in
            selectionUtil.selects(linesBetween: items, isClosed: false)
        }
    }
    
    // MARK: - Drawing
    
    private func shouldDraw(with strategy: DrawingStrategy) -> Bool {
        guard !strategy.contains(.always) else {
            return true
        }
        guard !isFinished else {
            return strategy.contains(.whenFinished)
        }
        
        return layoutAction.isFinishable
            ? strategy.contains(.whenFinishable)
            : strategy.contains(.beforeFinishable)
    }
    
    open func makePreliminaryGraphics() -> [Drawable] {
        let method = PathGraphicsRenderer.Method.stroke(lineWidth: lineWidth, dash: [3])
        let renderer = PathGraphicsRenderer(method: method, color: strokeColor) { path in
            layout.forEach { items in
                if items.count > 1 {
                    path.addLines(between: items)
                } else if let item = items.first{
                    path.addLines(between: [item, item])
                }
            }
        }
        
        return [renderer]
    }
    
    open func makeMainGraphics() -> [Drawable] {
        let method = PathGraphicsRenderer.Method.stroke(lineWidth: lineWidth)
        let renderer = PathGraphicsRenderer(method: method, color: strokeColor) { path in
            layout.forEach { items in
                if items.count > 1 {
                    path.addLines(between: items)
                } else if let item = items.first{
                    path.addLines(between: [item, item])
                }
            }
        }
        
        return [renderer]
    }
    
    open func update() {
        if shouldDraw(with: preliminaryGraphicsDrawingStrategy) {
            preliminaryGraphics = makePreliminaryGraphics()
        } else {
            preliminaryGraphics.removeAll()
        }
        
        if shouldDraw(with: mainGraphicsDrawingStrategy) {
            let graphics = makeMainGraphics()
            
            mainGraphics = graphics
            pathOfMainGraphics = graphics
                .compactMap(\.cgPath)
                .reduce(CGMutablePath()) { mutablePath, path in
                    mutablePath.addPath(path)
                    return mutablePath
                }
        } else {
            mainGraphics.removeAll()
            pathOfMainGraphics = nil
        }
        
        redrawHandler?()
    }
    
    open func draw(context: CGContext) {
        for drawable in preliminaryGraphics + mainGraphics {
            let builtIn = drawable is BasicGraphicsRenderer || drawable is PathGraphicsRenderer
            
            if builtIn {
                drawable.draw(context: context)
            } else {
                context.saveGState()
                drawable.draw(context: context)
                context.restoreGState()
            }
        }
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case layout
        case lineWidth
        case strokeColor    // ObjectRenderer.Color
        case fillColor      // ObjectRenderer.Color
        case rotationCenter
        case rotationAngle
        case isFinished
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        commonInit()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        layout          = try container.decode(ObjectLayout.self, forKey: .layout)
        lineWidth       = try container.decode(CGFloat.self, forKey: .lineWidth)
        strokeColor     = try container.decodeIfPresent(Color.self, forKey: .strokeColor)?.platformColor ?? .black
        fillColor       = try container.decodeIfPresent(Color.self, forKey: .fillColor)?.platformColor ?? .white
        rotationCenter  = try container.decodeIfPresent(PointDescriptor.self, forKey: .rotationCenter)
        rotationAngle   = try container.decode(Angle.self, forKey: .rotationAngle)
        isFinished      = try container.decode(Bool.self, forKey: .isFinished)
        
        layoutDidUpdate()
        update()
    }
    
    open func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(layout, forKey: .layout)
        try container.encode(lineWidth, forKey: .lineWidth)
        try container.encodeIfPresent(Color(color: strokeColor), forKey: .strokeColor)
        try container.encodeIfPresent(Color(color: fillColor), forKey: .fillColor)
        try container.encodeIfPresent(rotationCenter, forKey: .rotationCenter)
        try container.encode(rotationAngle, forKey: .rotationAngle)
        try container.encode(isFinished, forKey: .isFinished)
    }
    
}
