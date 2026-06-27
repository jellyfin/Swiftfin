//
//  String+KeyPaths.swift
//  CoreStore
//
//  Copyright © 2019 John Rommel Estropia
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

import CoreData
import Foundation


// MARK: - KeyPathString

extension KeyPathString {

    /**
     Extracts the keyPath string from the property.
     ```
     let keyPath = String(keyPath: \Person.nickname)
     ```
     */
    public init<O: NSManagedObject, V: AllowedObjectiveCKeyPathValue>(keyPath: KeyPath<O, V>) {

        self = keyPath.cs_keyPathString
    }

    /**
     Extracts the keyPath string from the property.
     ```
     let keyPath = String(keyPath: \Person.nickname)
     ```
     */
    public init<O: CoreStoreObject, K: KeyPathStringConvertible>(keyPath: KeyPath<O, K>) {

        self = O.meta[keyPath: keyPath].cs_keyPathString
    }

    /**
     Extracts the keyPath string from the property.
     ```
     let keyPath = String(keyPath: \Person.nickname)
     ```
     */
    public init<O: DynamicObject, T, V>(keyPath: Where<O>.Expression<T, V>) {

        self = keyPath.cs_keyPathString
    }
}
