//
//  FunctionalOperations.swift
//  Operations
//
//  Created by Daniel Thorpe on 21/12/2015.
//
//

import Foundation

/**
 # Map Operation
 
 An `Operation` subclass which accepts a map transform closure. Because it
 conforms to both `ResultOperationType` and `AutomaticInjectionOperationType`
 it can be used to create an array of operations which transform state.
 
 - discussion: Note that the closure is invoked as the operation's *work* on
 an operation queue. So it should perform synchronous computation, although
 it will be executed asynshronously.

*/
public class MapOperation<T, U>: Operation, ResultOperationType, AutomaticInjectionOperationType {

    /// - returns: the requirement an optional type T
    public var requirement: T? = .None

    /// - returns: the result, an optional type U
    public var result: U? = .None

    let transform: T -> U

    /**
     Initializes an instance with an optional starting requirement, and an
     transform block.
     
     - parameter x: the value to the transformed. Note this is optional, as it
     can be injected after initialization, but before execution.
     - parameter transform: a closure which maps a non-optional T to U!. Note
     that this closure will only be run if the requirement is non-nil.
    */
    public init(x: T? = .None, transform: T -> U) {
        self.requirement = x
        self.transform = transform
        super.init()
        name = "Map"
    }

    public override func execute() {
        result = requirement.flatMap(transform)
        finish()
    }
}

extension ResultOperationType where Self: Operation {

    /**
     Map the result of an `Operation` which conforms to `ResultOperationType`.
     
     ```swift
     let getLocation = UserLocationOperation()
     let toString = getLocation.mapResult { $0.map { "\($0)" } ?? "No location received" }
     queue.addOperations(getLocation, toString)
     ```

    */
    public func mapOperation<U>(transform: Result -> U) -> MapOperation<Result, U> {
        let map: MapOperation<Result, U> = MapOperation(transform: transform)
        map.injectResultFromDependency(self) { operation, dependency, errors in
            if errors.isEmpty {
                operation.requirement = dependency.result
            }
            else {
                operation.cancelWithError(AutomaticInjectionError.DependencyFinishedWithErrors(errors))
            }
        }
        return map
    }
}

/**
 # Filter Operation

 An `Operation` subclass which accepts an include element closure. Because it
 conforms to both `ResultOperationType` and `AutomaticInjectionOperationType`
 it can be used to create an array of operations which transform state.
 
 - discussion: Note that the closure is invoked as the operation's *work* on
 an operation queue. So it should perform synchronous computation, although
 it will be executed asynshronously.

*/
public class FilterOperation<Element>: Operation, ResultOperationType, AutomaticInjectionOperationType {

    /// - returns: the requirement an optional type T
    public var requirement: Array<Element> = []

    /// - returns: the result, an optional type U
    public var result: Array<Element> = []

    let filter: Element -> Bool

    public init(source: Array<Element> = [], includeElement: Element -> Bool) {
        self.requirement = source
        self.filter = includeElement
        super.init()
        name = "Filter"
    }

    public override func execute() {
        result = requirement.filter(filter)
        finish()
    }
}

extension ResultOperationType where Self: Operation, Result: SequenceType {

    /**
     Filter the result of an `Operation` which conforms to `ResultOperationType` where 
     the Result is a SequenceType.
     
     ```swift
     let getLocation = UserLocationOperation()
     let toString = getLocation.mapResult { $0.map { "\($0)" } ?? "No location received" }
     queue.addOperations(getLocation, toString)
     ```
    */
    public func filterOperation(includeElement: Result.Generator.Element -> Bool) -> FilterOperation<Result.Generator.Element> {
        let filter: FilterOperation<Result.Generator.Element> = FilterOperation(includeElement: includeElement)
        filter.injectResultFromDependency(self) { operation, dependency, errors in
            if errors.isEmpty {
                operation.requirement = Array(dependency.result)
            }
            else {
                operation.cancelWithError(AutomaticInjectionError.DependencyFinishedWithErrors(errors))
            }
        }
        return filter
    }
}

