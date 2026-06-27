//
//  FieldCoderType.swift
//  CoreStore
//
//  Copyright © 2020 John Rommel Estropia
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
import CoreData


// MARK: - FieldCoderType

/**
 Types that implement encoding to and decoding from `Data` to be used in `Field.Coded` properties' `coder:` argument.
 ```
 class Person: CoreStoreObject {

     @Field.Coded("profile", coder: FieldCoders.Json.self)
     var profile: Profile = .init()
 }
 ```
 */
public protocol FieldCoderType {

    /**
     The type to encode to and decode from `Data`
     */
    associatedtype FieldStoredValue

    /**
     Encodes the value to `Data`
     */
    static func encodeToStoredData(_ fieldValue: FieldStoredValue?) -> Data?

    /**
     Decodes the value from `Data`
     */
    static func decodeFromStoredData(_ data: Data?) -> FieldStoredValue?
}
