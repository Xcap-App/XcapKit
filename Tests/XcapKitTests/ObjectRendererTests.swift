import XCTest
@testable import XcapKit

class TestRenderer: ObjectRenderer {
    override var layoutAction: ObjectRenderer.LayoutAction {
        layout.first?.count != 2 ? .push(finishable: false) : .finish
    }
    
    override var itemBindings: [ObjectLayout.Position : [ObjectRenderer.ItemBinding]] {
        let target1 = ObjectLayout.Position.zero
        let binding1 = ObjectRenderer.ItemBinding(
            position: ObjectLayout.Position(item: 1, section: 0),
            offset: CGPoint(x: -1, y: -1)
        )
        let target2 = ObjectLayout.Position(item: 1, section: 0)
        let binding2 = ObjectRenderer.ItemBinding(
            position: ObjectLayout.Position.zero,
            offset: CGPoint(x: -1, y: -1)
        )
        return [
            target1: [binding1],
            target2: [binding2]
        ]
    }
}

class LineSegment: ObjectRenderer {
    override var layoutAction: ObjectRenderer.LayoutAction {
        layout.first?.count != 2 ? .push(finishable: false) : .finish
    }
}

class SectionsOf2: ObjectRenderer {
    override var layoutAction: ObjectRenderer.LayoutAction {
        if layout.count < 2 {
            return layout.first?.count != 2 ? .push(finishable: false) : .pushSection(finishable: false)
        } else {
            return layout.last?.count != 2 ? .push(finishable: false) : .finish
        }
    }
}

final class ObjectRendererTests: XCTestCase {
    
    func test_object_renderer() {
        let object = TestRenderer()
        let item1 = CGPoint(x: 0, y: 0)
        let item2 = CGPoint(x: 10, y: 10)
        
        XCTAssertTrue(object.canPush())
        XCTAssertFalse(object.canPushSection())
        XCTAssertFalse(object.canFinish())
        
        object.push(item1)
        XCTAssertTrue(object.canPush())
        XCTAssertFalse(object.canPushSection())
        XCTAssertFalse(object.canFinish())
        
        object.push(item2)
        XCTAssertFalse(object.canPush())
        XCTAssertFalse(object.canPushSection())
        XCTAssertTrue(object.canFinish())
        
        object.markAsFinished()
        XCTAssertFalse(object.canPush())
        XCTAssertFalse(object.canPushSection())
        XCTAssertFalse(object.canFinish())
        XCTAssertEqual(object.layout.data, [[item1, item2]])
        
        object.push(.zero)
        XCTAssertEqual(object.layout.data, [[item1, item2]])
        
        object.pushSection(.zero)
        XCTAssertEqual(object.layout.data, [[item1, item2]])
        
        object.update(CGPoint(x: 0, y: 5), at: .zero)
        XCTAssertEqual(object.layout.data, [[CGPoint(x: 0, y: 5), CGPoint(x: 10, y: 5)]])
        
        object.updateLast(CGPoint(x: 10, y: 10))
        XCTAssertEqual(object.layout.data, [[CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 10)]])
        
        let angle = Angle.degrees(90)
        object.setRotationCenter(.item(.zero))
        object.rotate(angle: angle)
        XCTAssertEqual(object.layout.data, [[.zero, .init(x: -10, y: 10)]])
    }
    
    func test_single_section() {
        let lineSeg = LineSegment()
        
        XCTAssertTrue(lineSeg.canPush())
        XCTAssertFalse(lineSeg.canPushSection())
        XCTAssertFalse(lineSeg.canFinish())
        
        lineSeg.push(.zero)
        XCTAssertTrue(lineSeg.canPush())
        XCTAssertFalse(lineSeg.canPushSection())
        XCTAssertFalse(lineSeg.canFinish())
        
        lineSeg.push(.zero)
        XCTAssertFalse(lineSeg.canPush())
        XCTAssertFalse(lineSeg.canPushSection())
        XCTAssertTrue(lineSeg.canFinish())
        
        lineSeg.markAsFinished()
        XCTAssertFalse(lineSeg.canPush())
        XCTAssertFalse(lineSeg.canPushSection())
        XCTAssertFalse(lineSeg.canFinish())
        XCTAssertEqual(lineSeg.layout.data, [[.zero, .zero]])
    }
    
    func test_multi_section() {
        let secsOf2 = SectionsOf2()
        
        XCTAssertTrue(secsOf2.canPush())
        XCTAssertFalse(secsOf2.canPushSection())
        XCTAssertFalse(secsOf2.canFinish())
        
        secsOf2.push(.zero)
        XCTAssertTrue(secsOf2.canPush())
        XCTAssertFalse(secsOf2.canPushSection())
        XCTAssertFalse(secsOf2.canFinish())
        
        secsOf2.push(.zero)
        XCTAssertFalse(secsOf2.canPush())
        XCTAssertTrue(secsOf2.canPushSection())
        XCTAssertFalse(secsOf2.canFinish())
        
        secsOf2.pushSection(.zero)
        XCTAssertTrue(secsOf2.canPush())
        XCTAssertFalse(secsOf2.canPushSection())
        XCTAssertFalse(secsOf2.canFinish())
        
        secsOf2.push(.zero)
        XCTAssertFalse(secsOf2.canPush())
        XCTAssertFalse(secsOf2.canPushSection())
        XCTAssertTrue(secsOf2.canFinish())
        
        secsOf2.markAsFinished()
        XCTAssertFalse(secsOf2.canPush())
        XCTAssertFalse(secsOf2.canPushSection())
        XCTAssertFalse(secsOf2.canFinish())
        XCTAssertEqual(secsOf2.layout.data, [[.zero, .zero], [.zero, .zero]])
    }
    
}
