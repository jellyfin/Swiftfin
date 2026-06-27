//
//  FieldCoders.Plist.swift
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


// MARK: - FieldCoders

extension FieldCoders {

    // MARK: - Plist

    /**
     A `FieldCoderType` that implements Binary-Plist encoding and decoding of `Codable` values.
     - Important: Due to restrictions of `JSONEncoder`, the value will be contained in single-item array before encoding.
     */
    public struct Plist<V: Codable>: FieldCoderType {

        // MARK: FieldCoderType

        public typealias FieldStoredValue = V

        public static func encodeToStoredData(_ fieldValue: FieldStoredValue?) -> Data? {

            guard let fieldValue = fieldValue else {

                return nil
            }
            return try! PropertyListEncoder().encode([fieldValue])
        }

        public static func decodeFromStoredData(_ data: Data?) -> FieldStoredValue? {

            guard let data = data else {

                return nil
            }
            return try! PropertyListDecoder().decode([FieldStoredValue].self, from: data).first
        }
    }
}
