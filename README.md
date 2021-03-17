# CombineFromClosure


## Future Can't retry

```swift
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
}
```

## With ClosurePublisher, it can retry

```swift
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
```
