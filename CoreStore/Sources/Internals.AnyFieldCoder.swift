//
//  Internals.AnyFieldCoder.swift
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


// MARK: - Internals

extension Internals {

    // MARK: - AnyFieldCoder

    internal struct AnyFieldCoder {

        // MARK: Internal

        internal let transformerName: NSValueTransformerName
        internal let transformer: Foundation.ValueTransformer
        internal let encodeToStoredData: (_ fieldValue: Any?) -> Data?
        internal let decodeFromStoredData: (_ data: Data?) -> Any?

        internal init<Coder: FieldCoderType>(_ fieldCoder: Coder.Type) {

            let transformer = CustomValueTransformer(fieldCoder: fieldCoder)
            self.transformerName = transformer.id
            self.transformer = transformer
            self.encodeToStoredData = {

                switch $0 {

                case let value as Coder.FieldStoredValue:
                    return fieldCoder.encodeToStoredData(value)

                case let valueBox as Internals.AnyFieldCoder.TransformableDefaultValueCodingBox:
                    return fieldCoder.encodeToStoredData(valueBox.value as! Coder.FieldStoredValue?)

                default:
                    return fieldCoder.encodeToStoredData(nil)
                }
            }
            self.decodeFromStoredData = { fieldCoder.decodeFromStoredData($0) }
        }

        internal init<V>(tag: UUID, encode: @escaping (V) -> Data?, decode: @escaping (Data?) -> V) {

            let transformer = CustomValueTransformer(tag: tag)
            self.transformerName = transformer.id
            self.transformer = transformer
            self.encodeToStoredData = { encode($0 as! V) }
            self.decodeFromStoredData = { decode($0) }
        }

        internal func register() {

            switch self.transformerName {

            case .secureUnarchiveFromDataTransformerName,
                 .isNotNilTransformerName,
                 .isNilTransformerName,
                 .negateBooleanTransformerName:
                return

            case let transformerName:
                Self.cachedCoders[transformerName] = self

                Foundation.ValueTransformer.setValueTransformer(
                    self.transformer,
                    forName: transformerName
                )
            }
        }


        // MARK: FilePrivate

        fileprivate static var cachedCoders: [NSValueTransformerName: AnyFieldCoder] = [:]


        // MARK: - TransformableDefaultValueCodingBox

        @objc(_CoreStore_Internals_TransformableDefaultValueCodingBox)
        internal final class TransformableDefaultValueCodingBox: NSObject, NSSecureCoding {

            // MARK: Internal

            @objc
            internal dynamic let transformerName: String

            @objc
            internal dynamic let data: Data

            @nonobjc
            internal let value: Any?

            internal init?(defaultValue: Any?, fieldCoder: Internals.AnyFieldCoder?) {

                guard
                    let fieldCoder = fieldCoder,
                    let defaultValue = defaultValue,
                    !(defaultValue is NSNull),
                    let data = fieldCoder.encodeToStoredData(defaultValue)
                    else {

                        return nil
                }
                self.transformerName = fieldCoder.transformerName.rawValue
                self.value = defaultValue
                self.data = data
            }


            // MARK: NSSecureCoding

            @objc
            dynamic class var supportsSecureCoding: Bool {

                return true
            }


            // MARK: NSCoding

            @objc
            dynamic required init?(coder aDecoder: NSCoder) {
                
                guard
                    case let transformerName as String = aDecoder.decodeObject(forKey: #keyPath(TransformableDefaultValueCodingBox.transformerName)),
                    let transformer = ValueTransformer(forName: .init(transformerName)),
                    case let data as Data = aDecoder.decodeObject(forKey: #keyPath(TransformableDefaultValueCodingBox.data)),
                    let value = transformer.reverseTransformedValue(data)
                    else {

                        return nil
                }
                self.transformerName = transformerName
                self.data = data
                self.value = value
            }

            @objc
            dynamic func encode(with coder: NSCoder) {

                coder.encode(self.data, forKey: #keyPath(TransformableDefaultValueCodingBox.data))
                coder.encode(self.transformerName, forKey: #keyPath(TransformableDefaultValueCodingBox.transformerName))
            }
        }
    }


    // MARK: - CustomValueTransformer

    fileprivate final class CustomValueTransformer: ValueTransformer {

        // MARK: FilePrivate

        fileprivate let id: NSValueTransformerName

        fileprivate init<Coder: FieldCoderType>(fieldCoder: Coder.Type) {

            self.id = .init(rawValue: "CoreStore.FieldCoders.CustomValueTransformer<\(String(reflecting: fieldCoder))>.transformerName")
        }

        fileprivate init(tag: UUID) {

            self.id = .init(rawValue: "CoreStore.FieldCoders.CustomValueTransformer<\(tag.uuidString)>.transformerName")
        }


        // MARK: ValueTransformer

        override class func transformedValueClass() -> AnyClass {

            return NSData.self
        }

        override class func allowsReverseTransformation() -> Bool {

            return true
        }

        override func transformedValue(_ value: Any?) -> Any? {

            return AnyFieldCoder.cachedCoders[self.id]?.encodeToStoredData(value) as Data?
        }

        override func reverseTransformedValue(_ value: Any?) -> Any? {

            return AnyFieldCoder.cachedCoders[self.id]?.decodeFromStoredData(value as! Data?)
        }
    }
}
