//
//  CoreStore+Logging.swift
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


// MARK: - Internal

extension Internals {

    // MARK: Internal

    @inline(__always)
    internal static func log(
        _ level: LogLevel,
        message: String,
        fileName: StaticString = #file,
        lineNumber: Int = #line,
        functionName: StaticString = #function
    ) {

        CoreStoreDefaults.logger.log(
            level: level,
            message: message,
            fileName: fileName,
            lineNumber: lineNumber,
            functionName: functionName
        )
    }

    @inline(__always)
    internal static func log(
        _ error: CoreStoreError,
        _ message: String,
        fileName: StaticString = #file,
        lineNumber: Int = #line,
        functionName: StaticString = #function
    ) {

        CoreStoreDefaults.logger.log(
            error: error,
            message: message,
            fileName: fileName,
            lineNumber: lineNumber,
            functionName: functionName
        )
    }

    @inline(__always)
    internal static func assert(
        _ condition: @autoclosure () -> Bool,
        _ message: @autoclosure () -> String,
        fileName: StaticString = #file,
        lineNumber: Int = #line,
        functionName: StaticString = #function
    ) {

        CoreStoreDefaults.logger.assert(
            condition(),
            message: message(),
            fileName: fileName,
            lineNumber: lineNumber,
            functionName: functionName
        )
    }

    @inline(__always)
    internal static func abort(
        _ message: String,
        fileName: StaticString = #file,
        lineNumber: Int = #line,
        functionName: StaticString = #function
    ) -> Never  {

        CoreStoreDefaults.logger.abort(
            message,
            fileName: fileName,
            lineNumber: lineNumber,
            functionName: functionName
        )
        Swift.fatalError(message, file: fileName, line: UInt(lineNumber))
    }
}
