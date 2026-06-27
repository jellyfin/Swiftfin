//
//  ListReader.swift
//  CoreStore
//
//  Copyright © 2021 John Rommel Estropia
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

#if canImport(Combine) && canImport(SwiftUI)

import Combine
import SwiftUI


// MARK: - ListReader

/**
 A container view that reads list changes in a `ListPublisher`
 */
public struct ListReader<Object: DynamicObject, Content: View, Value>: View {
    
    // MARK: Internal
    
    /**
     Creates an instance that creates views for `ListPublisher` changes.
     ```
     let people: ListPublisher<Person>
     
     var body: some View {
     
        List {
            
            ListReader(self.people) { listSnapshot in
     
                ForEach(objectIn: listSnapshot) { person in

                    ProfileView(person)
                }
            }
        }
        .animation(.default)
     }
     ```
     
     - parameter listPublisher: The `ListPublisher` that the `ListReader` instance uses to create views dynamically
     - parameter content: The view builder that receives an `ListSnapshot` instance and creates views dynamically.
     */
    public init(
        _ listPublisher: ListPublisher<Object>,
        @ViewBuilder content: @escaping (ListSnapshot<Object>) -> Content
    ) where Value == ListSnapshot<Object> {
        
        self._list = .init(listPublisher)
        self.content = content
    }
    
    /**
     Creates an instance that creates views for `ListPublisher` changes.
     ```
     let people: ListPublisher<Person>
     
     var body: some View {
     
         ListReader(self.people, keyPath: \.count) { count in

             Text("Number of members: \(count)")
         }
     }
     ```
     
     - parameter listPublisher: The `ListPublisher` that the `ListReader` instance uses to create views dynamically
     - parameter keyPath: A `KeyPath` for a property in the `ListSnapshot` whose value will be sent to the views
     - parameter content: The view builder that receives the value from the property `KeyPath` and creates views dynamically.
     */
    public init(
        _ listPublisher: ListPublisher<Object>,
        keyPath: KeyPath<ListSnapshot<Object>, Value>,
        @ViewBuilder content: @escaping (Value) -> Content
    ) {
        
        self._list = .init(listPublisher)
        self.content = {
            
            content($0[keyPath: keyPath])
        }
    }
    
    
    // MARK: View
    
    public var body: some View {
        
        self.content(self.list)
    }
    
    
    // MARK: Private
    
    @ListState
    private var list: ListSnapshot<Object>
    
    private let content: (ListSnapshot<Object>) -> Content
}

#endif
