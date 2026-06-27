//
//  CoreStoreStrings.swift
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


// MARK: - XcodeDataModelFileName

/**
 A `String` that pertains to the name of an *.xcdatamodeld file (without the file extension).
 */
public typealias XcodeDataModelFileName = String


// MARK: - ModelConfiguration

/**
 An `Optional<String>` that pertains to the name of a "Configuration" which particular groups of entities may belong to. When `nil`, pertains to the default configuration which includes all entities.
 */
public typealias ModelConfiguration = String?


// MARK: - ModelVersion

/**
 An `String` that pertains to the name of a versioned *.xcdatamodeld file (without the file extension). Model version strings don't necessarily have to be numeric or ordered in any way. The migration sequence will always be decided by (or the lack of) the `MigrationChain`.
 */
public typealias ModelVersion = String


// MARK: - EntityName

/**
 An `String` that pertains to an Entity name.
 */
public typealias EntityName = String


// MARK: - ClassName

/**
 An `String` that pertains to a dynamically-accessable class name (usable with NSClassFromString(...)).
 */
public typealias ClassName = String


// MARK: - KeyPathString

/**
 An `String` that pertains to a attribute keyPaths.
 */
public typealias KeyPathString = String
