import XCTest
import XcapKit

private class TestObject: SettingMonitor {
    
    let undoManager: UndoManager? = .init()
    
    @Setting var value = 0
    
    init() {
        registerSettings {
            
        }
    }
    
}

class SettingTests: XCTestCase {
    
    func test_observation() {
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
        
        object.value = 3
        object.undoManager?.undo()
        object.undoManager?.redo()
        print(values)
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
