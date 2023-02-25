import XCTest
@testable import XcapKit

private class TestObject: SettingMonitor {
    
    let undoManager: UndoManager? = .init()
    
    @Setting var value = 0
    
    init() {
        registerSettings {
            
        }
    }
    
}

class SettingTests: XCTestCase {
    
    func test_observe_setting() {
        let expectation = XCTestExpectation()
        let expectedValues = [0, 3, 0, 3]
        var values: [Int] = []
        
        let object = TestObject()
        let observation = object.observeSetting(\.$value) { value in
            values.append(value)
            
            if values == expectedValues {
                expectation.fulfill()
            }
        }
        let undoActionName = "Undo Value"
        
        object.$value.undoMode = .enable(name: undoActionName)
        object.value = 3
        
        XCTAssertEqual(object.undoManager?.undoActionName, undoActionName)
        
        object.undoManager?.undo()
        object.undoManager?.redo()
        
        wait(for: [expectation], timeout: 0)
        
        _ = observation
    }
    
    func test_store() {
        var observationSet: Set<SettingObservation> = []
        var observationArray: [SettingObservation] = []
        let object = TestObject()
        
        object.observeSetting(\.$value) { _ in
            
        }
        .store(in: &observationSet)
        
        object.observeSetting(\.$value) { _ in
            
        }
        .store(in: &observationArray)
        
        XCTAssertEqual(observationSet.count, 1)
        XCTAssertEqual(observationArray.count, 1)
    }
    
}
