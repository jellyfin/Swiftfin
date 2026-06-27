//
//  CoreStoreLogger.swift
//  CoreStore
//
//  Copyright © 2018 John Rommel Estropia
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation


// MARK: - LogLevel

/**
 The `LogLevel` indicates the severity of a log message.
 */
public enum LogLevel {
    
    case trace
    case notice
    case warning
    case fatal
}


// MARK: - CoreStoreLogger

/**
 Custom loggers should implement the `CoreStoreLogger` protocol and pass its instance to `CoreStoreDefaults.logger`. Calls to `log(...)`, `assert(...)`, and `abort(...)` are not tied to a specific queue/thread, so it is the implementer's job to handle thread-safety.
 */
public protocol CoreStoreLogger {
    
    /**
     Handles log messages sent by the `CoreStore` framework.
     
     - parameter level: the severity of the log message
     - parameter message: the log message
     - parameter fileName: the source file name
     - parameter lineNumber: the source line number
     - parameter functionName: the source function name
     */
    func log(
        level: LogLevel,
        message: String,
        fileName: StaticString,
        lineNumber: Int,
        functionName: StaticString
    )

    /**
     Handles errors sent by the `CoreStore` framework.
     
     - parameter error: the error
     - parameter message: the error message
     - parameter fileName: the source file name
     - parameter lineNumber: the source line number
     - parameter functionName: the source function name
     */
    func log(
        error: CoreStoreError,
        message: String,
        fileName: StaticString,
        lineNumber: Int,
        functionName: StaticString
    )

    /**
     Handles assertions made throughout the `CoreStore` framework.
     
     - parameter condition: the assertion condition
     - parameter message: the assertion message
     - parameter fileName: the source file name
     - parameter lineNumber: the source line number
     - parameter functionName: the source function name
     */
    func assert(
        _ condition: @autoclosure () -> Bool,
        message: @autoclosure () -> String,
        fileName: StaticString,
        lineNumber: Int,
        functionName: StaticString
    )

    /**
     Handles fatal errors made throughout the `CoreStore` framework. The app wil terminate after this method is called.
     - Important: Implementers may guarantee that the function doesn't return, either by calling another `Never` function such as `fatalError()` or `abort()`, or by raising an exception. If the implementation does not terminate the app, CoreStore will call an internal `fatalError()` to do so.
     
     - parameter message: the fatal error message
     - parameter fileName: the source file name
     - parameter lineNumber: the source line number
     - parameter functionName: the source function name
     */
    func abort(
        _ message: String,
        fileName: StaticString,
        lineNumber: Int,
        functionName: StaticString
    )
}

extension CoreStoreLogger {
    
    public func abort(
        _ message: String,
        fileName: StaticString,
        lineNumber: Int,
        functionName: StaticString
    ) {

        Swift.fatalError(message, file: fileName, line: UInt(lineNumber))
    }
}
