import XCTest
@testable import XcapKit

private class TestObject: SettingsMonitor {
    
    let undoManager: UndoManager? = .init()
    
    @Setting var value = 0
    
    init() {
        registerSettings()
    }
    
}

class SettingTests: XCTestCase {
    
    func test_undo() {
        let setting = Setting(wrappedValue: 0)
        let undoManager = UndoManager()
        
        setting.wrappedValue = 1
        setting.undoManager = undoManager
        
        // 1
        setting.wrappedValue = 2
        undoManager.undo()
        XCTAssertEqual(setting.wrappedValue, 1)
        
        // 2
        undoManager.redo()
        XCTAssertEqual(setting.wrappedValue, 2)
        
        // 3
        let undoActionName = "Line Width"
        setting.undoMode = .enable(name: undoActionName)
        setting.wrappedValue = 3
        XCTAssertEqual(undoManager.undoActionName, undoActionName)
        
        // 4
        undoManager.undo()
        XCTAssertEqual(undoManager.redoActionName, undoActionName)
    }
    
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
