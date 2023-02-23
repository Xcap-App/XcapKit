import XCTest
@testable import XcapKit

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
        class SettingsManager: SettingsMonitor {
            
            let undoManager: UndoManager? = .init()
            
            @Setting var setting = 0
            
            init() {
                registerSettings {
                    
                }
            }
            
        }
        
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 4
        
        var numberOfFullfillment = 0
        let observable = SettingsManager()
        let observation = observable.$setting.observe(options: [.initial, .new]) { value in
            if numberOfFullfillment == 0 && value == 0 {
                expectation.fulfill()
                numberOfFullfillment += 1
            } else if numberOfFullfillment == 1 && value == 3 {
                expectation.fulfill()
                numberOfFullfillment += 1
            } else if numberOfFullfillment == 2 && value == 0 {
                expectation.fulfill()
                numberOfFullfillment += 1
            } else if numberOfFullfillment == 3 && value == 3 {
                expectation.fulfill()
            }
        }
        
        observable.setting = 3
        observable.undoManager?.undo()
        observable.undoManager?.redo()
        
        wait(for: [expectation], timeout: 1)
        
        _ = observation
    }
    
}
