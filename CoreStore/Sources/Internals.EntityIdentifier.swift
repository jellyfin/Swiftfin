//
//  Internals.EntityIdentifier.swift
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

import CoreData
import Foundation


// MARK: - Internal

extension Internals {

    // MARK: - EntityIdentifier

    internal struct EntityIdentifier: Hashable {

        // MARK: - Category

        internal enum Category: Int {

            case coreData
            case coreStore
        }


        // MARK: -

        internal let category: Category
        internal let interfacedClassName: String

        internal init(_ type: NSManagedObject.Type) {

            self.category = .coreData
            self.interfacedClassName = NSStringFromClass(type)
        }

        internal init(_ type: CoreStoreObject.Type) {

            self.category = .coreStore
            self.interfacedClassName = NSStringFromClass(type)
        }

        internal init(_ type: DynamicObject.Type) {

            switch type {

            case let type as NSManagedObject.Type:
                self.init(type)

            case let type as CoreStoreObject.Type:
                self.init(type)

            default:
                Internals.abort("\(Internals.typeName(DynamicObject.self)) is not meant to be implemented by external types.")
            }
        } 

        internal init(_ entityDescription: NSEntityDescription) {

            if let anyEntity = entityDescription.coreStoreEntity {

                self.category = .coreStore
                self.interfacedClassName = NSStringFromClass(anyEntity.type)
            }
            else {

                self.category = .coreData
                self.interfacedClassName = entityDescription.managedObjectClassName!
            }
        }
    }
}
