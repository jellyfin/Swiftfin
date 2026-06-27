//
//  Relationship.ToOne.swift
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
extension RelationshipContainer {

    public final class ToOne<D: CoreStoreObject>: RelationshipKeyPathStringConvertible, RelationshipProtocol {

        public convenience init(
            _ keyPath: KeyPathString,
            deleteRule: DeleteRule = .nullify,
            versionHashModifier: @autoclosure @escaping () -> String? = nil,
            renamingIdentifier: @autoclosure @escaping () -> String? = nil,
            affectedByKeyPaths: @autoclosure @escaping () -> Set<String> = []) {

            self.init(
                keyPath: keyPath,
                inverseKeyPath: { nil },
                deleteRule: deleteRule,
                versionHashModifier: versionHashModifier(),
                renamingIdentifier: renamingIdentifier(),
                affectedByKeyPaths: affectedByKeyPaths()
            )
        }

        public convenience init(
            _ keyPath: KeyPathString,
            inverse: @escaping (D) -> RelationshipContainer<D>.ToOne<O>,
            deleteRule: DeleteRule = .nullify,
            versionHashModifier: @autoclosure @escaping () -> String? = nil,
            renamingIdentifier: @autoclosure @escaping () -> String? = nil,
            affectedByKeyPaths: @autoclosure @escaping () -> Set<String> = []) {

            self.init(
                keyPath: keyPath,
                inverseKeyPath: { inverse(D.meta).keyPath },
                deleteRule: deleteRule,
                versionHashModifier: versionHashModifier(),
                renamingIdentifier: renamingIdentifier(),
                affectedByKeyPaths: affectedByKeyPaths()
            )
        }
        
        public convenience init(
            _ keyPath: KeyPathString,
            inverse: @escaping (D) -> RelationshipContainer<D>.ToManyOrdered<O>,
            deleteRule: DeleteRule = .nullify,
            versionHashModifier: @autoclosure @escaping () -> String? = nil,
            renamingIdentifier: @autoclosure @escaping () -> String? = nil,
            affectedByKeyPaths: @autoclosure @escaping () -> Set<String> = []) {

            self.init(
                keyPath: keyPath,
                inverseKeyPath: { inverse(D.meta).keyPath },
                deleteRule: deleteRule,
                versionHashModifier: versionHashModifier(),
                renamingIdentifier: renamingIdentifier(),
                affectedByKeyPaths: affectedByKeyPaths()
            )
        }
        
        public convenience init(
            _ keyPath: KeyPathString,
            inverse: @escaping (D) -> RelationshipContainer<D>.ToManyUnordered<O>,
            deleteRule: DeleteRule = .nullify,
            versionHashModifier: @autoclosure @escaping () -> String? = nil,
            renamingIdentifier: @autoclosure @escaping () -> String? = nil,
            affectedByKeyPaths: @autoclosure @escaping () -> Set<String> = []) {

            self.init(
                keyPath: keyPath,
                inverseKeyPath: { inverse(D.meta).keyPath },
                deleteRule: deleteRule,
                versionHashModifier: versionHashModifier(),
                renamingIdentifier: renamingIdentifier(),
                affectedByKeyPaths: affectedByKeyPaths()
            )
        }
        
        public var value: ReturnValueType {

            get {

                return self.nativeValue.flatMap(D.cs_fromRaw)
            }
            set {

                self.nativeValue = newValue?.rawObject
            }
        }

        public var cs_keyPathString: String {

            return self.keyPath
        }

        public typealias ObjectType = O
        public typealias DestinationValueType = D

        public typealias ReturnValueType = DestinationValueType?

        internal let keyPath: KeyPathString

        internal let entityDescriptionValues: () -> RelationshipProtocol.EntityDescriptionValues
        internal var rawObject: CoreStoreManagedObject?

        internal var nativeValue: NSManagedObject? {

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
                    return object.getValue(
                        forKvcKey: self.keyPath,
                        didGetValue: { $0 as! NSManagedObject? }
                    )
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
                    object.setValue(
                        newValue,
                        forKvcKey: self.keyPath
                    )
                }
            }
        }

        internal var valueForSnapshot: Any? {

            return self.value?.objectID()
        }


        // MARK: Private

        private init(keyPath: KeyPathString, inverseKeyPath: @escaping () -> KeyPathString?, deleteRule: RelationshipContainer.DeleteRule, versionHashModifier: @autoclosure @escaping () -> String?, renamingIdentifier: @autoclosure @escaping () -> String?, affectedByKeyPaths: @autoclosure @escaping () -> Set<String>) {

            self.keyPath = keyPath
            self.entityDescriptionValues = {
                (
                    isToMany: false,
                    isOrdered: false,
                    deleteRule: deleteRule.nativeValue,
                    inverse: (type: D.self, keyPath: inverseKeyPath()),
                    versionHashModifier: versionHashModifier(),
                    renamingIdentifier: renamingIdentifier(),
                    affectedByKeyPaths: affectedByKeyPaths(),
                    minCount: 0,
                    maxCount: 1
                )
            }
        }
    }
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
extension RelationshipContainer.ToOne {

    public static func .= (_ relationship: RelationshipContainer<O>.ToOne<D>, _ newObject: D?) {

        relationship.nativeValue = newObject?.cs_toRaw()
    }

    public static func .= <O2>(_ relationship: RelationshipContainer<O>.ToOne<D>, _ relationship2: RelationshipContainer<O2>.ToOne<D>) {

        relationship.nativeValue = relationship2.nativeValue
    }

    public static func .== (_ relationship: RelationshipContainer<O>.ToOne<D>, _ object: D?) -> Bool {

        return relationship.nativeValue == object?.cs_toRaw()
    }
    
    public static func .== (_ object: D?, _ relationship: RelationshipContainer<O>.ToOne<D>) -> Bool {

        return object?.cs_toRaw() == relationship.nativeValue
    }
    
    public static func .== <O2>(_ relationship: RelationshipContainer<O>.ToOne<D>, _ relationship2: RelationshipContainer<O2>.ToOne<D>) -> Bool {

        return relationship.nativeValue == relationship2.nativeValue
    }
}
