//
//  FieldCoders.DefaultNSSecureCoding.swift
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

    /**
     A `FieldCoderType` that implements the default Core Data transformable attribute behavior, which uses a `ValueTransformer` named `.secureUnarchiveFromDataTransformerName`.
     */
    public struct DefaultNSSecureCoding<T: DefaultNSSecureCodable>: FieldCoderType {

        // MARK: FieldCoderType

        public typealias FieldStoredValue = T

        public static func encodeToStoredData(_ fieldValue: FieldStoredValue?) -> Data? {

            return ValueTransformer(forName: self.transformerName)?.reverseTransformedValue(fieldValue) as? Data
        }

        public static func decodeFromStoredData(_ data: Data?) -> FieldStoredValue? {

            return ValueTransformer(forName: self.transformerName)?.transformedValue(data) as! FieldStoredValue?
        }


        // MARK: Internal

        internal static var transformerName: NSValueTransformerName {

            return .secureUnarchiveFromDataTransformerName
        }
    }
}


// MARK: - DefaultNSSecureCodable

/**
 Types that are supported by `FieldCoders.DefaultNSSecureCoding`
 */
public protocol DefaultNSSecureCodable: NSObject, NSSecureCoding {}

extension NSArray: DefaultNSSecureCodable {}

extension NSDictionary: DefaultNSSecureCodable {}

extension NSSet: DefaultNSSecureCodable {}

extension NSString: DefaultNSSecureCodable {}

extension NSNumber: DefaultNSSecureCodable {}

extension NSDate: DefaultNSSecureCodable {}

extension NSData: DefaultNSSecureCodable {}

extension NSURL: DefaultNSSecureCodable {}

extension NSUUID: DefaultNSSecureCodable {}

extension NSNull: DefaultNSSecureCodable {}
