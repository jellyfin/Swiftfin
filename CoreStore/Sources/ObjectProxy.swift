//
//  ObjectProxy.swift
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

import CoreData
import Foundation


// MARK: - ObjectProxy

/**
 An `ObjectProxy` is only used when overriding getters and setters for `CoreStoreObject` properties. Custom getters and setters are implemented as a closure that "overrides" the default property getter/setter. The closure receives an `ObjectProxy<O>`, which acts as a fast, type-safe KVC interface for `CoreStoreObject`. The reason a `CoreStoreObject` instance is not passed directly is because the Core Data runtime is not aware of `CoreStoreObject` properties' static typing, and so loading those info every time KVO invokes this accessor method incurs a heavy performance hit (especially in KVO-heavy operations such as `ListMonitor` observing.) When accessing the property value from `ObjectProxy<O>`, make sure to use `ObjectProxy<O>.$property.primitiveValue` instead of `ObjectProxy<O>.$property.value`, which would execute the same accessor again recursively.
 */
@dynamicMemberLookup
public struct ObjectProxy<O: CoreStoreObject> {

    /**
     Returns the value for the property identified by a given key.
     */
    public subscript<OBase, V>(
        dynamicMember member: KeyPath<O, FieldContainer<OBase>.Stored<V>>
    ) -> FieldProxy<V> {

        return .init(rawObject: self.rawObject, keyPath: member)
    }

    /**
     Returns the value for the property identified by a given key.
     */
    public subscript<OBase, V>(
        dynamicMember member: KeyPath<O, FieldContainer<OBase>.Virtual<V>>
    ) -> FieldProxy<V> {

        return .init(rawObject: self.rawObject, keyPath: member)
    }

    /**
     Returns the value for the property identified by a given key.
     */
    public subscript<OBase, V>(
        dynamicMember member: KeyPath<O, FieldContainer<OBase>.Coded<V>>
    ) -> FieldProxy<V> {

        return .init(rawObject: self.rawObject, keyPath: member)
    }


    // MARK: Internal

    internal let rawObject: CoreStoreManagedObject

    internal init(_ rawObject: CoreStoreManagedObject) {

        self.rawObject = rawObject
    }


    // MARK: - FieldProxy

    public struct FieldProxy<V> {

        // MARK: Public

        /**
         Returns the value for the specified property from the object’s private internal storage.

         This method is used primarily to implement custom accessor methods that need direct access to the object's private storage.
         */
        public var primitiveValue: V? {

            get {

                return self.getPrimitiveValue()
            }
            nonmutating set {

                self.setPrimitiveValue(newValue)
            }
        }

        /**
         Returns the value for the property identified by a given key.
         */
        public var value: V {

            get {

                return self.getValue()
            }
            nonmutating set {

                self.setValue(newValue)
            }
        }


        // MARK: Internal

        internal init<OBase>(
            rawObject: CoreStoreManagedObject,
            keyPath: KeyPath<O, FieldContainer<OBase>.Stored<V>>
        ) {

            self.init(rawObject: rawObject, field: O.meta[keyPath: keyPath])
        }

        internal init<OBase>(
            rawObject: CoreStoreManagedObject,
            keyPath: KeyPath<O, FieldContainer<OBase>.Virtual<V>>
        ) {

            self.init(rawObject: rawObject, field: O.meta[keyPath: keyPath])
        }

        internal init<OBase>(
            rawObject: CoreStoreManagedObject,
            keyPath: KeyPath<O, FieldContainer<OBase>.Coded<V>>
        ) {

            self.init(rawObject: rawObject, field: O.meta[keyPath: keyPath])
        }

        internal init<OBase>(
            rawObject: CoreStoreManagedObject,
            field: FieldContainer<OBase>.Stored<V>
        ) {

            let keyPathString = field.keyPath
            self.getValue = {

                return type(of: field).read(field: field, for: rawObject) as! V
            }
            self.setValue = {

                type(of: field).modify(field: field, for: rawObject, newValue: $0)
            }
            self.getPrimitiveValue = {

                return V.cs_fromFieldStoredNativeType(
                    rawObject.primitiveValue(forKey: keyPathString) as! V.FieldStoredNativeType
                )
            }
            self.setPrimitiveValue = {

                rawObject.willChangeValue(forKey: keyPathString)
                defer {
                    
                    rawObject.didChangeValue(forKey: keyPathString)
                }
                rawObject.setPrimitiveValue(
                    $0.cs_toFieldStoredNativeType(),
                    forKey: keyPathString
                )
            }
        }

        internal init<OBase>(
            rawObject: CoreStoreManagedObject,
            field: FieldContainer<OBase>.Virtual<V>
        ) {

            let keyPathString = field.keyPath
            self.getValue = {

                return type(of: field).read(field: field, for: rawObject) as! V
            }
            self.setValue = {

                type(of: field).modify(field: field, for: rawObject, newValue: $0)
            }
            self.getPrimitiveValue = {

                switch rawObject.primitiveValue(forKey: keyPathString) {

                case let value as V:
                    return value

                case nil,
                     is NSNull,
                     _? /* any other unrelated type */ :
                    return nil
                }
            }
            self.setPrimitiveValue = {
                
                rawObject.setPrimitiveValue(
                    $0,
                    forKey: keyPathString
                )
            }
        }

        internal init<OBase>(
            rawObject: CoreStoreManagedObject,
            field: FieldContainer<OBase>.Coded<V>
        ) {

            let keyPathString = field.keyPath
            self.getValue = {

                return type(of: field).read(field: field, for: rawObject) as! V
            }
            self.setValue = {

                type(of: field).modify(field: field, for: rawObject, newValue: $0)
            }
            self.getPrimitiveValue = {

                switch rawObject.primitiveValue(forKey: keyPathString) {

                case let valueBox as Internals.AnyFieldCoder.TransformableDefaultValueCodingBox:
                    rawObject.setPrimitiveValue(valueBox.value, forKey: keyPathString)
                    return valueBox.value as? V

                case let value as V:
                    return value

                case nil,
                     is NSNull,
                      _? /* any other unrelated type */ :
                     return nil
                }
            }
            self.setPrimitiveValue = {
                
                rawObject.willChangeValue(forKey: keyPathString)
                defer {

                    rawObject.didChangeValue(forKey: keyPathString)
                }
                rawObject.setPrimitiveValue(
                    $0,
                    forKey: keyPathString
                )
            }
        }


        // MARK: Private

        private let getValue: () -> V
        private let setValue: (V) -> Void
        private let getPrimitiveValue: () -> V?
        private let setPrimitiveValue: (V?) -> Void
    }
}
