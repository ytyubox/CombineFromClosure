import XCTest
import Combine
@testable import CombineFromClosure

final class CombineFromClosureTests: XCTestCase {
    func testFutureInitClosureWillDisappearAfterInit() {
        var object:NSObject? = NSObject()
        weak var theWeak = object
        XCTAssertNotNil(theWeak)
        _ = Future<Int, Error> {
            [object] promise in
            _ = object
            promise(.success(1))
        }
        object = nil
        XCTAssertNil(theWeak)
    }

    func testFutureCanNotRetry() {
        var i = 0
        var captured = [Capture<Int>]()
        let binding = Future<Int, Error>{ promise in
            guard  i > 2 else {
                i += 1
                promise(.failure(anyError()))
                return
            }
            return promise(.success(i))
        }.retry(3)
        .sink { (completion) in
            switch completion {
            case .failure(let error): captured.append(.failure(error as NSError))
            case .finished: captured.append(.finished)
            }
        } receiveValue: { (i) in
            captured.append(.value(i))
        }
        XCTAssertEqual(captured, [.failure(anyError())])
        binding.cancel()
    }
    
    func testClosurePublisher() {
        var i = 0
        var captured = [Capture<Int>]()
        let binding = ClosurePublisher{ () throws -> Int in
            guard  i > 2 else {
                i += 1
                throw NSError(domain: "test", code: 0)
            }
            return i
        }.retry(3)
        .sink { (completion) in
            switch completion {
            case .failure(let error): captured.append(.failure(error as NSError))
            case .finished: captured.append(.finished)
            }
        } receiveValue: { (i) in
            captured.append(.value(i))
        }
        XCTAssertEqual(captured, [.value(3)])
        binding.cancel()
        
    }
    
   
}

func anyError() -> NSError {
    NSError(domain: "test", code: 0)
}

enum Capture<Value:Equatable>:Equatable {

    case value(Value)
    case finished
    case failure(NSError)
}
