//
//  Value.Optional.swift
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


// MARK: - Deprecated

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
extension ValueContainer {
    
    public final class Optional<V: ImportableAttributeType>: AttributeKeyPathStringConvertible, AttributeProtocol {
        
        public init(
            _ keyPath: KeyPathString,
            initial: @autoclosure @escaping () -> V? = nil,
            isTransient: Bool = false,
            versionHashModifier: @autoclosure @escaping () -> String? = nil,
            renamingIdentifier: @autoclosure @escaping () -> String? = nil,
            customGetter: ((_ partialObject: PartialObject<O>) -> V?)? = nil,
            customSetter: ((_ partialObject: PartialObject<O>, _ newValue: V?) -> Void)? = nil,
            affectedByKeyPaths: @autoclosure @escaping () -> Set<String> = []) {

            self.keyPath = keyPath
            self.entityDescriptionValues = {
                (
                    attributeType: V.cs_rawAttributeType,
                    isOptional: true,
                    isTransient: isTransient,
                    allowsExternalBinaryDataStorage: false,
                    versionHashModifier: versionHashModifier(),
                    renamingIdentifier: renamingIdentifier(),
                    affectedByKeyPaths: affectedByKeyPaths(),
                    defaultValue: initial()?.cs_toQueryableNativeType()
                )
            }
            self.customGetter = customGetter
            self.customSetter = customSetter
        }
        
        public var value: ReturnValueType {

            get {

                Internals.assert(
                    self.rawObject != nil,
                    "Attempted to access values from a \(Internals.typeName(O.self)) meta object. Meta objects are only used for querying keyPaths and infering types."
                )
                return withExtendedLifetime(self.rawObject!) { (object) in

                    Internals.assert(
                        object.isRunningInAllowedQueue() == true,
                        "Attempted to access \(Internals.typeName(O.self))'s value outside it's designated queue."
                    )
                    if let customGetter = self.customGetter {

                        return customGetter(PartialObject<O>(object))
                    }
                    return (object.value(forKey: self.keyPath) as! V.QueryableNativeType?)
                        .flatMap(V.cs_fromQueryableNativeType)
                }
            }
            set {

                Internals.assert(
                    self.rawObject != nil,
                    "Attempted to access values from a \(Internals.typeName(O.self)) meta object. Meta objects are only used for querying keyPaths and infering types."
                )
                return withExtendedLifetime(self.rawObject!) { (object) in

                    Internals.assert(
                        object.isRunningInAllowedQueue() == true,
                        "Attempted to access \(Internals.typeName(O.self))'s value outside it's designated queue."
                    )
                    Internals.assert(
                        object.isEditableInContext() == true,
                        "Attempted to update a \(Internals.typeName(O.self))'s value from outside a transaction."
                    )
                    if let customSetter = self.customSetter {

                        return customSetter(PartialObject<O>(object), newValue)
                    }
                    object.setValue(
                        newValue?.cs_toQueryableNativeType(),
                        forKey: self.keyPath
                    )
                }
            }
        }

        public var cs_keyPathString: String {

            return self.keyPath
        }

        public typealias ObjectType = O
        public typealias DestinationValueType = V

        public typealias ReturnValueType = DestinationValueType?

        internal let keyPath: KeyPathString

        internal let entityDescriptionValues: () -> AttributeProtocol.EntityDescriptionValues
        internal var rawObject: CoreStoreManagedObject?

        internal private(set) lazy var getter: CoreStoreManagedObject.CustomGetter? = Internals.with { [unowned self] in

            guard let customGetter = self.customGetter else {

                return nil
            }
            let keyPath = self.keyPath
            return { (_ id: Any) -> Any? in

                let rawObject = id as! CoreStoreManagedObject
                rawObject.willAccessValue(forKey: keyPath)
                defer {

                    rawObject.didAccessValue(forKey: keyPath)
                }
                let value = customGetter(PartialObject<O>(rawObject))
                return value?.cs_toQueryableNativeType()
            }
        }

        internal private(set) lazy var setter: CoreStoreManagedObject.CustomSetter? = Internals.with { [unowned self] in

            guard let customSetter = self.customSetter else {

                return nil
            }
            let keyPath = self.keyPath
            return { (_ id: Any, _ newValue: Any?) -> Void in

                let rawObject = id as! CoreStoreManagedObject
                rawObject.willChangeValue(forKey: keyPath)
                defer {

                    rawObject.didChangeValue(forKey: keyPath)
                }
                customSetter(
                    PartialObject<O>(rawObject),
                    (newValue as! V.QueryableNativeType?).flatMap(V.cs_fromQueryableNativeType)
                )
            }
        }

        internal var valueForSnapshot: Any? {

            return self.value
        }

        private let customGetter: ((_ partialObject: PartialObject<O>) -> V?)?
        private let customSetter: ((_ partialObject: PartialObject<O>, _ newValue: V?) -> Void)?
    }
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
extension ValueContainer.Optional {

    public static func .= (_ property: ValueContainer<O>.Optional<V>, _ newValue: V?) {

        property.value = newValue
    }
    
    public static func .= <O2>(_ property: ValueContainer<O>.Optional<V>, _ property2: ValueContainer<O2>.Optional<V>) {

        property.value = property2.value
    }
    
    public static func .= <O2>(_ property: ValueContainer<O>.Optional<V>, _ property2: ValueContainer<O2>.Required<V>) {

        property.value = property2.value
    }
    
    public static func .== (_ property: ValueContainer<O>.Optional<V>, _ value: V?) -> Bool {

        return property.value == value
    }
    
    public static func .== (_ value: V?, _ property: ValueContainer<O>.Optional<V>) -> Bool {

        return value == property.value
    }
    
    public static func .== (_ property: ValueContainer<O>.Optional<V>, _ property2: ValueContainer<O>.Optional<V>) -> Bool {

        return property.value == property2.value
    }
    
    public static func .== (_ property: ValueContainer<O>.Optional<V>, _ property2: ValueContainer<O>.Required<V>) -> Bool {

        return property.value == property2.value
    }
}
