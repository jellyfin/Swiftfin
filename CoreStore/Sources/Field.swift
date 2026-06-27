//
//  Field.swift
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


// MARK: - DynamicObject

extension DynamicObject where Self: CoreStoreObject {

    /**
     The containing type for value propertiess.
     ```
     class Pet: CoreStoreObject {

         @Field.Stored("species")
         var species = ""

         @Field.Stored("nickname")
         var nickname: String?

         @Field.Coded("color", coder: FieldCoders.Plist.self)
         var eyeColor: UIColor?

         @Field.Relationship("owner", inverse: \.$pets)
         var owner: Person?

         @Field.Relationship("children")
         var children: Array<Pet>

         @Field.Relationship("parents", inverse: \.$children)
         var parents: Set<Pet>
     }
     ```
     - Important: `Field` properties are required to be used as `@propertyWrapper`s. Any other declaration not using the `@Field.*(...) var` syntax will result in undefined behavior.
     */
    public typealias Field = FieldContainer<Self>
}


// MARK: - FieldContainer

/**
 The containing type for value properties. Use the `Field` typealias instead for shorter syntax.
 ```
 class Pet: CoreStoreObject {
 
     @Field.Stored("species")
     var species = ""

     @Field.Stored("nickname")
     var nickname: String?

     @Field.Coded("color", coder: FieldCoders.Plist.self)
     var eyeColor: UIColor?

     @Field.Relationship("owner", inverse: \.$pets)
     var owner: Person?

     @Field.Relationship("children")
     var children: Array<Pet>

     @Field.Relationship("parents", inverse: \.$children)
     var parents: Set<Pet>
 }
 ```
 */
public enum FieldContainer<O: CoreStoreObject> {}
