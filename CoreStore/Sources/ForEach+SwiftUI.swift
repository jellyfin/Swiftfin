//
//  ForEach+SwiftUI.swift
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


// MARK: - ForEach

extension ForEach where Content: View {
    
    // MARK: Public
    
    /**
     Creates an instance that creates views for each object in a collection of `ObjectSnapshot`s. The objects' `NSManagedObjectID` are used as the identifier
     ```
     let people: [ObjectSnapshot<Person>]
     
     var body: some View {
     
        List {
            
            ForEach(self.people) { person in

                ProfileView(person)
            }
        }
        .animation(.default)
     }
     ```
     
     - parameter objectSnapshots: The collection of `ObjectSnapshot`s that the `ForEach` instance uses to create views dynamically
     - parameter content: The view builder that receives an `ObjectPublisher` instance and creates views dynamically.
     */
    public init<O: DynamicObject>(
        _ objectSnapshots: Data,
        @ViewBuilder content: @escaping (ObjectSnapshot<O>) -> Content
    ) where Data.Element == ObjectSnapshot<O>, ID == O.ObjectID {
        
        self.init(objectSnapshots, id: \.cs_objectID, content: content)
    }

    /**
     Creates an instance that creates views for each object in a `ListSnapshot`.
     ```
     @ListState
     var people: ListSnapshot<Person>
     
     var body: some View {
     
        List {
            
             ForEach(objectIn: self.people) { person in

                 ProfileView(person)
             }
        }
        .animation(.default)
     }
     ```
     
     - parameter listSnapshot: The `ListSnapshot` that the `ForEach` instance uses to create views dynamically
     - parameter content: The view builder that receives an `ObjectPublisher` instance and creates views dynamically.
     */
    public init<O: DynamicObject>(
        objectIn listSnapshot: Data,
        @ViewBuilder content: @escaping (ObjectPublisher<O>) -> Content
    ) where Data == ListSnapshot<O>, ID == O.ObjectID {
        
        self.init(listSnapshot, id: \.cs_objectID, content: content)
    }
    
    /**
     Creates an instance that creates views for each object in a collection of `ObjectPublisher`s.
     ```
     let people: [ObjectPublisher<Person>]
     
     var body: some View {
     
        List {
            
            ForEach(objectIn: self.people) { person in

                ProfileView(person)
            }
        }
        .animation(.default)
     }
     ```
     
     - parameter objectPublishers: The collection of `ObjectPublisher`s that the `ForEach` instance uses to create views dynamically
     - parameter content: The view builder that receives an `ObjectPublisher` instance and creates views dynamically.
     */
    public init<O: DynamicObject>(
        objectIn objectPublishers: Data,
        @ViewBuilder content: @escaping (ObjectPublisher<O>) -> Content
    ) where Data.Element == ObjectPublisher<O>, ID == O.ObjectID {
        
        self.init(objectPublishers, id: \.cs_objectID, content: content)
    }
    
    /**
     Creates an instance that creates views for `ListSnapshot` sections.
     ```
     @ListState
     var people: ListSnapshot<Person>
     
     var body: some View {
     
        List {
            
            ForEach(sectionIn: self.people) { section in
                
                Section(header: Text(section.sectionID)) {

                    ForEach(objectIn: section) { person in

                        ProfileView(person)
                    }
                }
            }
        }
        .animation(.default)
     }
     ```
     
     - parameter listSnapshot: The `ListSnapshot` that the `ForEach` instance uses to create views dynamically
     - parameter content: The view builder that receives a `ListSnapshot.SectionInfo` instance and creates views dynamically.
     */
    public init<O: DynamicObject>(
        sectionIn listSnapshot: ListSnapshot<O>,
        @ViewBuilder content: @escaping (ListSnapshot<O>.SectionInfo) -> Content
    ) where Data == [ListSnapshot<O>.SectionInfo], ID == ListSnapshot<O>.SectionID {
        
        let sections = listSnapshot.sections()
        self.init(sections, id: \.sectionID, content: content)
    }
    
    /**
     Creates an instance that creates views for each object in a `ListSnapshot.SectionInfo`.
     ```
     @ListState
     var people: ListSnapshot<Person>
     
     var body: some View {
     
        List {
            
            ForEach(sectionIn: self.people) { section in
                
                Section(header: Text(section.sectionID)) {

                    ForEach(objectIn: section) { person in

                        ProfileView(person)
                    }
                }
            }
        }
        .animation(.default)
     }
     ```
     
     - parameter sectionInfo: The `ListSnapshot.SectionInfo` that the `ForEach` instance uses to create views dynamically
     - parameter content: The view builder that receives an `ObjectPublisher` instance and creates views dynamically.
     */
    public init<O: DynamicObject>(
        objectIn sectionInfo: Data,
        @ViewBuilder content: @escaping (ObjectPublisher<O>) -> Content
    ) where Data == ListSnapshot<O>.SectionInfo, ID == O.ObjectID {
        
        self.init(sectionInfo, id: \.cs_objectID, content: content)
    }
}

#endif
