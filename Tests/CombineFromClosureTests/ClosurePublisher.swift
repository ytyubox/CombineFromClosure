//
/* 
 *		Created by 游宗諭 in 2021/3/17
 *		
 *		Using Swift 5.0
 *		
 *		Running on macOS 11.2
 */


import Foundation
import Combine

public struct ClosurePublisher<Output>:Publisher {
    internal init(c: @escaping () throws -> Output) {
        self.c = c
    }
    
    private let c: () throws -> Output
    public typealias Failure = Error

    public func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
            subscriber.receive(subscription: Inner(self, subscriber))
    }

    private typealias Parent = ClosurePublisher
    private final class Inner<Downstream>: Subscription, CustomStringConvertible, CustomReflectable, CustomPlaygroundDisplayConvertible
    where
        Downstream: Subscriber,
        Downstream.Input == Parent.Output,
        Downstream.Failure == Parent.Failure
    {
        private var parent: Parent?
        private var demand: Subscribers.Demand
        private var downstream: Downstream?
        private let lock = NSLock()

        var description: String { return "ClosureSubscription" }
        var customMirror: Mirror {
            lock.lock()
            defer { lock.unlock() }
            return Mirror(self, children: [
                "closurePublisher": parent as Any,
                "demand": demand
            ])
        }
        var playgroundDescription: Any { return description }
        
        fileprivate typealias Parent = ClosurePublisher
        fileprivate init(
            _ parent: Parent,
            _ subscriber: Downstream)
        {
            demand = .max(0)
            self.downstream = subscriber
            self.parent = parent
        }
        

        deinit {
            lock.unlock()
        }

        func request(_ d: Subscribers.Demand) {
            lock.lock()
            self.demand += d
            guard
                let parent = parent,
                demand > 0,
                let ds = downstream
            else {
                lock.unlock()
                return
            }
            do {
                
                let additional = ds.receive(try parent.c())
                demand += additional
            }
            catch {
                ds.receive(completion: .failure(error))
                demand = .max(0)
            }
            lock.unlock()
        }

        func cancel() {
            lock.lock()
            guard parent != nil else {
                lock.unlock()
                return
            }
            lock.unlock()

            parent = nil
            downstream = nil
        }
    }
}

