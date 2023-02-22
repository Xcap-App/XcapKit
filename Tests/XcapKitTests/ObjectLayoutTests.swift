import XCTest
@testable import XcapKit

final class ObjectLayoutTests: XCTestCase {
    
    func test_layout() {
        var layout = ObjectLayout()

        let section1: [[CGPoint]] = [[.zero]]
        layout.push(.zero)
        XCTAssertEqual(layout.data, section1)

        layout.push(.zero)
        XCTAssertEqual(layout.data, [[.zero, .zero]])

        layout.pushSection(.zero)
        XCTAssertEqual(layout.data, [[.zero, .zero], [.zero]])

        let item = CGPoint(x: 0, y: 1)
        let position = ObjectLayout.Position(item: 0, section: 1)
        
        layout.update(item, at: position)

        XCTAssertEqual(layout.first, [.zero, .zero])
        XCTAssertEqual(layout.last, [item])

        XCTAssertEqual(layout.index(after: 0), 1)
        XCTAssertEqual(layout.index(before: 1), 0)

        XCTAssertEqual(layout.item(at: position), item)

        XCTAssertEqual(layout.pop(), item)
        XCTAssertEqual(layout.data, [[.zero, .zero]])

        XCTAssertEqual(layout.popSection(), [.zero, .zero])
        XCTAssertEqual(layout.data, [])

        XCTAssertEqual(layout.popSection(), nil)
        XCTAssertEqual(layout.data, [])

        XCTAssertEqual(layout.pop(), nil)
        XCTAssertEqual(layout.data, [])
    }
    
}
